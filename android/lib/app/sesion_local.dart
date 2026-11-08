import 'dart:convert';

import 'package:path_provider/path_provider.dart';

import '../services/captura/ticket_temporal.dart';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../data/local/base_local.dart';
import '../data/repositories/compras_sqlite.dart';
import '../domain/models/compra.dart';
import '../domain/models/identidad_y_fecha.dart';
import '../domain/models/producto.dart';
import '../features/tickets/viewmodels/revision_ticket_viewmodel.dart';

/// Una sesión por aplicación. Posee la base y no importa datos ficticios.
class SesionLocal {
  SesionLocal._(this.base, this.dispositivoId, this.unidades, this.nuevoId)
    : compras = ComprasSqlite(base, dispositivoId: dispositivoId);
  final BaseLocal base;
  final String dispositivoId;
  final List<UnidadMedida> unidades;
  final ComprasSqlite compras;
  final String Function() nuevoId;
  Map<String, String> get simbolos => {
    for (final u in unidades) u.id: u.simbolo,
  };

  static Future<SesionLocal> abrirPrivada() async {
    await TicketTemporal.limpiarHuerfanas(await getTemporaryDirectory());
    return abrir(await BaseLocal.abrirPrivada());
  }

  /// Transfiere propiedad de la base a la sesión; también cierra si falla.
  static Future<SesionLocal> abrir(
    BaseLocal base, {
    AssetBundle? assets,
    String Function()? nuevoId,
  }) async {
    final generar = nuevoId ?? const Uuid().v4;
    try {
      final catalogo =
          (jsonDecode(
                await (assets ?? rootBundle).loadString(
                  'assets/db/unidades_iniciales.json',
                ),
              ) as List)
              .map(
                (v) => UnidadMedida(
                  id: v['id'] as String,
                  nombre: v['nombre'] as String,
                  simbolo: v['simbolo'] as String,
                  escala: EscalaHistorica(
                    dimension: DimensionMedida.values.byName(
                      v['dimension'] as String,
                    ),
                    factorBase: BigInt.from(v['factor_base'] as int),
                  ),
                ),
              )
              .toList();
      final dispositivo = await base.transaction(() async {
        for (final unidad in catalogo) {
          final existentes = await base
              .customSelect(
                'SELECT * FROM unidades_medida WHERE id=? OR simbolo=?',
                variables: [
                  Variable.withString(unidad.id),
                  Variable.withString(unidad.simbolo),
                ],
              )
              .get();
          if (existentes.isEmpty) {
            final ahora = DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch,
              isUtc: true,
            ).toIso8601String();
            await base.customStatement(
              'INSERT INTO unidades_medida (id,nombre,simbolo,dimension,factor_base,creado_en,actualizado_en) VALUES (?,?,?,?,?,?,?)',
              [
                unidad.id,
                unidad.nombre,
                unidad.simbolo,
                unidad.escala.dimension.name,
                unidad.escala.factorBase.toInt(),
                ahora,
                ahora,
              ],
            );
          } else if (existentes.length != 1 ||
              existentes.single.data['id'] != unidad.id ||
              existentes.single.data['simbolo'] != unidad.simbolo ||
              existentes.single.data['dimension'] !=
                  unidad.escala.dimension.name ||
              existentes.single.data['factor_base'] !=
                  unidad.escala.factorBase.toInt() ||
              existentes.single.data['eliminado_en'] != null) {
            throw StateError(
              'El catálogo de unidades requiere conciliación explícita',
            );
          }
        }
        final guardado = await base
            .customSelect(
              "SELECT valor FROM metadatos_locales WHERE clave='dispositivo_id'",
            )
            .get();
        if (guardado.isNotEmpty) {
          return DatosEntidad.id(guardado.single.read<String>('valor'));
        }
        final heredados = <String>{};
        for (final fila
            in await base
                .customSelect(
                  'SELECT dispositivo_id FROM cola_sincronizacion UNION SELECT dispositivo_id FROM servidores_confiables WHERE activo=1',
                )
                .get()) {
          heredados.add(DatosEntidad.id(fila.read<String>('dispositivo_id')));
        }
        for (final fila
            in await base
                .customSelect(
                  'SELECT solicitud_json FROM recibos_guardado_local',
                )
                .get()) {
          heredados.add(
            DatosEntidad.id(
              (jsonDecode(fila.read<String>('solicitud_json'))
                      as Map)['dispositivo_id']
                  as String,
            ),
          );
        }
        if (heredados.length > 1) {
          throw StateError('Identidades anteriores requieren conciliación');
        }
        final id = heredados.isEmpty
            ? DatosEntidad.id(generar())
            : heredados.single;
        await base.customStatement(
          "INSERT INTO metadatos_locales VALUES ('dispositivo_id',?)",
          [id],
        );
        return id;
      });
      return SesionLocal._(
        base,
        dispositivo,
        List.unmodifiable(catalogo),
        generar,
      );
    } catch (_) {
      await base.close();
      rethrow;
    }
  }

  RevisionTicketViewModel revisar(Compra borrador) => RevisionTicketViewModel(
    borrador,
    repositorio: compras,
    nuevoId: nuevoId,
    unidades: simbolos,
  );
  Future<void> cerrar() => base.close();
}
