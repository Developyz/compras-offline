import 'package:compras_offline/demo/revision_demo.dart';
import 'package:compras_offline/domain/models/compra.dart';
import 'package:compras_offline/domain/models/identidad_y_fecha.dart';
import 'package:compras_offline/domain/models/producto.dart';
import 'package:compras_offline/domain/models/valores_compra.dart';
import 'package:compras_offline/domain/repositories/repositorios.dart';
import 'package:compras_offline/features/tickets/viewmodels/revision_ticket_viewmodel.dart';
import 'package:compras_offline/features/tickets/views/revision_view.dart';
import 'package:compras_offline/features/tickets/views/confirmacion_revision_view.dart';
import 'package:compras_offline/presentation/widgets/compra_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ViewModelInspeccionable extends RevisionTicketViewModel {
  ViewModelInspeccionable(super.borrador);
  bool get tieneOyentes => hasListeners;
}

String id(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
ImportePyg pyg(String valor) => ImportePyg.desdeTexto(valor);
Compra personalizada(
  String total, {
  String? leido,
  List<String> pendientes = const [],
}) => Compra(
  id: id(1),
  fechaCompra: DateTime.utc(2026, 11, 9),
  fechaLocal: FechaLocalCompra('2026-11-08'),
  estado: EstadoCompra.borrador,
  comercioId: id(2),
  sucursal: SucursalCompra(id: id(3), comercioId: id(2)),
  canastaId: id(4),
  observaciones: 'Ticket revisado',
  totalTicket: pyg(leido ?? total),
  camposPorRevisar: pendientes,
  detalles: [
    DetalleCompra(
      id: id(5),
      numeroLinea: 1,
      descripcionTicket: 'Producto diferente',
      cantidad: CantidadCompra.desdeTexto('1'),
      unidadCantidadId: id(6),
      precioUnitario: pyg(total),
      importeBruto: pyg(total),
      contextoHistorico: ContextoHistorico(
        nombreProducto: 'Producto histórico',
        presentacion: 'Envase anterior',
      ),
    ),
  ],
  descuentos: [],
);

Future<void> montar(WidgetTester tester, RevisionTicketViewModel vm) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: RevisionView(viewModel: vm)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('dos incertidumbres se resuelven por separado y notifican cambios', () {
    final vm = ViewModelInspeccionable(
      crearRevisionDemo(DemoReviewScenario.uncertain),
    );
    addTearDown(vm.dispose);
    var cambios = 0;
    vm.addListener(() => cambios++);
    expect(vm.puedeContinuar, isFalse);
    vm.marcarCampoRevisado(campoProductoDemo);
    expect(vm.puedeContinuar, isFalse);
    expect(vm.camposPendientes, [campoCantidadDemo]);
    vm.marcarCampoRevisado(campoCantidadDemo);
    expect(vm.puedeContinuar, isTrue);
    expect(cambios, 2);
    expect(() => vm.camposPendientes.clear(), throwsUnsupportedError);
  });

  test(
    'diferencia usa el cálculo real y nunca se corrige al abrir o confirmar',
    () {
      final vm = ViewModelInspeccionable(personalizada('9137', leido: '9500'));
      addTearDown(vm.dispose);
      expect(vm.totalCoincide, isFalse);
      expect(() => vm.prepararConfirmacion(), throwsStateError);
      expect(vm.borrador.totalTicket!.valor, BigInt.from(9500));
      vm.actualizarTotalTicket(pyg('9137'));
      expect(vm.puedeContinuar, isTrue);
      expect(
        vm.prepararConfirmacion().resumen.totalCalculado.valor,
        BigInt.from(9137),
      );
    },
  );

  test(
    'quitar total bloquea; poner uno coincidente no resuelve campos dudosos',
    () {
      final vm = ViewModelInspeccionable(
        personalizada('9137', pendientes: ['producto']),
      );
      addTearDown(vm.dispose);
      vm.actualizarTotalTicket(null);
      expect(vm.totalCoincide, isFalse);
      expect(vm.puedeContinuar, isFalse);
      vm.actualizarTotalTicket(pyg('9137'));
      expect(vm.puedeContinuar, isFalse);
      vm.marcarCampoRevisado('producto');
      expect(vm.puedeContinuar, isTrue);
    },
  );

  test('recargar restablece revisión y no arrastra comprobaciones del ticket anterior', () {
    final vm = ViewModelInspeccionable(
      crearRevisionDemo(DemoReviewScenario.uncertain),
    );
    addTearDown(vm.dispose);
    vm.marcarCampoRevisado(campoProductoDemo);
    vm.marcarCampoRevisado(campoCantidadDemo);
    vm.cargarBorrador(crearRevisionDemo(DemoReviewScenario.uncertain));
    expect(vm.camposPendientes, hasLength(2));
    expect(vm.puedeContinuar, isFalse);
  });

  test('preparar conserva metadatos e historia; el borrador original no cambia de estado', () {
    final original = personalizada('9137', leido: '9500');
    final vm = ViewModelInspeccionable(original);
    addTearDown(vm.dispose);
    vm.actualizarTotalTicket(pyg('9137'));
    final preparada = vm.prepararConfirmacion();
    expect(preparada.estado, EstadoCompra.confirmada);
    expect(original.estado, EstadoCompra.borrador);
    expect(original.totalTicket!.valor, BigInt.from(9500));
    expect(preparada.id, original.id);
    expect(preparada.fechaCompra, original.fechaCompra);
    expect(preparada.fechaLocal.valor, original.fechaLocal.valor);
    expect(preparada.comercioId, original.comercioId);
    expect(preparada.sucursal!.id, original.sucursal!.id);
    expect(preparada.canastaId, original.canastaId);
    expect(preparada.observaciones, original.observaciones);
    expect(
      preparada.detalles.single.contextoHistorico.presentacion,
      'Envase anterior',
    );
    expect(vm.borrador.estado, EstadoCompra.borrador);
  });

  test('un campo ya revisado o ajeno no produce cambios; solo se cargan borradores', () {
    final vm = ViewModelInspeccionable(
      crearRevisionDemo(DemoReviewScenario.correct),
    );
    addTearDown(vm.dispose);
    var cambios = 0;
    vm.addListener(() => cambios++);
    vm.marcarCampoRevisado('inexistente');
    expect(cambios, 0);
    final confirmada = vm.prepararConfirmacion();
    expect(() => vm.cargarBorrador(confirmada), throwsArgumentError);
    expect(() => ViewModelInspeccionable(confirmada), throwsArgumentError);
    expect(vm.borrador.estado, EstadoCompra.borrador);
  });

  test('preparar no duplica descuentos y conserva el bruto leído', () {
    final original = crearRevisionDemo(DemoReviewScenario.correct);
    final vm = ViewModelInspeccionable(original);
    addTearDown(vm.dispose);
    final primera = vm.prepararConfirmacion();
    final segunda = vm.prepararConfirmacion();
    expect(primera.resumen.totalCalculado.valor, BigInt.from(6000));
    expect(segunda.descuentos.single.importe.valor, BigInt.from(400));
    expect(
      segunda.detalles.first.importeBruto.valor,
      original.detalles.first.importeBruto.valor,
    );
    expect(segunda.id, primera.id);
  });

  test(
    'formato de dominio preserva enteros grandes y cantidades fraccionarias',
    () {
      expect(
        guaraniesDominio(pyg('9223372036854775807')),
        '₲ 9.223.372.036.854.775.807',
      );
      expect(guaraniesDominio(pyg('0')), '₲ 0');
      expect(cantidadDominio(CantidadCompra.desdeTexto('3.200')), '3,2');
      expect(cantidadDominio(CantidadCompra.desdeTexto('0.001')), '0,001');
      expect(cantidadDominio(CantidadCompra.desdeTexto('1')), '1');
    },
  );

  test('solicitud local preserva versión exacta e identidad para futuros reintentos', () {
    final solicitud = EscrituraLocal(
      entidad: personalizada('9137'),
      operacionId: id(7),
      versionBase: BigInt.parse('9007199254740993'),
    );
    expect(solicitud.versionBase.toString(), '9007199254740993');
    expect(solicitud.operacionId, id(7));
    expect(
      () => EscrituraLocal(
        entidad: solicitud.entidad,
        operacionId: id(7),
        versionBase: BigInt.from(-1),
      ),
      throwsArgumentError,
    );
    expect(
      () => EscrituraLocal(
        entidad: solicitud.entidad,
        operacionId: id(7),
        versionBase: Entero64.maximo + BigInt.one,
      ),
      throwsRangeError,
    );
  });

  testWidgets(
    'la vista renderiza el total del ViewModel y responde a sus correcciones',
    (tester) async {
      final vm = ViewModelInspeccionable(personalizada('9137', leido: '9500'));
      await montar(tester, vm);
      expect(
        find.text('El ticket indica ₲ 9.500 y el cálculo suma ₲ 9.137.'),
        findsOneWidget,
      );
      expect(find.text('Producto diferente'), findsOneWidget);
      expect(find.textContaining('₲ 6.000'), findsNothing);
      vm.actualizarTotalTicket(pyg('9137'));
      await tester.pumpAndSettle();
      expect(
        find.text('Total leído y calculado coinciden: ₲ 9.137.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      expect(vm.tieneOyentes, isFalse);
      vm.actualizarTotalTicket(null); // La View ya no recibe notificaciones.
      vm.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reemplazar ViewModel desprende el anterior y no lo destruye', (
    tester,
  ) async {
    final anterior = ViewModelInspeccionable(personalizada('9137'));
    final nuevo = ViewModelInspeccionable(personalizada('8888'));
    await montar(tester, anterior);
    await montar(tester, nuevo);
    expect(anterior.tieneOyentes, isFalse);
    expect(nuevo.tieneOyentes, isTrue);
    anterior.actualizarTotalTicket(null);
    await tester.pumpAndSettle();
    expect(
      find.text('Total leído y calculado coinciden: ₲ 8.888.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    anterior.dispose();
    nuevo.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'la confirmación muestra la compra preparada, también en pantalla pequeña',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vm = ViewModelInspeccionable(personalizada('9137'));
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            home: Scaffold(body: RevisionView(viewModel: vm)),
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                body: ConfirmacionRevisionView(settings.arguments! as Compra),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boton = find.byKey(const ValueKey('review-confirm'));
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
      expect(find.text('Compra revisada'), findsOneWidget);
      final preparada = tester
          .widget<ConfirmacionRevisionView>(
            find.byType(ConfirmacionRevisionView),
          )
          .compra;
      expect(preparada.totalTicket!.valor, BigInt.from(9137));
      expect(preparada.estado, EstadoCompra.confirmada);
      expect(find.textContaining('₲ 6.000'), findsNothing);
      expect(find.textContaining('Simulación completada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      vm.dispose();
    },
  );
}
