import '../domain/models/compra.dart';
import '../domain/models/identidad_y_fecha.dart';
import '../domain/models/producto.dart';
import '../domain/models/valores_compra.dart';

enum DemoReviewScenario { correct, uncertain, difference }

const campoProductoDemo = 'detalles[0].producto';
const campoCantidadDemo = 'detalles[1].cantidad';

// Solo datos de prueba. IDs fijos no se reutilizarán para compras reales.
String _id(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
ImportePyg _pyg(int n) => ImportePyg(BigInt.from(n));

Compra crearRevisionDemo(DemoReviewScenario escenario) {
  final nombres = [
    'Arroz integral · 500 g',
    'Leche entera · 1 L',
    'Manzana roja · kg',
  ];
  final precios = [1800, 1200, 2200];
  final cantidades = [1, 2, 1];
  return Compra(
    id: _id(100),
    fechaCompra: DateTime.utc(2026, 11, 8, 15),
    fechaLocal: FechaLocalCompra('2026-11-08'),
    estado: EstadoCompra.borrador,
    comercioId: _id(200),
    totalTicket: _pyg(escenario == DemoReviewScenario.difference ? 6500 : 6000),
    detalles: [
      for (var i = 0; i < 3; i++)
        DetalleCompra(
          id: _id(i + 1),
          numeroLinea: i + 1,
          descripcionTicket: nombres[i],
          cantidad: CantidadCompra(BigInt.from(cantidades[i] * 1000)),
          unidadCantidadId: _id(i == 2 ? 302 : 301),
          precioUnitario: _pyg(precios[i]),
          importeBruto: _pyg(precios[i] * cantidades[i]),
          contextoHistorico: ContextoHistorico(
            nombreProducto: nombres[i],
            escalaCantidad: EscalaHistorica(
              dimension: i == 2 ? DimensionMedida.masa : DimensionMedida.conteo,
              factorBase: BigInt.from(i == 2 ? 1000 : 1),
            ),
          ),
        ),
    ],
    descuentos: [
      DescuentoCompra(
        id: _id(400),
        descripcion: 'Descuento del ticket',
        importe: _pyg(400),
      ),
    ],
    camposPorRevisar: escenario == DemoReviewScenario.uncertain
        ? [campoProductoDemo, campoCantidadDemo]
        : const [],
  );
}
