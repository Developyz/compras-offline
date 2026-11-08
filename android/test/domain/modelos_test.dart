import 'package:compras_offline/domain/models/canasta.dart';
import 'package:compras_offline/domain/models/compra.dart';
import 'package:compras_offline/domain/models/identidad_y_fecha.dart';
import 'package:compras_offline/domain/models/producto.dart';
import 'package:compras_offline/domain/models/valores_compra.dart';
import 'package:flutter_test/flutter_test.dart';

String id(int valor) =>
    '00000000-0000-4000-8000-${valor.toString().padLeft(12, '0')}';
ImportePyg pyg(String valor) => ImportePyg.desdeTexto(valor);
CantidadCompra cantidad(String valor) => CantidadCompra.desdeTexto(valor);
UnidadMedida unidad(
  int n, {
  DimensionMedida dimension = DimensionMedida.conteo,
  String simbolo = 'u',
}) => UnidadMedida(
  id: id(n),
  nombre: simbolo,
  simbolo: simbolo,
  escala: EscalaHistorica(dimension: dimension, factorBase: BigInt.one),
);
Producto producto({
  String nombre = 'Arroz',
  String presentacion = 'Bolsa 500 g',
}) => Producto(
  id: id(1),
  nombre: nombre,
  presentacion: presentacion,
  tipoVenta: TipoVenta.unidad,
  contenido: ContenidoProducto(cantidad: cantidad('500'), unidadId: id(2)),
);
DetalleCompra detalle({
  int n = 1,
  int linea = 1,
  ContextoHistorico? contexto,
}) => DetalleCompra(
  id: id(n),
  numeroLinea: linea,
  descripcionTicket: 'ARR 500',
  cantidad: cantidad('1'),
  unidadCantidadId: id(3),
  precioUnitario: pyg('1800'),
  importeBruto: pyg('1800'),
  contextoHistorico: contexto ?? ContextoHistorico(),
);
Compra compra({
  EstadoCompra estado = EstadoCompra.confirmada,
  String? total = '1800',
  List<DetalleCompra>? detalles,
  List<DescuentoCompra> descuentos = const [],
  String? comercioId,
  SucursalCompra? sucursal,
  DateTime? fecha,
  List<String> pendientes = const [],
}) => Compra(
  id: id(9),
  fechaCompra: fecha ?? DateTime.utc(2026, 11, 9, 2),
  fechaLocal: FechaLocalCompra('2026-11-08'),
  estado: estado,
  detalles: detalles ?? [detalle()],
  descuentos: descuentos,
  totalTicket: total == null ? null : pyg(total),
  comercioId: comercioId,
  sucursal: sucursal,
  camposPorRevisar: pendientes,
);
ItemCanasta item(int n, {String? precio = '1800', String unidades = '1'}) =>
    ItemCanasta(
      id: id(n),
      descripcion: 'Arroz',
      cantidad: cantidad(unidades),
      unidadCantidadId: id(3),
      precioEstimado: precio == null ? null : pyg(precio),
    );
Canasta canasta(List<ItemCanasta> items) => Canasta(
  id: id(9),
  nombre: 'Mi canasta',
  estado: EstadoCanasta.abierta,
  items: items,
);

void main() {
  test('UUID válido se normaliza y referencias inválidas se rechazan', () {
    expect(
      DatosEntidad.id('ABCDEFAB-0000-4000-8000-000000000001'),
      'abcdefab-0000-4000-8000-000000000001',
    );
    expect(
      () => Producto(id: 'local', nombre: 'Arroz', tipoVenta: TipoVenta.unidad),
      throwsArgumentError,
    );
    expect(
      () => Producto(
        id: id(1),
        nombre: 'Arroz',
        tipoVenta: TipoVenta.unidad,
        marcaId: 'inválido',
      ),
      throwsArgumentError,
    );
  });

  test('fecha civil valida calendario y no normaliza fechas inexistentes', () {
    expect(FechaLocalCompra('2024-02-29').valor, '2024-02-29');
    for (final texto in [
      '2026-02-29',
      '2026-04-31',
      '0000-01-01',
      '2026-13-01',
      '2026-1-01',
      '2026-01-01\n',
    ]) {
      expect(() => FechaLocalCompra(texto), throwsFormatException);
    }
  });

  test(
    'fecha de compra es UTC en milisegundos y fecha civil se conserva aparte',
    () {
      final c = compra();
      expect(c.fechaCompra.day, 9);
      expect(c.fechaLocal.valor, '2026-11-08');
      expect(() => compra(fecha: DateTime(2026, 11, 8)), throwsArgumentError);
      expect(
        () => compra(fecha: DateTime.utc(2026, 11, 8, 0, 0, 0, 0, 1)),
        throwsArgumentError,
      );
    },
  );

  test(
    'contenido agrupa cantidad y unidad; factor debe ser positivo e int64',
    () {
      expect(producto().contenido!.cantidad.milesimas, BigInt.from(500000));
      expect(
        () => EscalaHistorica(
          dimension: DimensionMedida.masa,
          factorBase: BigInt.zero,
        ),
        throwsArgumentError,
      );
      expect(
        () => EscalaHistorica(
          dimension: DimensionMedida.masa,
          factorBase: Entero64.maximo + BigInt.one,
        ),
        throwsRangeError,
      );
    },
  );

  test(
    'historia copia catálogo al registrar y sobrevive una edición posterior',
    () {
      final anterior = producto();
      final contexto = ContextoHistorico.desdeProducto(
        producto: anterior,
        unidadCantidad: unidad(3),
        unidadContenido: unidad(
          2,
          dimension: DimensionMedida.masa,
          simbolo: 'g',
        ),
      );
      final c = compra(detalles: [detalle(contexto: contexto)]);
      final editado = producto(
        nombre: 'Arroz nuevo',
        presentacion: 'Nueva presentación',
      );
      expect(editado.nombre, 'Arroz nuevo');
      expect(c.detalles.single.contextoHistorico.nombreProducto, 'Arroz');
      expect(c.detalles.single.contextoHistorico.presentacion, 'Bolsa 500 g');
      expect(c.detalles.single.contextoHistorico.contenido!.simbolo, 'g');
      expect(c.detalles.single.descripcionTicket, 'ARR 500');
    },
  );

  test(
    'historia desconocida queda null y no inventa factores del catálogo',
    () {
      final contexto = ContextoHistorico();
      expect(contexto.nombreProducto, isNull);
      expect(contexto.contenido, isNull);
      expect(contexto.escalaCantidad, isNull);
      expect(
        () => ContextoHistorico.desdeProducto(
          producto: producto(),
          unidadCantidad: unidad(3),
        ),
        throwsArgumentError,
      );
      expect(
        () => ContextoHistorico.desdeProducto(
          producto: producto(),
          unidadCantidad: unidad(3),
          unidadContenido: unidad(99),
        ),
        throwsArgumentError,
      );
    },
  );

  test('estimación distingue subtotal conocido de total completo', () {
    final e = canasta([item(1), item(2, precio: null)]).estimar();
    expect(e.totalConocido.valor, BigInt.from(1800));
    expect(e.itemsSinPrecio, 1);
    expect(e.totalCompleto, isNull);
    expect(
      canasta([item(1, precio: '0')]).estimar().totalCompleto!.valor,
      BigInt.zero,
    );
    expect(canasta([]).estimar().totalCompleto!.valor, BigInt.zero);
  });

  test('estimación calcula cantidad fraccionaria con HALF_UP y detecta desbordamiento', () {
    expect(
      canasta([item(1, precio: '1', unidades: '0.5')])
          .estimar()
          .totalCompleto!
          .valor,
      BigInt.one,
    );
    expect(
      () => canasta([
        item(1, precio: Entero64.maximo.toString()),
        item(2, precio: '1'),
      ]).estimar(),
      throwsRangeError,
    );
  });

  test('canasta rechaza duplicados y más de mil items, conserva una copia inmutable', () {
    expect(() => canasta([item(1), item(1)]), throwsArgumentError);
    expect(
      () => canasta(List.generate(1001, (i) => item(i))),
      throwsArgumentError,
    );
    final items = [item(1)];
    final c = canasta(items);
    items.clear();
    expect(c.items, hasLength(1));
    expect(() => c.items.clear(), throwsUnsupportedError);
  });

  test(
    'compra valida comercio y sucursal sin sustituirlos silenciosamente',
    () {
      final sucursal = SucursalCompra(id: id(7), comercioId: id(8));
      expect(compra(comercioId: id(8), sucursal: sucursal).sucursal!.id, id(7));
      expect(() => compra(sucursal: sucursal), throwsArgumentError);
      expect(
        () => compra(comercioId: id(6), sucursal: sucursal),
        throwsArgumentError,
      );
    },
  );

  test('borrador conserva discrepancias; confirmada exige total y revisión completa', () {
    expect(
      compra(
        estado: EstadoCompra.borrador,
        total: null,
      ).revision.puedeContinuar,
      isFalse,
    );
    expect(
      compra(
        estado: EstadoCompra.borrador,
        total: '1801',
      ).resumen.totalCalculado.valor,
      BigInt.from(1800),
    );
    expect(() => compra(total: null), throwsArgumentError);
    expect(() => compra(total: '1801'), throwsArgumentError);
    expect(() => compra(pendientes: ['cantidad']), throwsArgumentError);
  });

  test('número de línea e ID son únicos; listas vacías no forman compra', () {
    expect(() => compra(detalles: []), throwsArgumentError);
    expect(
      () => compra(detalles: [detalle(), detalle(n: 2)]),
      throwsArgumentError,
    );
    expect(
      () => compra(detalles: [detalle(), detalle(linea: 2)]),
      throwsArgumentError,
    );
    expect(() => detalle(linea: 0), throwsArgumentError);
  });

  test(
    'resúmenes de descuentos derivan de una sola fuente; general no se reparte',
    () {
      final c = compra(
        total: '1500',
        descuentos: [
          DescuentoCompra(
            id: id(4),
            descripcion: 'Producto',
            importe: pyg('100'),
            detalleId: id(1),
          ),
          DescuentoCompra(
            id: id(5),
            descripcion: 'General',
            importe: pyg('200'),
          ),
        ],
      );
      expect(c.descuentoDe(id(1)).valor, BigInt.from(100));
      expect(c.importeFinalDe(id(1)).valor, BigInt.from(1700));
      expect(c.resumen.totalCalculado.valor, BigInt.from(1500));
      expect(() => c.descuentoDe(id(99)), throwsArgumentError);
      expect(
        () => compra(
          descuentos: [
            DescuentoCompra(
              id: id(4),
              descripcion: 'Ajeno',
              importe: pyg('1'),
              detalleId: id(99),
            ),
          ],
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'agregados son inmutables y moneda no depende de valores arbitrarios',
    () {
      final detalles = [detalle()];
      final c = compra(detalles: detalles);
      detalles.clear();
      expect(c.detalles, hasLength(1));
      expect(() => c.detalles.clear(), throwsUnsupportedError);
      expect(() => c.descuentos.clear(), throwsUnsupportedError);
      expect(c.moneda, 'PYG');
      expect(c.decimalesMoneda, 0);
      expect(canasta([]).moneda, 'PYG');
    },
  );
}
