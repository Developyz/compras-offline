import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:compras_offline/app/canasta_app.dart';
import 'package:compras_offline/app/sesion_local.dart';
import 'package:compras_offline/data/local/base_local.dart';

Brightness brillo(WidgetTester t) =>
    Theme.of(t.element(find.byType(Scaffold).last)).brightness;
Future<void> alternar(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('alternar-tema')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('oscuro y claro se alternan sin perder búsqueda ni ruta', (
    t,
  ) async {
    await t.pumpWidget(const CanastaApp());
    await t.pumpAndSettle();
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.pushNamed('/productos');
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('product-search')), 'leche');
    await alternar(t);
    expect(brillo(t), Brightness.dark);
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('product-search')))
          .controller!
          .text,
      'leche',
    );
    expect(find.byKey(const ValueKey('product-arroz')), findsNothing);
    await alternar(t);
    expect(brillo(t), Brightness.light);
    expect(t.takeException(), isNull);
  });
  testWidgets('todas las pantallas se abren en oscuro y texto grande', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: CanastaApp(),
      ),
    );
    await t.pumpAndSettle();
    await alternar(t);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    for (final ruta in [
      '/canasta',
      '/captura',
      '/revision',
      '/historial',
      '/productos',
      '/producto',
      '/estados',
    ]) {
      nav.pushNamedAndRemoveUntil(ruta, (r) => r.isFirst);
      await t.pumpAndSettle();
      expect(brillo(t), Brightness.dark);
      expect(t.takeException(), isNull, reason: ruta);
    }
  });
  testWidgets('cambiar tema conserva datos de la carga manual', (t) async {
    final sesion = await SesionLocal.abrir(BaseLocal.enMemoria());
    await t.pumpWidget(CanastaApp(sesionLocal: sesion));
    await t.pumpAndSettle();
    t.state<NavigatorState>(find.byType(Navigator).first).pushNamed('/manual');
    await t.pumpAndSettle();
    await t.enterText(
      find.byKey(const ValueKey('descripcion-0')),
      'Mi producto',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await alternar(t);
    expect(brillo(t), Brightness.dark);
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('descripcion-0')))
          .controller!
          .text,
      'Mi producto',
    );
    expect(await sesion.compras.listarRecientes(), isEmpty);
    await t.pumpWidget(const SizedBox.shrink());
    await sesion.cerrar();
  });
}
