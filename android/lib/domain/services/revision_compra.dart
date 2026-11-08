import '../models/borrador_compra.dart';
import '../models/valores_compra.dart';

/// Códigos estables para que un futuro ViewModel decida el texto de la UI.
enum MotivoRevision {
  cantidadDetalles,
  cantidadDescuentos,
  identificadorInvalido,
  identificadorDuplicado,
  descripcionVacia,
  descuentoSinImporte,
  detalleDesconocido,
  descuentoExcesivo,
  ajusteSinJustificacion,
  totalNegativo,
  fueraDeRango,
  totalTicketAusente,
  totalDiferente,
  campoPendiente,
}

final class IncidenciaRevision {
  const IncidenciaRevision(this.campo, this.motivo);
  final String campo;
  final MotivoRevision motivo;
}

final class ResultadoRevision {
  ResultadoRevision({
    required this.resumen,
    required List<IncidenciaRevision> incidencias,
  }) : incidencias = List.unmodifiable(incidencias);

  /// No disponible cuando la estructura o los importes son inválidos.
  final ResumenCompra? resumen;
  final List<IncidenciaRevision> incidencias;

  /// Solo habilita el siguiente paso de revisión, nunca guarda una compra.
  bool get puedeContinuar => resumen != null && incidencias.isEmpty;
}

abstract final class RevisionCompra {
  /// Cálculo solicitado expresamente: decimal exacto y HALF_UP al guaraní.
  /// No se utiliza al revisar un importe bruto que ya fue leído.
  static ImportePyg calcularBruto({
    required CantidadCompra cantidad,
    required ImportePyg precioUnitario,
  }) {
    final numerador = cantidad.milesimas * precioUnitario.valor;
    return ImportePyg((numerador + BigInt.from(500)) ~/ BigInt.from(1000));
  }

  static ResultadoRevision revisar(BorradorCompra compra) {
    final errores = <IncidenciaRevision>[];
    void agregar(String campo, MotivoRevision motivo) {
      errores.add(IncidenciaRevision(campo, motivo));
    }

    if (compra.detalles.isEmpty || compra.detalles.length > 1000) {
      agregar('detalles', MotivoRevision.cantidadDetalles);
    }
    if (compra.descuentos.length > 1000) {
      agregar('descuentos', MotivoRevision.cantidadDescuentos);
    }
    // No procesar listas fuera de los límites del contrato.
    if (errores.isNotEmpty) {
      return ResultadoRevision(resumen: null, incidencias: errores);
    }

    final porId = <String, DetalleEnRevision>{};
    var subtotal = BigInt.zero;
    for (var i = 0; i < compra.detalles.length; i++) {
      final detalle = compra.detalles[i];
      if (detalle.id.trim().isEmpty) {
        agregar('detalles[$i].id', MotivoRevision.identificadorInvalido);
      } else if (porId.containsKey(detalle.id)) {
        agregar('detalles[$i].id', MotivoRevision.identificadorDuplicado);
      } else {
        porId[detalle.id] = detalle;
      }
      if (detalle.descripcionTicket.trim().isEmpty) {
        agregar(
          'detalles[$i].descripcion_ticket',
          MotivoRevision.descripcionVacia,
        );
      }
      subtotal += detalle.importeBruto.valor;
    }

    final idsDescuentos = <String>{};
    final porDetalle = <String, BigInt>{};
    var descuentoProductos = BigInt.zero;
    var descuentoGeneral = BigInt.zero;
    for (var i = 0; i < compra.descuentos.length; i++) {
      final descuento = compra.descuentos[i];
      final campo = 'descuentos[$i]';
      if (descuento.id.trim().isEmpty) {
        agregar('$campo.id', MotivoRevision.identificadorInvalido);
      } else if (!idsDescuentos.add(descuento.id)) {
        agregar('$campo.id', MotivoRevision.identificadorDuplicado);
      }
      if (descuento.descripcion.trim().isEmpty) {
        agregar('$campo.descripcion', MotivoRevision.descripcionVacia);
      }
      if (descuento.importe.valor == BigInt.zero) {
        agregar('$campo.importe_menor', MotivoRevision.descuentoSinImporte);
      }
      final detalleId = descuento.detalleId;
      if (detalleId == null) {
        descuentoGeneral += descuento.importe.valor;
      } else if (!porId.containsKey(detalleId)) {
        agregar('$campo.detalle_compra_id', MotivoRevision.detalleDesconocido);
      } else {
        descuentoProductos += descuento.importe.valor;
        porDetalle[detalleId] =
            (porDetalle[detalleId] ?? BigInt.zero) + descuento.importe.valor;
      }
    }
    for (var i = 0; i < compra.detalles.length; i++) {
      final detalle = compra.detalles[i];
      if ((porDetalle[detalle.id] ?? BigInt.zero) >
          detalle.importeBruto.valor) {
        agregar(
          'detalles[$i].descuento_menor',
          MotivoRevision.descuentoExcesivo,
        );
      }
    }
    if (descuentoGeneral > subtotal - descuentoProductos) {
      agregar('descuento_general_menor', MotivoRevision.descuentoExcesivo);
    }
    if (compra.ajuste != BigInt.zero &&
        (compra.justificacionAjuste?.trim().isEmpty ?? true)) {
      agregar('observaciones', MotivoRevision.ajusteSinJustificacion);
    }
    final total =
        subtotal - descuentoProductos - descuentoGeneral + compra.ajuste;
    if (total.isNegative) {
      agregar('total_calculado_menor', MotivoRevision.totalNegativo);
    }
    final importes = {
      'subtotal_menor': subtotal,
      'descuento_productos_menor': descuentoProductos,
      'descuento_general_menor': descuentoGeneral,
      'total_calculado_menor': total,
    };
    for (final entrada in importes.entries) {
      if (entrada.value < Entero64.minimo || entrada.value > Entero64.maximo) {
        agregar(entrada.key, MotivoRevision.fueraDeRango);
      }
    }
    // No ofrecer un resumen contable de una estructura inválida.
    if (errores.isNotEmpty) {
      return ResultadoRevision(resumen: null, incidencias: errores);
    }
    final resumen = ResumenCompra(
      subtotal: ImportePyg(subtotal),
      descuentoProductos: ImportePyg(descuentoProductos),
      descuentoGeneral: ImportePyg(descuentoGeneral),
      ajuste: compra.ajuste,
      totalCalculado: ImportePyg(total),
    );
    if (compra.totalTicket == null) {
      agregar('total_ticket_menor', MotivoRevision.totalTicketAusente);
    } else if (compra.totalTicket!.valor != total) {
      agregar('total_ticket_menor', MotivoRevision.totalDiferente);
    }
    for (final campo in compra.camposPorRevisar) {
      agregar(campo, MotivoRevision.campoPendiente);
    }
    return ResultadoRevision(resumen: resumen, incidencias: errores);
  }
}
