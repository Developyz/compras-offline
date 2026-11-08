import '../../../domain/models/valores_compra.dart';
import '../../../domain/services/revision_compra.dart';
import 'registro_manual.dart';

final class ProductoLeido {
  const ProductoLeido(
    this.descripcion,
    this.cantidad,
    this.precio,
    this.unidad,
  );
  final String descripcion;
  final String cantidad;
  final String precio;
  final String unidad;
}

/// Propuestas de lectura: siempre requieren revisión, nunca crean catálogo.
final class LecturaTicket {
  const LecturaTicket(this.texto);
  final String texto;
  String? get totalSugerido {
    final encontrados = <String>[];
    for (final linea in texto.split('\n')) {
      final m = RegExp(
        r'^\s*TOTAL(?:\s+A\s+PAGAR)?\s*[:\s]+(?:GS\.?\s*|₲\s*)?([0-9]+|[0-9]{1,3}(?:\.[0-9]{3})+)\s*$',
        caseSensitive: false,
      ).firstMatch(linea);
      if (m != null) encontrados.add(m[1]!);
    }
    return encontrados.length == 1 ? encontrados.single : null;
  }

  List<ProductoLeido> get productosSugeridos {
    final propuestas = <ProductoLeido>[];
    for (final linea in texto.split('\n')) {
      if (propuestas.length == 1000) break;
      if (RegExp(
        r'^\s*(TOTAL|SUBTOTAL|IVA|EFECTIVO|VUELTO|DESCUENTO|RUC)\b',
        caseSensitive: false,
      ).hasMatch(linea)) {
        continue;
      }
      final m = RegExp(
        r'^\s*(.+?)\s+(\d+(?:,\d{1,3})?)\s*(kg|l|u)?\s*[x×]\s*([\d.]+)\s*(?:=|\s)\s*([\d.]+)\s*$',
        caseSensitive: false,
      ).firstMatch(linea);
      if (m == null) continue;
      try {
        final cantidad = CantidadCompra.desdeTexto(m[2]!.replaceAll(',', '.'));
        final precio = leerGuaranies(m[4]!);
        final bruto = leerGuaranies(m[5]!);
        if (RevisionCompra.calcularBruto(
              cantidad: cantidad,
              precioUnitario: precio,
            ).valor !=
            bruto.valor) {
          continue;
        }
        propuestas.add(
          ProductoLeido(
            m[1]!.trim(),
            m[2]!,
            precio.valor.toString(),
            m[3]?.toLowerCase() ?? 'u',
          ),
        );
      } on FormatException {
        continue;
      } on ArgumentError {
        continue;
      }
    }
    return List.unmodifiable(propuestas);
  }
}
