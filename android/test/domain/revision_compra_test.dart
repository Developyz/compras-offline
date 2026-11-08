import 'package:compras_offline/domain/models/borrador_compra.dart';
import 'package:compras_offline/domain/models/valores_compra.dart';
import 'package:compras_offline/domain/services/revision_compra.dart';
import 'package:flutter_test/flutter_test.dart';

ImportePyg pyg(String valor) => ImportePyg.desdeTexto(valor);
DetalleEnRevision detalle({
  String id = 'arroz',
  String bruto = '1800',
  String descripcion = 'Arroz 500 g',
}) => DetalleEnRevision(
  id: id,
  descripcionTicket: descripcion,
  cantidad: CantidadCompra.desdeTexto('1'),
  precioUnitario: pyg('1800'),
  importeBruto: pyg(bruto),
);
DescuentoEnRevision descuento(String id, String importe, {String? detalleId}) =>
    DescuentoEnRevision(
      id: id,
      descripcion: 'Promoción',
      importe: pyg(importe),
      detalleId: detalleId,
    );
BorradorCompra compra({
  List<DetalleEnRevision>? detalles,
  List<DescuentoEnRevision> descuentos = const [],
  String? total = '1800',
  BigInt? ajuste,
  String? justificacion,
  List<String> pendientes = const [],
}) => BorradorCompra(
  detalles: detalles ?? [detalle()],
  descuentos: descuentos,
  totalTicket: total == null ? null : pyg(total),
  ajuste: ajuste,
  justificacionAjuste: justificacion,
  camposPorRevisar: pendientes,
);
Set<MotivoRevision> motivos(ResultadoRevision r) =>
    r.incidencias.map((e) => e.motivo).toSet();

void main() {
  test('valores monetarios exactos por encima de la precisión de double', () {
    expect(pyg('9007199254740993').valor.toString(), '9007199254740993');
    expect(pyg('9223372036854775807').valor, Entero64.maximo);
    expect(() => pyg('9223372036854775808'), throwsRangeError);
    for (final texto in [
      '-1',
      '1.5',
      '1,5',
      '1.000',
      ' 100',
      '1e3',
      '1\n',
      '',
    ]) {
      expect(() => pyg(texto), throwsFormatException);
    }
    expect(() => ImportePyg(BigInt.from(-1)), throwsArgumentError);
  });

  test('cantidades exactas en milésimas sin redondear la entrada', () {
    expect(CantidadCompra.desdeTexto('3.2').milesimas, BigInt.from(3200));
    expect(CantidadCompra.desdeTexto('0.001').milesimas, BigInt.one);
    expect(() => CantidadCompra.desdeTexto('0'), throwsArgumentError);
    expect(() => CantidadCompra.desdeTexto('1.0001'), throwsFormatException);
    expect(() => CantidadCompra.desdeTexto('1,5'), throwsFormatException);
    expect(
      () => CantidadCompra(Entero64.maximo + BigInt.one),
      throwsRangeError,
    );
  });

  test('HALF_UP explícito: menos de medio, medio y más de medio guaraní', () {
    for (final entrada in {
      '0.499': '0',
      '0.500': '1',
      '0.501': '1',
      '1.500': '2',
    }.entries) {
      final importe = RevisionCompra.calcularBruto(
        cantidad: CantidadCompra.desdeTexto(entrada.key),
        precioUnitario: pyg('1'),
      );
      expect(importe.valor.toString(), entrada.value);
    }
    expect(
      RevisionCompra.calcularBruto(
        cantidad: CantidadCompra.desdeTexto('3.2'),
        precioUnitario: pyg('2100'),
      ).valor,
      BigInt.from(6720),
    );
  });

  test('producto intermedio puede superar int64; resultado se comprueba antes de devolver', () {
    expect(
      RevisionCompra.calcularBruto(
        cantidad: CantidadCompra.desdeTexto('1'),
        precioUnitario: ImportePyg(Entero64.maximo),
      ).valor,
      Entero64.maximo,
    );
    expect(
      () => RevisionCompra.calcularBruto(
        cantidad: CantidadCompra.desdeTexto('2'),
        precioUnitario: ImportePyg(Entero64.maximo),
      ),
      throwsRangeError,
    );
  });

  test(
    'compra ejemplo: descuentos de renglón y generales se cuentan una sola vez',
    () {
      final r = RevisionCompra.revisar(
        compra(
          detalles: [
            detalle(),
            detalle(id: 'leche', bruto: '2400'),
            detalle(id: 'manzana', bruto: '2200'),
          ],
          descuentos: [
            descuento('d1', '100', detalleId: 'arroz'),
            descuento('d2', '100', detalleId: 'arroz'),
            descuento('d3', '200'),
          ],
          total: '6000',
        ),
      );
      expect(r.puedeContinuar, isTrue);
      expect(r.resumen!.subtotal.valor, BigInt.from(6400));
      expect(r.resumen!.descuentoProductos.valor, BigInt.from(200));
      expect(r.resumen!.descuentoGeneral.valor, BigInt.from(200));
      expect(r.resumen!.totalCalculado.valor, BigInt.from(6000));
    },
  );

  test(
    'revisar conserva importe leído aunque difiera de cantidad por precio',
    () {
      final borrador = compra(
        detalles: [detalle(bruto: '1799')],
        total: '1799',
      );
      final r = RevisionCompra.revisar(borrador);
      expect(r.puedeContinuar, isTrue);
      expect(r.resumen!.totalCalculado.valor, BigInt.from(1799));
      expect(borrador.detalles.single.importeBruto.valor, BigInt.from(1799));
    },
  );

  test(
    'diferencia y total ausente bloquean pero conservan el resumen de revisión',
    () {
      final diferente = RevisionCompra.revisar(compra(total: '1801'));
      expect(diferente.puedeContinuar, isFalse);
      expect(motivos(diferente), contains(MotivoRevision.totalDiferente));
      expect(diferente.resumen!.totalCalculado.valor, BigInt.from(1800));
      expect(
        motivos(RevisionCompra.revisar(compra(total: null))),
        contains(MotivoRevision.totalTicketAusente),
      );
    },
  );

  test('campos dudosos bloquean aunque los totales coincidan', () {
    final r = RevisionCompra.revisar(
      compra(pendientes: ['detalles[0].cantidad']),
    );
    expect(r.puedeContinuar, isFalse);
    expect(r.incidencias.single.campo, 'detalles[0].cantidad');
    expect(r.incidencias.single.motivo, MotivoRevision.campoPendiente);
  });

  test(
    'descuentos acumulados no pueden exceder el renglón ni el saldo general',
    () {
      final r = RevisionCompra.revisar(
        compra(
          descuentos: [
            descuento('a', '1000', detalleId: 'arroz'),
            descuento('b', '801', detalleId: 'arroz'),
          ],
          ajuste: BigInt.one,
          justificacion: 'No oculta descuento inválido',
        ),
      );
      expect(r.resumen, isNull);
      expect(motivos(r), contains(MotivoRevision.descuentoExcesivo));
      final general = RevisionCompra.revisar(
        compra(
          descuentos: [
            descuento('a', '1000', detalleId: 'arroz'),
            descuento('b', '801'),
          ],
        ),
      );
      expect(motivos(general), contains(MotivoRevision.descuentoExcesivo));
      expect(
        RevisionCompra.revisar(
          compra(descuentos: [descuento('todo', '1800')], total: '0'),
        ).puedeContinuar,
        isTrue,
      );
    },
  );

  test('descuento cero y referencia a otro detalle son inválidos', () {
    final r = RevisionCompra.revisar(
      compra(
        descuentos: [
          descuento('cero', '0'),
          descuento('ajeno', '1', detalleId: 'otro'),
        ],
      ),
    );
    expect(
      motivos(r),
      containsAll([
        MotivoRevision.descuentoSinImporte,
        MotivoRevision.detalleDesconocido,
      ]),
    );
    expect(r.puedeContinuar, isFalse);
  });

  test(
    'ajuste firmado exige motivo; no corrige total de ticket automáticamente',
    () {
      expect(
        motivos(
          RevisionCompra.revisar(
            compra(ajuste: BigInt.one, justificacion: '  '),
          ),
        ),
        contains(MotivoRevision.ajusteSinJustificacion),
      );
      expect(
        RevisionCompra.revisar(
          compra(
            ajuste: BigInt.from(-1),
            justificacion: 'Redondeo revisado',
            total: '1799',
          ),
        ).puedeContinuar,
        isTrue,
      );
      expect(
        motivos(
          RevisionCompra.revisar(
            compra(
              ajuste: BigInt.one,
              justificacion: 'Revisado',
              total: '1800',
            ),
          ),
        ),
        contains(MotivoRevision.totalDiferente),
      );
      expect(
        motivos(
          RevisionCompra.revisar(
            compra(ajuste: BigInt.from(-1801), justificacion: 'Revisado'),
          ),
        ),
        contains(MotivoRevision.totalNegativo),
      );
    },
  );

  test(
    'sumas fuera de int64 no se envuelven ni se confunden con un total válido',
    () {
      final r = RevisionCompra.revisar(
        compra(
          detalles: [
            detalle(bruto: Entero64.maximo.toString()),
            detalle(id: 'otro', bruto: '1'),
          ],
          ajuste: BigInt.from(-1),
          justificacion: 'Revisado',
          total: Entero64.maximo.toString(),
        ),
      );
      expect(r.puedeContinuar, isFalse);
      expect(r.resumen, isNull);
      expect(
        r.incidencias.any(
          (e) =>
              e.campo == 'subtotal_menor' &&
              e.motivo == MotivoRevision.fueraDeRango,
        ),
        isTrue,
      );
    },
  );

  test('listas vacías, límite de mil y duplicados se rechazan sin guardar', () {
    expect(
      motivos(RevisionCompra.revisar(compra(detalles: []))),
      contains(MotivoRevision.cantidadDetalles),
    );
    expect(
      motivos(
        RevisionCompra.revisar(
          compra(detalles: List.generate(1001, (i) => detalle(id: '$i'))),
        ),
      ),
      contains(MotivoRevision.cantidadDetalles),
    );
    expect(
      motivos(
        RevisionCompra.revisar(
          compra(descuentos: List.generate(1001, (i) => descuento('$i', '1'))),
        ),
      ),
      contains(MotivoRevision.cantidadDescuentos),
    );
    expect(
      motivos(RevisionCompra.revisar(compra(detalles: [detalle(), detalle()]))),
      contains(MotivoRevision.identificadorDuplicado),
    );
    expect(
      motivos(
        RevisionCompra.revisar(
          compra(descuentos: [descuento('a', '1'), descuento('a', '1')]),
        ),
      ),
      contains(MotivoRevision.identificadorDuplicado),
    );
  });

  test(
    'errores indican campos para futura UI y rechazan texto obligatorio vacío',
    () {
      final r = RevisionCompra.revisar(
        compra(
          detalles: [detalle(id: ' ', descripcion: ' ')],
        ),
      );
      expect(
        motivos(r),
        containsAll([
          MotivoRevision.identificadorInvalido,
          MotivoRevision.descripcionVacia,
        ]),
      );
      expect(r.incidencias.first.campo, 'detalles[0].id');
    },
  );

  test('borradores y resultados son instantáneas inmutables', () {
    final detalles = [detalle()];
    final pendientes = <String>[];
    final borrador = compra(detalles: detalles, pendientes: pendientes);
    detalles.clear();
    pendientes.add('producto');
    final r = RevisionCompra.revisar(borrador);
    expect(r.puedeContinuar, isTrue);
    expect(() => borrador.detalles.clear(), throwsUnsupportedError);
    expect(() => borrador.descuentos.clear(), throwsUnsupportedError);
    expect(() => borrador.camposPorRevisar.add('otro'), throwsUnsupportedError);
    expect(() => r.incidencias.clear(), throwsUnsupportedError);
  });
}
