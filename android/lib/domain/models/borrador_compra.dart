import 'valores_compra.dart';

/// Entrada de revisión, no DTO de API ni entidad lista para persistir.
/// TODO: incorporar referencias, fecha y contexto histórico al agregado completo.
final class DetalleEnRevision {
  const DetalleEnRevision({
    required this.id,
    required this.descripcionTicket,
    required this.cantidad,
    required this.precioUnitario,
    required this.importeBruto,
  });

  final String id;
  final String descripcionTicket;
  final CantidadCompra cantidad;
  final ImportePyg precioUnitario;

  /// Se conserva el importe leído; no se sustituye por cantidad × precio.
  final ImportePyg importeBruto;
}

final class DescuentoEnRevision {
  const DescuentoEnRevision({
    required this.id,
    required this.descripcion,
    required this.importe,
    this.detalleId,
  });

  final String id;
  final String descripcion;
  final ImportePyg importe;

  /// null indica descuento general, que no se distribuye entre productos.
  final String? detalleId;
}

final class BorradorCompra {
  BorradorCompra({
    required List<DetalleEnRevision> detalles,
    required List<DescuentoEnRevision> descuentos,
    required this.totalTicket,
    BigInt? ajuste,
    this.justificacionAjuste,
    List<String> camposPorRevisar = const [],
  }) : detalles = List.unmodifiable(detalles),
       descuentos = List.unmodifiable(descuentos),
       ajuste = Entero64.verificar(ajuste ?? BigInt.zero),
       camposPorRevisar = List.unmodifiable(camposPorRevisar);

  final List<DetalleEnRevision> detalles;
  final List<DescuentoEnRevision> descuentos;
  final ImportePyg? totalTicket;
  final BigInt ajuste;
  final String? justificacionAjuste;

  /// Incertidumbres comunicadas por la futura captura/edición; no confianza OCR.
  final List<String> camposPorRevisar;
}

final class ResumenCompra {
  const ResumenCompra({
    required this.subtotal,
    required this.descuentoProductos,
    required this.descuentoGeneral,
    required this.ajuste,
    required this.totalCalculado,
  });

  final ImportePyg subtotal;
  final ImportePyg descuentoProductos;
  final ImportePyg descuentoGeneral;
  final BigInt ajuste;
  final ImportePyg totalCalculado;
}
