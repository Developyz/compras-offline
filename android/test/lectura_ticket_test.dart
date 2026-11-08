import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:compras_offline/services/captura/ticket_temporal.dart';
import 'package:compras_offline/features/tickets/viewmodels/lectura_ticket.dart';
import 'package:compras_offline/features/tickets/views/registro_manual_view.dart';
import 'package:compras_offline/app/sesion_local.dart';
import 'package:compras_offline/data/local/base_local.dart';

void main() {
  test('solo sugiere un total explícito y entero sin confundir subtotales', () {
    expect(
      const LecturaTicket('SUBTOTAL 900\nTOTAL: ₲ 1.000').totalSugerido,
      '1.000',
    );
    expect(const LecturaTicket('TOTAL 1000\nTOTAL 1000').totalSugerido, isNull);
    expect(const LecturaTicket('SUBTOTAL 1000\nIVA 100').totalSugerido, isNull);
    expect(const LecturaTicket('TOTAL 10,50').totalSugerido, isNull);
  });
  test('propone productos solo con cantidad por precio y bruto coherentes', () {
    final lectura = LecturaTicket(
      'ARROZ 2 x 1.000 = 2.000\nMANZANA 0,5 kg x 4.000 = 2.000\nIVA 2 x 500 = 1000\nLECHE 2 x 1000 = 3000\nOTRO TEXTO',
    );
    expect(lectura.productosSugeridos, hasLength(2));
    expect(lectura.productosSugeridos.last.unidad, 'kg');
    expect(lectura.productosSugeridos.first.precio, '1000');
  });
  for (final falla in [false, true]) {
    test('la foto se elimina también si el OCR falla: $falla', () async {
      final dir = await Directory.systemTemp.createTemp('captura-test-');
      final foto = File('${dir.path}/origen.jpg');
      await foto.writeAsBytes([1, 2, 3]);
      try {
        final lectura = TicketTemporal.reconocerYBorrar(
          foto,
          temporal: dir,
          reconocer: (ruta) async {
            expect(await File(ruta).exists(), isTrue);
            if (falla) throw StateError('OCR');
            return 'TOTAL 1000';
          },
        );
        if (falla) {
          await expectLater(lectura, throwsStateError);
        } else {
          expect(await lectura, 'TOTAL 1000');
        }
        expect(await foto.exists(), isFalse);
        expect(await dir.list().toList(), isEmpty);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  }
  test('limpieza de huérfanos no toca imágenes ajenas', () async {
    final dir = await Directory.systemTemp.createTemp('limpieza-test-');
    await dir.createTemp(TicketTemporal.prefijo);
    await File('${dir.path}/mi-foto.jpg').writeAsBytes([1]);
    await TicketTemporal.limpiarHuerfanas(dir);
    expect(await File('${dir.path}/mi-foto.jpg').exists(), isTrue);
    expect(await dir.list().length, 1);
    await dir.delete(recursive: true);
  });
  testWidgets('lectura exige revisión y editar invalida la comprobación', (
    t,
  ) async {
    final sesion = await SesionLocal.abrir(BaseLocal.enMemoria());
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegistroManualView(
            sesion,
            lectura: const LecturaTicket('TOTAL 1000'),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final casilla = find.byType(CheckboxListTile);
    await t.ensureVisible(casilla);
    await t.tap(casilla);
    await t.pumpAndSettle();
    expect(t.widget<CheckboxListTile>(casilla).value, isTrue);
    await t.ensureVisible(find.byKey(const ValueKey('descripcion-0')));
    await t.enterText(find.byKey(const ValueKey('descripcion-0')), 'Arroz');
    await t.pumpAndSettle();
    expect(t.widget<CheckboxListTile>(casilla).value, isFalse);
    expect(await sesion.compras.listarRecientes(), isEmpty);
    await t.pumpWidget(const SizedBox.shrink());
    await sesion.cerrar();
  });
}
