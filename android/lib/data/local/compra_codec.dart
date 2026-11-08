import 'dart:convert';

import '../../domain/models/compra.dart';
import '../../domain/models/identidad_y_fecha.dart';
import '../../domain/models/producto.dart';
import '../../domain/models/valores_compra.dart';

/// Solo Android/VM nativo: comprueba que la conversión int64 sea exacta.
int enteroSql(BigInt valor) {
  Entero64.verificar(valor);
  final resultado = valor.toInt();
  if (BigInt.from(resultado) != valor) {
    throw StateError('Plataforma sin int64 exacto');
  }
  return resultado;
}

/// Orden estable para comparar reintentos locales. No es el hash de API v2.
String jsonLocal(Object? valor) {
  Object? ordenar(Object? v) {
    if (v is Map<String, Object?>) {
      final claves = v.keys.toList()..sort();
      return {for (final clave in claves) clave: ordenar(v[clave])};
    }
    if (v is List) return v.map(ordenar).toList();
    return v;
  }

  return jsonEncode(ordenar(valor));
}

abstract final class CompraCodec {
  static Map<String, Object?> get contextoVacio =>
      contexto(ContextoHistorico());
  static Map<String, Object?> codificar(Compra c) => {
    'comercio_id': c.comercioId,
    'sucursal_id': c.sucursal?.id,
    'canasta_id': c.canastaId,
    'fecha_compra': c.fechaCompra.toIso8601String(),
    'fecha_local': c.fechaLocal.valor,
    'moneda': c.moneda,
    'decimales_moneda': c.decimalesMoneda,
    'estado': c.estado.name,
    'subtotal_menor': enteroSql(c.resumen.subtotal.valor),
    'descuento_productos_menor': enteroSql(c.resumen.descuentoProductos.valor),
    'descuento_general_menor': enteroSql(c.resumen.descuentoGeneral.valor),
    'ajuste_menor': enteroSql(c.resumen.ajuste),
    'total_ticket_menor': c.totalTicket == null
        ? null
        : enteroSql(c.totalTicket!.valor),
    'total_calculado_menor': enteroSql(c.resumen.totalCalculado.valor),
    'observaciones': c.observaciones,
    'detalles': [
      for (final d in c.detalles)
        {
          'id': d.id,
          'numero_linea': d.numeroLinea,
          'producto_id': d.productoId,
          'descripcion_ticket': d.descripcionTicket,
          'cantidad_milesimas': enteroSql(d.cantidad.milesimas),
          'unidad_cantidad_id': d.unidadCantidadId,
          'precio_unitario_menor': enteroSql(d.precioUnitario.valor),
          'importe_bruto_menor': enteroSql(d.importeBruto.valor),
          'descuento_menor': enteroSql(c.descuentoDe(d.id).valor),
          'importe_final_menor': enteroSql(c.importeFinalDe(d.id).valor),
          'contexto_historico': contexto(d.contextoHistorico),
        },
    ],
    'descuentos': [
      for (final d in c.descuentos)
        {
          'id': d.id,
          'detalle_compra_id': d.detalleId,
          'descripcion': d.descripcion,
          'importe_menor': enteroSql(d.importe.valor),
        },
    ],
  };

  static Map<String, Object?> contexto(ContextoHistorico c) => {
    'nombre_producto_historico': c.nombreProducto,
    'presentacion_historica': c.presentacion,
    'contenido_milesimas_historico': c.contenido == null
        ? null
        : enteroSql(c.contenido!.cantidad.milesimas),
    'unidad_contenido_simbolo_historico': c.contenido?.simbolo,
    'dimension_contenido_historica': c.contenido?.escala.dimension.name,
    'factor_base_contenido_historico': c.contenido == null
        ? null
        : enteroSql(c.contenido!.escala.factorBase),
    'dimension_cantidad_historica': c.escalaCantidad?.dimension.name,
    'factor_base_cantidad_historico': c.escalaCantidad == null
        ? null
        : enteroSql(c.escalaCantidad!.factorBase),
  };

  static BigInt _numero(Object? v) {
    if (v is! int) throw FormatException('Se requiere entero nativo exacto');
    return Entero64.verificar(BigInt.from(v));
  }

  static ImportePyg _importe(Object? v) => ImportePyg(_numero(v));
  static DateTime _fecha(Object? valor) {
    if (valor is! String ||
        RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$')
                .stringMatch(valor) !=
            valor) {
      throw FormatException('Fecha UTC canónica requerida');
    }
    final fecha = DateTime.parse(valor);
    if (fecha.toIso8601String() != valor) {
      throw FormatException('Fecha UTC inexistente');
    }
    return fecha;
  }

  static EscalaHistorica? _escala(Object? dimension, Object? factor) {
    if (dimension == null && factor == null) return null;
    if (dimension == null || factor == null) {
      throw FormatException('Escala incompleta');
    }
    return EscalaHistorica(
      dimension: DimensionMedida.values.byName(dimension as String),
      factorBase: _numero(factor),
    );
  }

  static ContextoHistorico _contexto(Map<String, Object?> m) {
    final valores = [
      m['contenido_milesimas_historico'],
      m['unidad_contenido_simbolo_historico'],
      m['dimension_contenido_historica'],
      m['factor_base_contenido_historico'],
    ];
    if (valores.any((v) => v != null) && valores.any((v) => v == null)) {
      throw FormatException('Contenido histórico incompleto');
    }
    return ContextoHistorico(
      nombreProducto: m['nombre_producto_historico'] as String?,
      presentacion: m['presentacion_historica'] as String?,
      contenido: valores.first == null
          ? null
          : ContenidoHistorico(
              cantidad: CantidadCompra(_numero(valores[0])),
              simbolo: valores[1] as String,
              escala: _escala(valores[2], valores[3])!,
            ),
      escalaCantidad: _escala(
        m['dimension_cantidad_historica'],
        m['factor_base_cantidad_historico'],
      ),
    );
  }

  static Compra decodificar(String id, Map<String, Object?> m) {
    final detalles = (m['detalles'] as List).cast<Map<String, Object?>>();
    final descuentos = (m['descuentos'] as List).cast<Map<String, Object?>>();
    if (m['moneda'] != 'PYG' || m['decimales_moneda'] != 0) {
      throw FormatException(
        'La moneda requiere revisión; no se convierte automáticamente',
      );
    }
    final c = Compra(
      id: id,
      comercioId: m['comercio_id'] as String?,
      sucursal: m['sucursal_id'] == null
          ? null
          : SucursalCompra(
              id: m['sucursal_id'] as String,
              comercioId: m['comercio_id'] as String,
            ),
      canastaId: m['canasta_id'] as String?,
      fechaCompra: _fecha(m['fecha_compra']),
      fechaLocal: FechaLocalCompra(m['fecha_local'] as String),
      estado: EstadoCompra.values.byName(m['estado'] as String),
      observaciones: m['observaciones'] as String?,
      totalTicket: m['total_ticket_menor'] == null
          ? null
          : _importe(m['total_ticket_menor']),
      ajuste: _numero(m['ajuste_menor']),
      detalles: [
        for (final d in detalles)
          DetalleCompra(
            id: d['id'] as String,
            numeroLinea: d['numero_linea'] as int,
            productoId: d['producto_id'] as String?,
            descripcionTicket: d['descripcion_ticket'] as String,
            cantidad: CantidadCompra(_numero(d['cantidad_milesimas'])),
            unidadCantidadId: d['unidad_cantidad_id'] as String,
            precioUnitario: _importe(d['precio_unitario_menor']),
            importeBruto: _importe(d['importe_bruto_menor']),
            contextoHistorico: _contexto(
              (d['contexto_historico'] as Map).cast<String, Object?>(),
            ),
          ),
      ],
      descuentos: [
        for (final d in descuentos)
          DescuentoCompra(
            id: d['id'] as String,
            descripcion: d['descripcion'] as String,
            importe: _importe(d['importe_menor']),
            detalleId: d['detalle_compra_id'] as String?,
          ),
      ],
    );
    final recalculado = codificar(c);
    for (final campo in [
      'subtotal_menor',
      'descuento_productos_menor',
      'descuento_general_menor',
      'total_calculado_menor',
    ]) {
      if (_numero(m[campo]) != _numero(recalculado[campo])) {
        throw FormatException('Resumen inconsistente: $campo');
      }
    }
    for (final d in detalles) {
      if (_numero(d['descuento_menor']) !=
              c.descuentoDe(d['id'] as String).valor ||
          _numero(d['importe_final_menor']) !=
              c.importeFinalDe(d['id'] as String).valor) {
        throw FormatException('Resumen de detalle inconsistente');
      }
    }
    return c;
  }
}
