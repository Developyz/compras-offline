import '../services/revision_compra.dart';
import 'borrador_compra.dart';
import 'identidad_y_fecha.dart';
import 'producto.dart';
import 'valores_compra.dart';

enum EstadoCompra { borrador, confirmada, anulada }

/// Incluye comercio para comprobar la pertenencia sin consultar una conexión.
final class SucursalCompra {
  SucursalCompra({required String id, required String comercioId})
    : id = DatosEntidad.id(id),
      comercioId = DatosEntidad.id(comercioId);
  final String id;
  final String comercioId;
}

final class DetalleCompra {
  DetalleCompra({
    required String id,
    required this.numeroLinea,
    String? productoId,
    required String descripcionTicket,
    required this.cantidad,
    required String unidadCantidadId,
    required this.precioUnitario,
    required this.importeBruto,
    required this.contextoHistorico,
  }) : id = DatosEntidad.id(id),
       productoId = DatosEntidad.idOpcional(productoId),
       descripcionTicket = DatosEntidad.texto(descripcionTicket, 500),
       unidadCantidadId = DatosEntidad.id(unidadCantidadId) {
    if (numeroLinea < 1 || numeroLinea > 1000) {
      throw ArgumentError('Línea fuera de rango');
    }
  }
  final String id;
  final int numeroLinea;
  final String? productoId;
  final String descripcionTicket;
  final CantidadCompra cantidad;
  final String unidadCantidadId;
  final ImportePyg precioUnitario;
  final ImportePyg importeBruto;
  final ContextoHistorico contextoHistorico;

  DetalleEnRevision paraRevision() => DetalleEnRevision(
    id: id,
    descripcionTicket: descripcionTicket,
    cantidad: cantidad,
    precioUnitario: precioUnitario,
    importeBruto: importeBruto,
  );
}

final class DescuentoCompra {
  DescuentoCompra({
    required String id,
    required String descripcion,
    required this.importe,
    String? detalleId,
  }) : id = DatosEntidad.id(id),
       descripcion = DatosEntidad.texto(descripcion, 500),
       detalleId = DatosEntidad.idOpcional(detalleId);
  final String id;
  final String descripcion;
  final ImportePyg importe;
  final String? detalleId;

  DescuentoEnRevision paraRevision() => DescuentoEnRevision(
    id: id,
    descripcion: descripcion,
    importe: importe,
    detalleId: detalleId,
  );
}

/// Agregado local validado. No representa un guardado ni una sincronización.
final class Compra {
  factory Compra({
    required String id,
    required DateTime fechaCompra,
    required FechaLocalCompra fechaLocal,
    required EstadoCompra estado,
    required List<DetalleCompra> detalles,
    required List<DescuentoCompra> descuentos,
    required ImportePyg? totalTicket,
    String? comercioId,
    SucursalCompra? sucursal,
    String? canastaId,
    BigInt? ajuste,
    String? observaciones,
    List<String> camposPorRevisar = const [],
  }) {
    final comercio = DatosEntidad.idOpcional(comercioId);
    if (sucursal != null && sucursal.comercioId != comercio) {
      throw ArgumentError('La sucursal debe pertenecer al comercio');
    }
    if (!fechaCompra.isUtc ||
        fechaCompra.year < 1 ||
        fechaCompra.year > 9999 ||
        fechaCompra.microsecond != 0) {
      throw ArgumentError('Fecha UTC con precisión de milisegundos requerida');
    }
    if (detalles.map((e) => e.numeroLinea).toSet().length != detalles.length) {
      throw ArgumentError('Números de línea duplicados');
    }
    final notas = DatosEntidad.textoOpcional(observaciones, 2000);
    final borrador = BorradorCompra(
      detalles: detalles.map((e) => e.paraRevision()).toList(),
      descuentos: descuentos.map((e) => e.paraRevision()).toList(),
      totalTicket: totalTicket,
      ajuste: ajuste,
      justificacionAjuste: notas,
      camposPorRevisar: camposPorRevisar,
    );
    final revision = RevisionCompra.revisar(borrador);
    if (revision.resumen == null ||
        (estado == EstadoCompra.confirmada && !revision.puedeContinuar)) {
      throw ArgumentError('La compra no cumple las reglas de revisión');
    }
    return Compra._(
      id: DatosEntidad.id(id),
      fechaCompra: fechaCompra,
      fechaLocal: fechaLocal,
      estado: estado,
      detalles: List.unmodifiable(detalles),
      descuentos: List.unmodifiable(descuentos),
      comercioId: comercio,
      sucursal: sucursal,
      canastaId: DatosEntidad.idOpcional(canastaId),
      observaciones: notas,
      revision: revision,
      totalTicket: totalTicket,
    );
  }

  const Compra._({
    required this.id,
    required this.fechaCompra,
    required this.fechaLocal,
    required this.estado,
    required this.detalles,
    required this.descuentos,
    required this.comercioId,
    required this.sucursal,
    required this.canastaId,
    required this.observaciones,
    required this.revision,
    required this.totalTicket,
  });
  final String id;
  final DateTime fechaCompra;
  final FechaLocalCompra fechaLocal;
  final EstadoCompra estado;
  final List<DetalleCompra> detalles;
  final List<DescuentoCompra> descuentos;
  final String? comercioId;
  final SucursalCompra? sucursal;
  final String? canastaId;
  final String? observaciones;
  final ResultadoRevision revision;
  final ImportePyg? totalTicket;
  ResumenCompra get resumen => revision.resumen!;
  String get moneda => 'PYG';
  int get decimalesMoneda => 0;

  ImportePyg descuentoDe(String detalleId) {
    final id = DatosEntidad.id(detalleId);
    if (!detalles.any((e) => e.id == id)) {
      throw ArgumentError('Detalle desconocido');
    }
    return ImportePyg(
      descuentos
          .where((e) => e.detalleId == id)
          .fold(BigInt.zero, (total, e) => total + e.importe.valor),
    );
  }

  ImportePyg importeFinalDe(String detalleId) {
    final descuento = descuentoDe(detalleId);
    final detalle = detalles.firstWhere(
      (e) => e.id == DatosEntidad.id(detalleId),
    );
    return ImportePyg(detalle.importeBruto.valor - descuento.valor);
  }
}
