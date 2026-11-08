import '../services/revision_compra.dart';
import 'identidad_y_fecha.dart';
import 'valores_compra.dart';

enum EstadoCanasta { abierta, confirmada, cancelada }

final class ItemCanasta {
  ItemCanasta({
    required String id,
    required String descripcion,
    required this.cantidad,
    required String unidadCantidadId,
    String? productoId,
    this.precioEstimado,
  }) : id = DatosEntidad.id(id),
       descripcion = DatosEntidad.texto(descripcion, 500),
       unidadCantidadId = DatosEntidad.id(unidadCantidadId),
       productoId = DatosEntidad.idOpcional(productoId);
  final String id;
  final String descripcion;
  final String? productoId;
  final CantidadCompra cantidad;
  final String unidadCantidadId;

  /// Precio por unidad de venta; null significa desconocido, no cero.
  final ImportePyg? precioEstimado;
}

final class EstimacionCanasta {
  const EstimacionCanasta({
    required this.totalConocido,
    required this.itemsSinPrecio,
  });
  final ImportePyg totalConocido;
  final int itemsSinPrecio;
  ImportePyg? get totalCompleto => itemsSinPrecio == 0 ? totalConocido : null;
}

final class Canasta {
  Canasta({
    required String id,
    required String nombre,
    required this.estado,
    required List<ItemCanasta> items,
  }) : id = DatosEntidad.id(id),
       nombre = DatosEntidad.texto(nombre, 200),
       items = List.unmodifiable(items) {
    if (items.length > 1000 ||
        items.map((e) => e.id).toSet().length != items.length) {
      throw ArgumentError('Hasta 1000 items con IDs únicos');
    }
  }
  final String id;
  final String nombre;
  final EstadoCanasta estado;
  final List<ItemCanasta> items;
  String get moneda => 'PYG';
  int get decimalesMoneda => 0;

  EstimacionCanasta estimar() {
    var total = BigInt.zero;
    var desconocidos = 0;
    for (final item in items) {
      final precio = item.precioEstimado;
      if (precio == null) {
        desconocidos++;
      } else {
        total += RevisionCompra.calcularBruto(
          cantidad: item.cantidad,
          precioUnitario: precio,
        ).valor;
      }
    }
    return EstimacionCanasta(
      totalConocido: ImportePyg(total),
      itemsSinPrecio: desconocidos,
    );
  }
}
