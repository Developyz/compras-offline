import 'dart:async';
import 'dart:io';

import 'package:compras_offline/app/canasta_app.dart';
import 'package:compras_offline/app/inicio_local.dart';
import 'package:compras_offline/app/sesion_local.dart';
import 'package:compras_offline/data/local/base_local.dart';
import 'package:compras_offline/domain/models/compra.dart';
import 'package:compras_offline/domain/repositories/repositorios.dart';
import 'package:compras_offline/features/tickets/viewmodels/registro_manual.dart';
import 'package:compras_offline/features/tickets/viewmodels/revision_ticket_viewmodel.dart';
import 'package:compras_offline/features/tickets/views/revision_view.dart';
import 'package:compras_offline/features/compras/views/compras_locales_view.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

String id(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
Compra manual(SesionLocal sesion, {String total = '2337'}) =>
    crearBorradorManual(
      lineas: [
        LineaManual(
          descripcion: 'Mi producto',
          cantidad: '2',
          precio: '1237',
          unidad: sesion.unidades.first,
        ),
      ],
      total: total,
      descuento: '137',
      fecha: DateTime(2026, 11, 8, 10, 30),
      nuevoId: sesion.nuevoId,
    );

class RepoControlado implements RepositorioCompras {
  final llamadas = <EscrituraLocal<Compra>>[];
  late Future<ReciboGuardadoLocal> Function(EscrituraLocal<Compra>) respuesta;
  @override
  Future<ReciboGuardadoLocal> guardarYEncolar(EscrituraLocal<Compra> e) {
    llamadas.add(e);
    return respuesta(e);
  }

  @override
  Future<Compra?> obtenerPorId(String id) async => null;
  @override
  Future<List<Compra>> listarRecientes({int limite = 100}) async => [];
}

ReciboGuardadoLocal recibo(EscrituraLocal<Compra> e) =>
    ReciboGuardadoLocal(entidadId: e.entidad.id, operacionId: e.operacionId);

Future<void> pulsar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> escribir(WidgetTester tester, String key, String texto) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.enterText(f, texto);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);
  late SesionLocal sesion;
  setUp(() async => sesion = await SesionLocal.abrir(BaseLocal.enMemoria()));
  tearDown(() async => sesion.cerrar());

  test(
    'doble pulsación genera una sola solicitud y espera al recibo',
    () async {
      final repo = RepoControlado();
      final pendiente = Completer<ReciboGuardadoLocal>();
      repo.respuesta = (_) => pendiente.future;
      var ids = 0;
      final vm = RevisionTicketViewModel(
        manual(sesion),
        repositorio: repo,
        nuevoId: () {
          ids++;
          return id(900);
        },
      );
      addTearDown(vm.dispose);
      final guardado = vm.guardar();
      await vm.guardar();
      expect(vm.estadoGuardado, EstadoGuardado.guardando);
      expect(vm.recibo, isNull);
      expect(vm.puedeGuardar, isFalse);
      expect(repo.llamadas, hasLength(1));
      expect(() => vm.actualizarTotalTicket(null), throwsStateError);
      pendiente.complete(recibo(repo.llamadas.single));
      await guardado;
      expect(vm.estadoGuardado, EstadoGuardado.guardado);
      expect(vm.compraGuardada!.estado, EstadoCompra.confirmada);
      await vm.guardar();
      expect(repo.llamadas, hasLength(1));
      expect(ids, 1);
    },
  );

  test('commit con respuesta perdida se reintenta con la misma operación sin duplicar SQLite', () async {
    final repo = RepoControlado();
    var perderRespuesta = true;
    repo.respuesta = (e) async {
      final resultado = await sesion.compras.guardarYEncolar(e);
      if (perderRespuesta) {
        perderRespuesta = false;
        throw StateError('Respuesta perdida después del commit');
      }
      return resultado;
    };
    final vm = RevisionTicketViewModel(manual(sesion), repositorio: repo);
    addTearDown(vm.dispose);
    await vm.guardar();
    expect(vm.estadoGuardado, EstadoGuardado.error);
    expect(vm.recibo, isNull);
    expect(vm.compraGuardada, isNull);
    expect((await sesion.compras.listarRecientes()), hasLength(1));
    expect(() => vm.cargarBorrador(manual(sesion)), throwsStateError);
    await vm.guardar();
    expect(vm.estadoGuardado, EstadoGuardado.guardado);
    expect(identical(repo.llamadas[0], repo.llamadas[1]), isTrue);
    expect(
      (await sesion.base
              .customSelect('SELECT count(*) n FROM cola_sincronizacion')
              .getSingle())
          .read<int>('n'),
      1,
    );
  });

  test('un error o un recibo ajeno nunca anuncia guardado', () async {
    final repo = RepoControlado();
    repo.respuesta = (_) async => throw StateError('Disco no disponible');
    final vm = RevisionTicketViewModel(manual(sesion), repositorio: repo);
    addTearDown(vm.dispose);
    await vm.guardar();
    expect(vm.estadoGuardado, EstadoGuardado.error);
    expect(vm.recibo, isNull);
    repo.respuesta = (_) async =>
        ReciboGuardadoLocal(entidadId: id(1), operacionId: id(2));
    await vm.guardar();
    expect(vm.estadoGuardado, EstadoGuardado.error);
    expect(vm.compraGuardada, isNull);
    expect(repo.llamadas[0].operacionId, repo.llamadas[1].operacionId);
  });

  test(
    'cerrar el ViewModel durante una escritura no cancela ni notifica después',
    () async {
      final repo = RepoControlado();
      final pendiente = Completer<ReciboGuardadoLocal>();
      repo.respuesta = (_) => pendiente.future;
      final vm = RevisionTicketViewModel(manual(sesion), repositorio: repo);
      var avisos = 0;
      vm.addListener(() => avisos++);
      final guardado = vm.guardar();
      vm.dispose();
      pendiente.complete(recibo(repo.llamadas.single));
      await guardado;
      expect(avisos, 1);
      expect(vm.puedeGuardar, isFalse);
    },
  );

  test(
    'total diferente bloquea el repositorio y modo ejemplo no escribe',
    () async {
      final repo = RepoControlado();
      repo.respuesta = (e) async => recibo(e);
      final bloqueado = RevisionTicketViewModel(
        manual(sesion, total: '2400'),
        repositorio: repo,
      );
      final ejemplo = RevisionTicketViewModel(manual(sesion));
      addTearDown(bloqueado.dispose);
      addTearDown(ejemplo.dispose);
      await bloqueado.guardar();
      await ejemplo.guardar();
      expect(repo.llamadas, isEmpty);
      expect(bloqueado.estadoGuardado, EstadoGuardado.listo);
      expect(ejemplo.recibo, isNull);
    },
  );

  test('carga manual conserva coma, miles, descuento y fecha sin doubles', () {
    final compra = crearBorradorManual(
      lineas: [
        LineaManual(
          descripcion: 'A granel',
          cantidad: '1,5',
          precio: '2.000',
          unidad: sesion.unidades[1],
        ),
      ],
      total: '2.900',
      descuento: '100',
      fecha: DateTime(2026, 11, 8, 12, 5),
      nuevoId: sesion.nuevoId,
    );
    expect(compra.resumen.totalCalculado.valor, BigInt.from(2900));
    expect(compra.detalles.single.cantidad.milesimas, BigInt.from(1500));
    expect(compra.fechaLocal.valor, '2026-11-08');
    for (final invalido in ['1,50', '1.20', '-1', '1e3']) {
      expect(() => leerGuaranies(invalido), throwsFormatException);
    }
    expect(
      () => crearBorradorManual(
        lineas: [],
        total: '0',
        descuento: '0',
        fecha: DateTime.now(),
        nuevoId: sesion.nuevoId,
      ),
      throwsArgumentError,
    );
  });

  test(
    'identidad, unidades y compra sobreviven al cierre y reapertura de archivo',
    () async {
      final directorio = await Directory.systemTemp.createTemp('sesion-local-');
      final archivo = File('${directorio.path}/app.sqlite');
      var disco = await SesionLocal.abrir(BaseLocal.enArchivo(archivo));
      final dispositivo = disco.dispositivoId;
      final vm = disco.revisar(manual(disco));
      await vm.guardar();
      final compraId = vm.compraGuardada!.id;
      vm.dispose();
      await disco.cerrar();
      disco = await SesionLocal.abrir(
        BaseLocal.enArchivo(archivo),
        nuevoId: () => throw StateError('No debe regenerar identidad'),
      );
      try {
        expect(disco.dispositivoId, dispositivo);
        expect(
          (await disco.compras.obtenerPorId(compraId))!
              .resumen
              .totalCalculado
              .valor,
          BigInt.from(2337),
        );
        expect(
          (await disco.base
                  .customSelect('SELECT count(*) n FROM unidades_medida')
                  .getSingle())
              .read<int>('n'),
          3,
        );
        expect(
          (await disco.base
                  .customSelect('SELECT count(*) n FROM compras')
                  .getSingle())
              .read<int>('n'),
          1,
        );
      } finally {
        await disco.cerrar();
        await directorio.delete(recursive: true);
      }
    },
  );

  test('catálogo incompatible aborta sin sobrescribir', () async {
    final base = BaseLocal.enMemoria();
    await base.customStatement(
      "INSERT INTO unidades_medida (id,nombre,simbolo,dimension,factor_base,creado_en,actualizado_en) VALUES (?,'Otra unidad','u','conteo',1,'2026','2026')",
      [id(1)],
    );
    await expectLater(SesionLocal.abrir(base), throwsStateError);
    // La fábrica cierra la conexión al fallar; no crea una sesión alternativa en memoria.
  });

  test(
    'migración v3 recupera la identidad de la cola y conserva recibos',
    () async {
      final directorio = await Directory.systemTemp.createTemp('sesion-v3-');
      final archivo = File('${directorio.path}/v3.sqlite');
      final anterior = await SesionLocal.abrir(BaseLocal.enArchivo(archivo));
      final dispositivo = anterior.dispositivoId;
      final vm = anterior.revisar(manual(anterior));
      await vm.guardar();
      vm.dispose();
      await anterior.base.customStatement('DROP TABLE metadatos_locales');
      await anterior.base.customStatement(
        'DELETE FROM versiones_esquema WHERE version=4',
      );
      await anterior.base.customStatement('PRAGMA user_version=3');
      await anterior.cerrar();
      final nueva = await SesionLocal.abrir(
        BaseLocal.enArchivo(archivo),
        nuevoId: () => throw StateError('Debe recuperar identidad'),
      );
      try {
        expect(nueva.dispositivoId, dispositivo);
        expect(await nueva.compras.listarRecientes(), hasLength(1));
        expect(
          (await nueva.base
                  .customSelect('SELECT count(*) n FROM recibos_guardado_local')
                  .getSingle())
              .read<int>('n'),
          1,
        );
      } finally {
        await nueva.cerrar();
        await directorio.delete(recursive: true);
      }
    },
  );

  test(
    'listado local valida límite y excluye eliminadas sin borrar datos',
    () async {
      final vm = sesion.revisar(manual(sesion));
      await vm.guardar();
      final idCompra = vm.compraGuardada!.id;
      vm.dispose();
      await expectLater(
        sesion.compras.listarRecientes(limite: 101),
        throwsRangeError,
      );
      expect(await sesion.compras.listarRecientes(limite: 1), hasLength(1));
      await sesion.base.customStatement(
        "UPDATE compras SET eliminado_en='2026-11-08' WHERE id=?",
        [idCompra],
      );
      expect(await sesion.compras.listarRecientes(), isEmpty);
      expect(
        (await sesion.base
                .customSelect('SELECT count(*) n FROM compras')
                .getSingle())
            .read<int>('n'),
        1,
      );
    },
  );

  testWidgets('pantalla espera al recibo, muestra error y permite reintento', (
    tester,
  ) async {
    final repo = RepoControlado();
    var pendiente = Completer<ReciboGuardadoLocal>();
    repo.respuesta = (_) => pendiente.future;
    final vm = RevisionTicketViewModel(manual(sesion), repositorio: repo);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RevisionView(viewModel: vm)),
      ),
    );
    await tester.pumpAndSettle();
    final boton = find.byKey(const ValueKey('review-confirm'));
    await tester.ensureVisible(boton);
    await tester.pumpAndSettle();
    await tester.tap(boton);
    await tester.pump();
    expect(find.text('Guardada en el celular'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    pendiente.completeError(StateError('Fallo'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar guardado'), findsOneWidget);
    expect(find.text('Guardada en el celular'), findsNothing);
    pendiente = Completer<ReciboGuardadoLocal>();
    await tester.tap(boton);
    await tester.pump();
    pendiente.complete(recibo(repo.llamadas.last));
    await tester.pumpAndSettle();
    expect(find.text('Guardada en el celular'), findsOneWidget);
    expect(find.text('Pendiente de sincronización'), findsOneWidget);
    expect(find.text('PROTOTIPO · DATOS FICTICIOS'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    vm.dispose();
  });

  testWidgets(
    'compra propia: formulario, revisión, SQLite e historial sin fixtures',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: CanastaApp(sesionLocal: sesion),
        ),
      );
      await tester.pumpAndSettle();
      await pulsar(tester, find.byKey(const ValueKey('nav-/captura')));
      await pulsar(tester, find.byKey(const ValueKey('registro-manual')));
      await escribir(tester, 'descripcion-0', 'Yerba de mi compra');
      await escribir(tester, 'cantidad-0', '2');
      await escribir(tester, 'precio-0', '1.237');
      await escribir(tester, 'descuento-manual', '137');
      await escribir(tester, 'total-manual', '2.337');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await pulsar(tester, find.byKey(const ValueKey('revisar-manual')));
      expect(find.text('Yerba de mi compra'), findsOneWidget);
      expect(find.text('Guardar en el celular'), findsOneWidget);
      await pulsar(tester, find.byKey(const ValueKey('review-confirm')));
      expect(find.text('Guardada en el celular'), findsOneWidget);
      await pulsar(tester, find.text('Ver mis compras'));
      expect(find.text('Mis compras'), findsOneWidget);
      expect(find.text('₲ 2.337'), findsOneWidget);
      expect(find.text('Almacén Central'), findsNothing);
      expect(await sesion.compras.listarRecientes(), hasLength(1));
      await pulsar(tester, find.text('₲ 2.337'));
      expect(find.text('Yerba de mi compra'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('arranque informa fallo y reintenta sin usar una base ficticia', (
    tester,
  ) async {
    var intentos = 0;
    await tester.pumpWidget(
      InicioLocal(
        abrir: () async {
          if (++intentos == 1) throw StateError('Sin acceso');
          return sesion;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No se pudo abrir el almacenamiento.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Cada compra cuenta.'), findsOneWidget);
    expect(intentos, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'error de historial se reintenta sin presentarlo como lista vacía',
    (tester) async {
      final repo = RepoLecturas();
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ComprasLocalesView(repo))),
      );
      await tester.pumpAndSettle();
      expect(find.text('No pudimos cargar tus compras.'), findsOneWidget);
      expect(find.text('Todavía no hay compras guardadas.'), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Todavía no hay compras guardadas.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test(
    'identidades anteriores ambiguas conservan compra y cola para conciliación',
    () async {
      final directorio = await Directory.systemTemp.createTemp(
        'sesion-ambigua-',
      );
      final archivo = File('${directorio.path}/ambigua.sqlite');
      final anterior = await SesionLocal.abrir(BaseLocal.enArchivo(archivo));
      final vm = anterior.revisar(manual(anterior));
      await vm.guardar();
      vm.dispose();
      await anterior.base.customStatement('DELETE FROM metadatos_locales');
      await anterior.base.customStatement(
        "INSERT INTO cola_sincronizacion (operacion_id,dispositivo_id,entidad,entidad_id,version_base,accion,datos_json,creado_en) VALUES (?,?,'productos',?,0,'guardar','{}','2026')",
        [id(999), id(998), id(997)],
      );
      await anterior.cerrar();
      await expectLater(
        SesionLocal.abrir(BaseLocal.enArchivo(archivo)),
        throwsA(
          predicate((e) => e.toString().contains('Identidades anteriores')),
        ),
      );
      final lectura = BaseLocal.enArchivo(archivo);
      try {
        expect(
          (await lectura
                  .customSelect('SELECT count(*) n FROM metadatos_locales')
                  .getSingle())
              .read<int>('n'),
          0,
        );
        expect(
          (await lectura
                  .customSelect('SELECT count(*) n FROM compras')
                  .getSingle())
              .read<int>('n'),
          1,
        );
        expect(
          (await lectura
                  .customSelect('SELECT count(*) n FROM cola_sincronizacion')
                  .getSingle())
              .read<int>('n'),
          2,
        );
      } finally {
        await lectura.close();
        await directorio.delete(recursive: true);
      }
    },
  );
  test('varios productos conservan unidades y no crean identidades de catálogo inventadas', () {
    final compra = crearBorradorManual(
      lineas: [
        LineaManual(
          descripcion: 'Paquete',
          cantidad: '1',
          precio: '1.000',
          unidad: sesion.unidades[0],
        ),
        LineaManual(
          descripcion: 'A granel',
          cantidad: '0,5',
          precio: '4.000',
          unidad: sesion.unidades[1],
        ),
      ],
      total: '2.900',
      descuento: '100',
      fecha: DateTime(2026, 11, 8, 10),
      nuevoId: sesion.nuevoId,
    );
    expect(compra.detalles, hasLength(2));
    expect(compra.resumen.subtotal.valor, BigInt.from(3000));
    expect(
      compra.detalles.last.contextoHistorico.escalaCantidad!.factorBase,
      BigInt.from(1000),
    );
    expect(compra.detalles.every((d) => d.productoId == null), isTrue);
    expect({
      compra.id,
      ...compra.detalles.map((d) => d.id),
      ...compra.descuentos.map((d) => d.id),
    }, hasLength(4));
  });

  testWidgets(
    'corregir el total manual es explícito y habilita guardado real',
    (tester) async {
      final vm = sesion.revisar(manual(sesion, total: '2400'));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RevisionView(viewModel: vm)),
        ),
      );
      await tester.pumpAndSettle();
      await pulsar(tester, find.text('Corregir total'));
      await tester.enterText(find.byType(TextFormField), '2.337');
      await pulsar(tester, find.text('Aplicar'));
      expect(vm.puedeGuardar, isTrue);
      expect(await sesion.compras.listarRecientes(), isEmpty);
      await pulsar(tester, find.byKey(const ValueKey('review-confirm')));
      expect(find.text('Guardada en el celular'), findsOneWidget);
      expect(
        (await sesion.compras.listarRecientes()).single.totalTicket!.valor,
        BigInt.from(2337),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      vm.dispose();
    },
  );
}

class RepoLecturas extends RepoControlado {
  int intentos = 0;
  @override
  Future<List<Compra>> listarRecientes({int limite = 100}) async {
    if (++intentos == 1) throw StateError('Fallo de lectura');
    return [];
  }
}
