import 'package:compras_offline/app/canasta_app.dart';
import 'package:compras_offline/demo/demo_data.dart';
import 'package:compras_offline/presentation/widgets/demo_widgets.dart';
import 'package:compras_offline/presentation/widgets/purchase_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openApp(WidgetTester tester, {bool largeText = false}) async {
  await tester.pumpWidget(
    largeText
        ? const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: CanastaApp(),
          )
        : const CanastaApp(),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> tab(WidgetTester tester, String route) =>
    tapVisible(tester, find.byKey(ValueKey('nav-$route')));

Future<void> selectExample(
  WidgetTester tester,
  String key,
  String option,
) async {
  await tapVisible(tester, find.byKey(ValueKey(key)));
  await tester.ensureVisible(find.text(option).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

FilledButton confirmButton(WidgetTester tester) => tester.widget<FilledButton>(
  find.descendant(
    of: find.byKey(const ValueKey('review-confirm')),
    matching: find.byType(FilledButton),
  ),
);

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
  test('los importes se muestran en guaraníes enteros y las series coinciden con compras', () {
    expect(guaranies(48000), '₲ 48.000');
    expect(guaranies(0), '₲ 0');
    expect(demoPurchases.fold<int>(0, (sum, p) => sum + p.total), 48000);
    for (final p in demoPurchases) {
      expect(p.lines.fold<int>(0, (sum, line) => sum + line.total), p.subtotal);
      expect(p.subtotal - p.discount, p.total);
    }
    for (var index = 0; index < demoProducts.length; index++) {
      for (final point in demoProducts[index].points) {
        final purchase = demoPurchases.singleWhere(
          (p) => p.store == point.store,
        );
        expect(point.price, purchase.lines[index].unitPrice);
      }
    }
  });

  testWidgets(
    'inicio usa datos ficticios y la cámara está centrada en la barra',
    (tester) async {
      await openApp(tester);
      expect(find.text('Cada compra cuenta.'), findsOneWidget);
      expect(find.text('PROTOTIPO · DATOS FICTICIOS'), findsOneWidget);
      expect(find.text('₲ 48.000'), findsOneWidget);
      final camera = tester.getCenter(
        find.byKey(const ValueKey('nav-/captura')),
      );
      expect(
        camera.dx,
        closeTo(
          tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
          1,
        ),
      );
      await tab(tester, '/captura');
      expect(find.text('Capturá tu ticket'), findsOneWidget);
      expect(find.text('VISTA ILUSTRATIVA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'el flujo de ticket confirma solo una simulación sin duplicar historial',
    (tester) async {
      await openApp(tester);
      await tab(tester, '/captura');
      await tapVisible(tester, find.text('Probar con ticket de ejemplo'));
      expect(find.text('Revisá tu compra'), findsOneWidget);
      expect(confirmButton(tester).onPressed, isNotNull);
      await tapVisible(tester, find.byKey(const ValueKey('review-confirm')));
      expect(find.textContaining('Simulación completada.'), findsOneWidget);
      await tab(tester, '/historial');
      expect(find.byType(DemoPurchaseTile), findsNWidgets(3));
      await tapVisible(tester, find.text('Almacén Central'));
      expect(find.text('05 de noviembre de 2026 · PYG'), findsOneWidget);
      expect(find.text('₲ 18.000'), findsOneWidget);
    },
  );

  testWidgets('ambos datos dudosos requieren revisión antes de confirmar', (
    tester,
  ) async {
    await openApp(tester);
    await tab(tester, '/captura');
    await tapVisible(tester, find.text('Probar con ticket de ejemplo'));
    await selectExample(tester, 'review-scenario', 'Datos dudosos');
    expect(confirmButton(tester).onPressed, isNull);
    await tapVisible(tester, find.byKey(const ValueKey('review-product')));
    expect(confirmButton(tester).onPressed, isNull);
    await tapVisible(tester, find.byKey(const ValueKey('review-quantity')));
    expect(confirmButton(tester).onPressed, isNotNull);
    await selectExample(tester, 'review-scenario', 'Lectura correcta');
    await selectExample(tester, 'review-scenario', 'Datos dudosos');
    expect(confirmButton(tester).onPressed, isNull);
  });

  testWidgets('una diferencia no se corrige ni confirma silenciosamente', (
    tester,
  ) async {
    await openApp(tester);
    await tab(tester, '/canasta');
    await tapVisible(tester, find.text('Revisar compra de ejemplo'));
    await selectExample(tester, 'review-scenario', 'Total diferente');
    expect(confirmButton(tester).onPressed, isNull);
    expect(
      find.text('El ticket indica ₲ 6.500 y el cálculo suma ₲ 6.000.'),
      findsOneWidget,
    );
    await tapVisible(tester, find.byKey(const ValueKey('review-total')));
    expect(confirmButton(tester).onPressed, isNotNull);
    expect(
      find.text('Total leído y calculado coinciden: ₲ 6.000.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'productos permite buscar, ver el gráfico y volver sin perder el filtro',
    (tester) async {
      await openApp(tester);
      await tab(tester, '/productos');
      await tester.enterText(
        find.byKey(const ValueKey('product-search')),
        'leche',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('product-arroz')), findsNothing);
      await tapVisible(tester, find.byKey(const ValueKey('product-leche')));
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('−14,3 %'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('price-point-0')));
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('price-point-0')))
            .selected,
        isTrue,
      );
      expect(
        find.textContaining('02 nov 2026 · Supermercado del Parque'),
        findsOneWidget,
      );
      await tapVisible(tester, find.byType(BackButton));
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('product-search')))
            .controller!
            .text,
        'leche',
      );
    },
  );

  testWidgets('búsqueda sin coincidencias permite recuperar el catálogo', (
    tester,
  ) async {
    await openApp(tester);
    await tab(tester, '/productos');
    await tester.enterText(
      find.byKey(const ValueKey('product-search')),
      'inexistente',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No encontramos ese producto'), findsOneWidget);
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('product-arroz')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-leche')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-manzana')), findsOneWidget);
  });

  testWidgets(
    'reintentar un error vuelve a pendiente sin simular confirmación remota',
    (tester) async {
      await openApp(tester);
      await tapVisible(tester, find.text('Ver estados de compras'));
      await selectExample(tester, 'state-scenario', 'Error al sincronizar');
      expect(find.text('No pudimos confirmar el envío'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('state-action')));
      expect(find.text('Esperando a tu PC'), findsOneWidget);
      expect(
        find.textContaining('No se hizo ninguna conexión.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('los siete estados tienen explicación y acciones de ejemplo', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(tester, find.text('Ver estados de compras'));
    const states = {
      'Sin compras': 'Tu primera compra empieza acá',
      'Canasta vacía': 'Prepará tu próxima compra',
      'Ticket ilegible': 'No pudimos leer este ticket',
      'Guardada en el celular': 'Tu compra quedó registrada',
      'Pendiente': 'Esperando a tu PC',
      'Error al sincronizar': 'No pudimos confirmar el envío',
      'Sincronizada': 'Tu compra está sincronizada',
    };
    for (final e in states.entries) {
      await selectExample(tester, 'state-scenario', e.key);
      expect(find.text(e.value), findsOneWidget);
      expect(find.byKey(const ValueKey('state-action')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'las nueve pantallas admiten texto ampliado en un teléfono pequeño',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openApp(tester, largeText: true);
      final title = tester.element(find.text('Cada compra cuenta.'));
      expect(MediaQuery.textScalerOf(title).scale(10), 20);
      final navigator = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      final routes = <String, Object?>{
        '/canasta': null,
        '/captura': null,
        '/revision': null,
        '/historial': null,
        '/productos': null,
        '/producto': demoProducts.first,
        '/compra': DemoPurchaseArguments(demoPurchases.first),
        '/estados': null,
      };
      for (final e in routes.entries) {
        navigator.pushNamedAndRemoveUntil<void>(
          e.key,
          (r) => r.isFirst,
          arguments: e.value,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: e.key);
      }
      await selectExample(tester, 'state-scenario', 'Guardada en el celular');
      expect(find.text('Tu compra quedó registrada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
