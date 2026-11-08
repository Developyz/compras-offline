/// Fixtures de presentación. No son modelos de dominio, registros ni DTOs API.
/// TODO: sustituirlos por modelos/ViewModels al implementar sus capas.
class DemoLine {
  const DemoLine(
    this.name,
    this.quantity,
    this.unitPrice,
    this.total, {
    this.unitLabel = 'por unidad',
  });
  final String name;
  final String quantity;
  final int unitPrice;
  final String unitLabel;
  final int total;
}

class DemoPurchase {
  const DemoPurchase({
    required this.id,
    required this.store,
    required this.date,
    required this.shortDate,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.total,
    this.pending = false,
  });
  final String id;
  final String store;
  final String date;
  final String shortDate;
  final List<DemoLine> lines;
  final int subtotal;
  final int discount;
  final int total;
  final bool pending;
}

const demoBasketLines = [
  DemoLine('Arroz integral · 500 g', '1 paquete', 1800, 1800),
  DemoLine('Leche entera · 1 L', '2 unidades', 1200, 2400),
  DemoLine('Manzana roja', '1 kg', 2200, 2200, unitLabel: 'por kg'),
];

const demoPurchases = [
  DemoPurchase(
    id: 'mercado',
    store: 'Mercado del Barrio',
    date: '08 de noviembre de 2026',
    shortDate: '08 nov 2026',
    lines: demoBasketLines,
    subtotal: 6400,
    discount: 400,
    total: 6000,
    pending: true,
  ),
  DemoPurchase(
    id: 'almacen',
    store: 'Almacén Central',
    date: '05 de noviembre de 2026',
    shortDate: '05 nov 2026',
    lines: [
      DemoLine('Arroz integral · 500 g', '4 paquetes', 1500, 6000),
      DemoLine('Leche entera · 1 L', '4 unidades', 1400, 5600),
      DemoLine('Manzana roja', '3,2 kg', 2100, 6720, unitLabel: 'por kg'),
    ],
    subtotal: 18320,
    discount: 320,
    total: 18000,
  ),
  DemoPurchase(
    id: 'supermercado',
    store: 'Supermercado del Parque',
    date: '02 de noviembre de 2026',
    shortDate: '02 nov 2026',
    lines: [
      DemoLine('Arroz integral · 500 g', '8 paquetes', 1600, 12800),
      DemoLine('Leche entera · 1 L', '4 unidades', 1300, 5200),
      DemoLine('Manzana roja', '3 kg', 2000, 6000, unitLabel: 'por kg'),
    ],
    subtotal: 24000,
    discount: 0,
    total: 24000,
  ),
];

class DemoPricePoint {
  const DemoPricePoint(this.date, this.store, this.price);
  final String date;
  final String store;
  final int price;
}

class DemoProduct {
  const DemoProduct({
    required this.id,
    required this.name,
    required this.presentation,
    required this.priceUnit,
    required this.equivalentUnit,
    required this.equivalentFactor,
    required this.points,
  });
  final String id;
  final String name;
  final String presentation;
  final String priceUnit;
  final String equivalentUnit;
  final int equivalentFactor;
  final List<DemoPricePoint> points;
}

// Las tres observaciones coinciden con las compras de ejemplo, antes de descuentos.
const demoProducts = [
  DemoProduct(
    id: 'arroz',
    name: 'Arroz integral',
    presentation: 'Bolsa de 500 g · Marca de ejemplo',
    priceUnit: 'por paquete de 500 g',
    equivalentUnit: 'kg',
    equivalentFactor: 2,
    points: [
      DemoPricePoint('02 nov', 'Supermercado del Parque', 1600),
      DemoPricePoint('05 nov', 'Almacén Central', 1500),
      DemoPricePoint('08 nov', 'Mercado del Barrio', 1800),
    ],
  ),
  DemoProduct(
    id: 'leche',
    name: 'Leche entera',
    presentation: 'Caja de 1 litro · Marca de ejemplo',
    priceUnit: 'por caja de 1 L',
    equivalentUnit: 'L',
    equivalentFactor: 1,
    points: [
      DemoPricePoint('02 nov', 'Supermercado del Parque', 1300),
      DemoPricePoint('05 nov', 'Almacén Central', 1400),
      DemoPricePoint('08 nov', 'Mercado del Barrio', 1200),
    ],
  ),
  DemoProduct(
    id: 'manzana',
    name: 'Manzana roja',
    presentation: 'A granel · Venta por peso',
    priceUnit: 'por kilogramo',
    equivalentUnit: 'kg',
    equivalentFactor: 1,
    points: [
      DemoPricePoint('02 nov', 'Supermercado del Parque', 2000),
      DemoPricePoint('05 nov', 'Almacén Central', 2100),
      DemoPricePoint('08 nov', 'Mercado del Barrio', 2200),
    ],
  ),
];

class DemoPurchaseArguments {
  const DemoPurchaseArguments(this.purchase, {this.confirmation = false});
  final DemoPurchase purchase;
  final bool confirmation;
}
