import 'package:drift/drift.dart';

import '../../domain/models/compra.dart';
import '../../domain/models/resumen_inicio.dart';
import '../../domain/models/identidad_y_fecha.dart';
import '../../domain/repositories/repositorios.dart';
import '../local/base_local.dart';
import '../local/compra_codec.dart';

final class ConflictoGuardadoLocal implements Exception {
  const ConflictoGuardadoLocal(this.motivo);
  final String motivo;
  @override
  String toString() => 'ConflictoGuardadoLocal: $motivo';
}

/// Primera escritura append-only. Ediciones/versiones remotas aún no soportadas.
class ComprasSqlite implements RepositorioCompras {
  ComprasSqlite(
    this.base, {
    required String dispositivoId,
    DateTime Function()? reloj,
  }) : dispositivoId = DatosEntidad.id(dispositivoId),
       _reloj = reloj ?? DateTime.now;
  final BaseLocal base;
  final String dispositivoId;
  final DateTime Function() _reloj;

  Future<List<Map<String, Object?>>> _filas(
    String sql, [
    List<String> args = const [],
  ]) async =>
      (await base
              .customSelect(
                sql,
                variables: args.map(Variable.withString).toList(),
              )
              .get())
          .map((r) => r.data)
          .toList();

  Future<void> _insertar(
    String tabla,
    Map<String, Object?> datos,
  ) => base.customStatement(
    'INSERT INTO $tabla (${datos.keys.join(',')}) VALUES (${List.filled(datos.length, '?').join(',')})',
    datos.values.toList(),
  );

  @override
  Future<ResumenInicio> resumenInicio(FechaLocalCompra hoy) =>
      base.transaction(() async {
        final inicio = '${hoy.valor.substring(0, 7)}-01';
        final fecha = DateTime.parse(hoy.valor);
        final fin = DateTime.utc(
          fecha.year,
          fecha.month + 1,
          1,
        ).toIso8601String().substring(0, 10);
        final filas = await _filas(
          "SELECT total_calculado_menor,fecha_local,moneda,decimales_moneda FROM compras WHERE eliminado_en IS NULL AND estado='confirmada'",
        );
        var mes = BigInt.zero, total = BigInt.zero;
        var cantidadMes = 0;
        for (final fila in filas) {
          if (fila['moneda'] != 'PYG' || fila['decimales_moneda'] != 0) {
            throw FormatException('Moneda local incompatible');
          }
          final importe = fila['total_calculado_menor'];
          if (importe is! int || importe < 0) {
            throw FormatException('Importe inválido');
          }
          final dia = FechaLocalCompra(fila['fecha_local'] as String).valor;
          total += BigInt.from(importe);
          if (dia.compareTo(inicio) >= 0 && dia.compareTo(fin) < 0) {
            mes += BigInt.from(importe);
            cantidadMes++;
          }
        }
        final ids = await _filas(
          "SELECT id FROM compras WHERE eliminado_en IS NULL AND estado='confirmada' ORDER BY fecha_local DESC,fecha_compra DESC,id DESC LIMIT 3",
        );
        final ultimas = <Compra>[];
        for (final fila in ids) {
          ultimas.add((await obtenerPorId(fila['id'] as String))!);
        }
        return ResumenInicio(
          totalMes: mes,
          totalLocal: total,
          comprasMes: cantidadMes,
          comprasLocales: filas.length,
          ultimas: ultimas,
        );
      });

  @override
  Future<List<Compra>> listarRecientes({int limite = 100}) async {
    if (limite < 1 || limite > 100) throw RangeError.range(limite, 1, 100);
    final ids = await _filas(
      'SELECT id FROM compras WHERE eliminado_en IS NULL ORDER BY fecha_compra DESC,id DESC LIMIT $limite',
    );
    final compras = <Compra>[];
    for (final fila in ids) {
      final compra = await obtenerPorId(fila['id'] as String);
      if (compra != null) compras.add(compra);
    }
    return List.unmodifiable(compras);
  }

  @override
  Future<Compra?> obtenerPorId(String id) async {
    final normalizado = DatosEntidad.id(id);
    return base.transaction(() async {
      final cabecera = await _filas(
        'SELECT * FROM compras WHERE id=? AND eliminado_en IS NULL',
        [normalizado],
      );
      if (cabecera.isEmpty) return null;
      final detalles = await _filas(
        'SELECT * FROM detalles_compra WHERE compra_id=? AND eliminado_en IS NULL ORDER BY numero_linea',
        [normalizado],
      );
      final descuentos = await _filas(
        'SELECT * FROM descuentos_compra WHERE compra_id=? AND eliminado_en IS NULL ORDER BY id',
        [normalizado],
      );
      return CompraCodec.decodificar(normalizado, {
        ...cabecera.single,
        'detalles': [
          for (final d in detalles)
            {
              ...d,
              'contexto_historico': {
                for (final campo in CompraCodec.contextoVacio.keys)
                  campo: d[campo],
              },
            },
        ],
        'descuentos': descuentos,
      });
    });
  }

  Future<void> _referencia(String tabla, String? id) async {
    if (id == null) return;
    if ((await _filas(
      'SELECT id FROM $tabla WHERE id=? AND eliminado_en IS NULL',
      [id],
    )).isEmpty) {
      throw ConflictoGuardadoLocal('Referencia ausente o eliminada en $tabla');
    }
  }

  @override
  Future<ReciboGuardadoLocal> guardarYEncolar(
    EscrituraLocal<Compra> escritura,
  ) async {
    final compra = escritura.entidad;
    if (escritura.versionBase != BigInt.zero ||
        compra.estado != EstadoCompra.confirmada) {
      throw UnsupportedError(
        'Solo creación de compras confirmadas con versión base cero',
      );
    }
    final datos = CompraCodec.codificar(compra);
    final datosJson = jsonLocal(datos);
    final solicitud = jsonLocal({
      'operacion_id': escritura.operacionId,
      'dispositivo_id': dispositivoId,
      'entidad': 'compras',
      'entidad_id': compra.id,
      'version_base': enteroSql(escritura.versionBase),
      'accion': 'guardar',
      'datos': datos,
    });
    return base.transaction(() async {
      final recibos = await _filas(
        'SELECT * FROM recibos_guardado_local WHERE operacion_id=?',
        [escritura.operacionId],
      );
      if (recibos.isNotEmpty) {
        if (recibos.single['solicitud_json'] != solicitud) {
          throw const ConflictoGuardadoLocal(
            'ID de operación reutilizado con otra solicitud',
          );
        }
        return ReciboGuardadoLocal(
          entidadId: compra.id,
          operacionId: escritura.operacionId,
        );
      }
      if ((await _filas('SELECT id FROM compras WHERE id=?', [
            compra.id,
          ])).isNotEmpty ||
          (await _filas(
            'SELECT operacion_id FROM cola_sincronizacion WHERE operacion_id=?',
            [escritura.operacionId],
          )).isNotEmpty) {
        throw const ConflictoGuardadoLocal(
          'La compra u operación ya existe; no se sobrescribe',
        );
      }
      await _referencia('comercios', compra.comercioId);
      await _referencia('sucursales', compra.sucursal?.id);
      await _referencia('canastas', compra.canastaId);
      if (compra.sucursal != null) {
        final sucursal = (await _filas(
          'SELECT comercio_id FROM sucursales WHERE id=?',
          [compra.sucursal!.id],
        )).single;
        if (sucursal['comercio_id'] != compra.comercioId) {
          throw const ConflictoGuardadoLocal('Sucursal de otro comercio');
        }
      }
      for (final detalle in compra.detalles) {
        await _referencia('productos', detalle.productoId);
        await _referencia('unidades_medida', detalle.unidadCantidadId);
      }
      final ahora = DateTime.fromMillisecondsSinceEpoch(
        _reloj().toUtc().millisecondsSinceEpoch,
        isUtc: true,
      ).toIso8601String();
      final auditoria = <String, Object?>{
        'version': 1,
        'creado_en': ahora,
        'actualizado_en': ahora,
      };
      await _insertar('compras', {
        'id': compra.id,
        for (final campo in datos.entries)
          if (campo.key != 'detalles' && campo.key != 'descuentos')
            campo.key: campo.value,
        ...auditoria,
      });
      final completos = datos;
      for (final d
          in (completos['detalles'] as List).cast<Map<String, Object?>>()) {
        final contexto = (d['contexto_historico'] as Map)
            .cast<String, Object?>();
        await _insertar('detalles_compra', {
          for (final campo in d.entries)
            if (campo.key != 'contexto_historico') campo.key: campo.value,
          ...contexto,
          'compra_id': compra.id,
          ...auditoria,
        });
      }
      for (final d
          in (completos['descuentos'] as List).cast<Map<String, Object?>>()) {
        await _insertar('descuentos_compra', {
          ...d,
          'compra_id': compra.id,
          ...auditoria,
        });
      }
      await _insertar('cola_sincronizacion', {
        'operacion_id': escritura.operacionId,
        'dispositivo_id': dispositivoId,
        'entidad': 'compras',
        'entidad_id': compra.id,
        'version_base': enteroSql(escritura.versionBase),
        'accion': 'guardar',
        'datos_json': datosJson,
        'estado': 'pendiente',
        'creado_en': ahora,
        'servidor_id': null,
        'hash_solicitud': null,
      });
      await _insertar('recibos_guardado_local', {
        'operacion_id': escritura.operacionId,
        'entidad': 'compras',
        'entidad_id': compra.id,
        'solicitud_json': solicitud,
        'creado_en': ahora,
      });
      return ReciboGuardadoLocal(
        entidadId: compra.id,
        operacionId: escritura.operacionId,
      );
    });
  }
}
