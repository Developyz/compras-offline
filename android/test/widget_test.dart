import 'package:compras_offline/app/canasta_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('presenta la bienvenida sin simular datos de compras', (
    tester,
  ) async {
    await tester.pumpWidget(const CanastaApp());
    expect(find.text('canasta.'), findsOneWidget);
    expect(
      find.text('Vista de preparación · Sin datos reales'),
      findsOneWidget,
    );
    expect(find.textContaining('guaraníes'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite texto ampliado en una pantalla pequeña', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(2)),
        child: CanastaApp(),
      ),
    );
    final marca = tester.element(find.text('canasta.'));
    expect(MediaQuery.textScalerOf(marca).scale(10), 20);
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
