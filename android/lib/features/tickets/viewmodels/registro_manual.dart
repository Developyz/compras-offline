import '../../../domain/models/compra.dart';
import '../../../domain/models/identidad_y_fecha.dart';
import '../../../domain/models/producto.dart';
import '../../../domain/models/valores_compra.dart';
import '../../../domain/services/revision_compra.dart';

ImportePyg leerGuaranies(String texto) {
  final valor = texto.trim();
  if (!RegExp(r'^\d+$').hasMatch(valor) &&
      !RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(valor)) {
    throw FormatException('Guaraníes enteros requeridos');
  }
  return ImportePyg.desdeTexto(valor.replaceAll('.', ''));
}

final class LineaManual {
  const LineaManual({
    required this.descripcion,
    required this.cantidad,
    required this.precio,
    required this.unidad,
  });
  final String descripcion;
  final String cantidad;
  final String precio;
  final UnidadMedida unidad;
}

/// Acción explícita: calcular importes de una carga manual; no interpreta OCR.
Compra crearBorradorManual({
  required List<LineaManual> lineas,
  required String total,
  required String descuento,
  required DateTime fecha,
  required String Function() nuevoId,
}) {
  final detalles = <DetalleCompra>[];
  for (var i = 0; i < lineas.length; i++) {
    final linea = lineas[i];
    final cantidad = CantidadCompra.desdeTexto(
      linea.cantidad.trim().replaceAll(',', '.'),
    );
    final precio = leerGuaranies(linea.precio);
    detalles.add(
      DetalleCompra(
        id: nuevoId(),
        numeroLinea: i + 1,
        descripcionTicket: linea.descripcion.trim(),
        cantidad: cantidad,
        unidadCantidadId: linea.unidad.id,
        precioUnitario: precio,
        importeBruto: RevisionCompra.calcularBruto(
          cantidad: cantidad,
          precioUnitario: precio,
        ),
        contextoHistorico: ContextoHistorico(
          escalaCantidad: linea.unidad.escala,
        ),
      ),
    );
  }
  final rebaja = leerGuaranies(descuento.trim().isEmpty ? '0' : descuento);
  return Compra(
    id: nuevoId(),
    fechaCompra: fecha.toUtc(),
    fechaLocal: FechaLocalCompra(
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
    ),
    estado: EstadoCompra.borrador,
    detalles: detalles,
    descuentos: rebaja.valor == BigInt.zero
        ? []
        : [
            DescuentoCompra(
              id: nuevoId(),
              descripcion: 'Descuento general',
              importe: rebaja,
            ),
          ],
    totalTicket: leerGuaranies(total),
  );
}
