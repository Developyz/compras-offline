import 'dart:convert';
import 'dart:io';

import 'package:compras_offline/data/local/base_local.dart';
import 'package:compras_offline/data/local/compra_codec.dart';
import 'package:compras_offline/data/repositories/compras_sqlite.dart';
import 'package:compras_offline/domain/models/compra.dart';
import 'package:compras_offline/domain/models/identidad_y_fecha.dart';
import 'package:compras_offline/domain/models/producto.dart';
import 'package:compras_offline/domain/models/valores_compra.dart';
import 'package:compras_offline/domain/repositories/repositorios.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

String id(int n) => '00000000-0000-4000-8000-${n.toString().padLeft(12, '0')}';
ImportePyg pyg(BigInt n) => ImportePyg(n);
Compra fixture({
  int n = 1,
  BigInt? precio,
  String descripcion = 'ARR 500',
  bool canasta = false,
}) {
  final bruto = precio ?? BigInt.from(1800);
  return Compra(
    id: id(1000 + n),
    fechaCompra: DateTime.utc(2026, 11, 9, 2),
    fechaLocal: FechaLocalCompra('2026-11-08'),
    estado: EstadoCompra.confirmada,
    comercioId: id(201),
    sucursal: SucursalCompra(id: id(202), comercioId: id(201)),
    canastaId: canasta ? id(203) : null,
    totalTicket: pyg(bruto - BigInt.from(301)),
    ajuste: BigInt.from(-1),
    observaciones: 'Ajuste explícito de un guaraní',
    detalles: [
      DetalleCompra(
        id: id(2000 + n),
        numeroLinea: 1,
        productoId: id(204),
        descripcionTicket: descripcion,
        cantidad: CantidadCompra.desdeTexto('1'),
        unidadCantidadId: id(205),
        precioUnitario: pyg(bruto),
        importeBruto: pyg(bruto),
        contextoHistorico: ContextoHistorico(
          nombreProducto: 'Arroz anterior',
          presentacion: 'Bolsa 500 g',
          contenido: ContenidoHistorico(
            cantidad: CantidadCompra.desdeTexto('500'),
            simbolo: 'g',
            escala: EscalaHistorica(
              dimension: DimensionMedida.masa,
              factorBase: BigInt.one,
            ),
          ),
          escalaCantidad: EscalaHistorica(
            dimension: DimensionMedida.conteo,
            factorBase: BigInt.one,
          ),
        ),
      ),
    ],
    descuentos: [
      DescuentoCompra(
        id: id(3000 + n),
        descripcion: 'Producto',
        importe: pyg(BigInt.from(100)),
        detalleId: id(2000 + n),
      ),
      DescuentoCompra(
        id: id(4000 + n),
        descripcion: 'General',
        importe: pyg(BigInt.from(200)),
      ),
    ],
  );
}

EscrituraLocal<Compra> solicitud(
  Compra c, {
  int operacion = 5001,
  BigInt? version,
}) => EscrituraLocal(
  entidad: c,
  operacionId: id(operacion),
  versionBase: version ?? BigInt.zero,
);

Future<void> semilla(BaseLocal db) async {
  final auditoria =
      "1,'2026-11-08T00:00:00.000Z','2026-11-08T00:00:00.000Z',NULL";
  await db.customStatement(
    "INSERT INTO unidades_medida VALUES (?, 'Unidad','u','conteo',1,$auditoria)",
    [id(205)],
  );
  await db.customStatement(
    "INSERT INTO unidades_medida VALUES (?, 'Gramo','g','masa',1,$auditoria)",
    [id(206)],
  );
  await db.customStatement(
    "INSERT INTO comercios VALUES (?, 'Mercado',$auditoria)",
    [id(201)],
  );
  await db.customStatement(
    "INSERT INTO sucursales VALUES (?,?,'Centro',NULL,$auditoria)",
    [id(202), id(201)],
  );
  await db.customStatement(
    "INSERT INTO canastas VALUES (?, 'Mensual','abierta',$auditoria)",
    [id(203)],
  );
  await db.customStatement(
    "INSERT INTO productos VALUES (?, 'Arroz actual',NULL,NULL,'Bolsa actual',500000,?,'unidad',$auditoria)",
    [id(204), id(206)],
  );
}

Future<int> contar(BaseLocal db, String tabla) async =>
    (await db.customSelect('SELECT count(*) AS n FROM $tabla').getSingle())
        .read<int>('n');
final tablasCompra = [
  'compras',
  'detalles_compra',
  'descuentos_compra',
  'cola_sincronizacion',
  'recibos_guardado_local',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Estas pruebas abren archivos independientes con ejecutores diferentes.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);
  late BaseLocal db;
  late ComprasSqlite repo;
  setUp(() async {
    db = BaseLocal.enMemoria();
    repo = ComprasSqlite(db, dispositivoId: id(6001));
    await semilla(db);
  });
  tearDown(() async => db.close());

  test(
    'esquema real, FK activas y una escritura completa con cola sin servidor',
    () async {
      expect(
        (await db
                .customSelect(
                  "SELECT count(*) n FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
                )
                .getSingle())
            .read<int>('n'),
        22,
      );
      expect(
        (await db.customSelect('PRAGMA foreign_keys').getSingle()).read<int>(
          'foreign_keys',
        ),
        1,
      );
      final c = fixture(canasta: true);
      final recibo = await repo.guardarYEncolar(solicitud(c));
      expect(recibo.entidadId, c.id);
      expect(recibo.operacionId, id(5001));
      expect(await contar(db, 'compras'), 1);
      expect(await contar(db, 'detalles_compra'), 1);
      expect(await contar(db, 'descuentos_compra'), 2);
      expect(await contar(db, 'recibos_guardado_local'), 1);
      final cola =
          (await db
                  .customSelect('SELECT * FROM cola_sincronizacion')
                  .getSingle())
              .data;
      expect(cola['estado'], 'pendiente');
      expect(cola['servidor_id'], isNull);
      expect(cola['hash_solicitud'], isNull);
      expect(cola['intentos'], 0);
      expect(cola['version_base'], 0);
      expect(
        jsonDecode(cola['datos_json'] as String),
        CompraCodec.codificar(c),
      );
      final leida = (await repo.obtenerPorId(c.id))!;
      expect(CompraCodec.codificar(leida), CompraCodec.codificar(c));
      expect(leida.fechaLocal.valor, '2026-11-08');
      expect(
        leida.detalles.single.contextoHistorico.presentacion,
        'Bolsa 500 g',
      );
    },
  );

  for (final tabla in [
    'detalles_compra',
    'descuentos_compra',
    'cola_sincronizacion',
    'recibos_guardado_local',
  ]) {
    test('fallo en $tabla revierte cabecera, hijos, cola y recibo', () async {
      await db.customStatement(
        "CREATE TRIGGER falla BEFORE INSERT ON $tabla BEGIN SELECT RAISE(ABORT,'fallo inyectado'); END",
      );
      await expectLater(
        repo.guardarYEncolar(solicitud(fixture())),
        throwsA(isA<sqlite.SqliteException>()),
      );
      for (final t in tablasCompra) {
        expect(await contar(db, t), 0, reason: t);
      }
      await db.customStatement('DROP TRIGGER falla');
      await repo.guardarYEncolar(solicitud(fixture()));
      expect(await contar(db, 'compras'), 1);
    });
  }

  test(
    'reintento exacto no duplica ni restablece una operación enviando',
    () async {
      final s = solicitud(fixture());
      await repo.guardarYEncolar(s);
      await db.customStatement(
        "UPDATE cola_sincronizacion SET estado='enviando', intentos=3",
      );
      await repo.guardarYEncolar(s);
      for (final t in [
        'compras',
        'cola_sincronizacion',
        'recibos_guardado_local',
      ]) {
        expect(await contar(db, t), 1);
      }
      final fila =
          (await db
                  .customSelect(
                    'SELECT estado,intentos FROM cola_sincronizacion',
                  )
                  .getSingle())
              .data;
      expect(fila['estado'], 'enviando');
      expect(fila['intentos'], 3);
    },
  );

  test(
    'misma operación con contenido o dispositivo diferente se rechaza',
    () async {
      await repo.guardarYEncolar(solicitud(fixture()));
      await expectLater(
        repo.guardarYEncolar(solicitud(fixture(descripcion: 'Otro producto'))),
        throwsA(isA<ConflictoGuardadoLocal>()),
      );
      final otro = ComprasSqlite(db, dispositivoId: id(6002));
      await expectLater(
        otro.guardarYEncolar(solicitud(fixture())),
        throwsA(isA<ConflictoGuardadoLocal>()),
      );
      expect(
        (await repo.obtenerPorId(id(1001)))!.detalles.single.descripcionTicket,
        'ARR 500',
      );
      expect(await contar(db, 'cola_sincronizacion'), 1);
    },
  );

  test('otra operación no sobrescribe compra; versiones no implementadas se rechazan', () async {
    await repo.guardarYEncolar(solicitud(fixture()));
    await expectLater(
      repo.guardarYEncolar(solicitud(fixture(), operacion: 5002)),
      throwsA(isA<ConflictoGuardadoLocal>()),
    );
    await expectLater(
      repo.guardarYEncolar(
        solicitud(fixture(n: 2), operacion: 5002, version: BigInt.one),
      ),
      throwsUnsupportedError,
    );
    expect(await contar(db, 'compras'), 1);
    expect(await contar(db, 'cola_sincronizacion'), 1);
  });

  test(
    'referencias ausentes o eliminadas impiden cualquier escritura',
    () async {
      await db.customStatement(
        "UPDATE productos SET eliminado_en='2026-11-08' WHERE id=?",
        [id(204)],
      );
      await expectLater(
        repo.guardarYEncolar(solicitud(fixture())),
        throwsA(isA<ConflictoGuardadoLocal>()),
      );
      for (final t in tablasCompra) {
        expect(await contar(db, t), 0);
      }
      await db.customStatement('DELETE FROM productos');
      await expectLater(
        repo.guardarYEncolar(solicitud(fixture())),
        throwsA(isA<ConflictoGuardadoLocal>()),
      );
    },
  );

  test('SQLite y JSON preservan int64 máximo sin double', () async {
    final c = fixture(precio: Entero64.maximo);
    await repo.guardarYEncolar(solicitud(c));
    final leida = (await repo.obtenerPorId(c.id))!;
    expect(leida.resumen.subtotal.valor, Entero64.maximo);
    final cola = await db
        .customSelect('SELECT datos_json FROM cola_sincronizacion')
        .getSingle();
    final datos = jsonDecode(cola.read<String>('datos_json')) as Map;
    expect(datos['subtotal_menor'].toString(), '9223372036854775807');
    expect(datos['subtotal_menor'], isA<int>());
    expect(CompraCodec.codificar(leida), CompraCodec.codificar(c));
  });

  test(
    'lectura ausente es null y lectura inconsistente propaga error',
    () async {
      expect(await repo.obtenerPorId(id(999)), isNull);
      final datos = CompraCodec.codificar(fixture());
      expect(
        () => CompraCodec.decodificar(id(1001), {
          ...datos,
          'fecha_compra': '2026-02-31T00:00:00.000Z',
        }),
        throwsFormatException,
      );
      expect(
        () => CompraCodec.decodificar(id(1001), {
          ...datos,
          'subtotal_menor': 1800.0,
        }),
        throwsFormatException,
      );

      await repo.guardarYEncolar(solicitud(fixture()));
      await db.customStatement(
        'UPDATE detalles_compra SET descuento_menor=0,importe_final_menor=importe_bruto_menor',
      );
      await expectLater(repo.obtenerPorId(id(1001)), throwsFormatException);
    },
  );

  test(
    'edición del catálogo no cambia contexto histórico almacenado',
    () async {
      await repo.guardarYEncolar(solicitud(fixture()));
      await db.customStatement(
        "UPDATE productos SET nombre='Producto nuevo',presentacion='Envase nuevo'",
      );
      final c = (await repo.obtenerPorId(id(1001)))!;
      expect(
        c.detalles.single.contextoHistorico.nombreProducto,
        'Arroz anterior',
      );
      expect(c.detalles.single.contextoHistorico.contenido!.simbolo, 'g');
      expect(c.detalles.single.descripcionTicket, 'ARR 500');
    },
  );

  test('reapertura en archivo conserva compra y recibo idempotente', () async {
    final directorio = await Directory.systemTemp.createTemp('compras-sqlite-');
    final archivo = File('${directorio.path}/prueba.sqlite');
    var disco = BaseLocal.enArchivo(archivo);
    try {
      await semilla(disco);
      final r = ComprasSqlite(disco, dispositivoId: id(6001));
      await r.guardarYEncolar(solicitud(fixture()));
      await disco.close();
      disco = BaseLocal.enArchivo(archivo);
      final reabierto = ComprasSqlite(disco, dispositivoId: id(6001));
      expect(
        (await reabierto.obtenerPorId(id(1001)))!.resumen.totalCalculado.valor,
        BigInt.from(1499),
      );
      await reabierto.guardarYEncolar(solicitud(fixture()));
      expect(await contar(disco, 'cola_sincronizacion'), 1);
    } finally {
      await disco.close();
      await directorio.delete(recursive: true);
    }
  });

  test('migración Drift v2 a v3 conserva compras y añade recibos', () async {
    await repo.guardarYEncolar(solicitud(fixture()));
    // Base auxiliar con el mismo esquema v2, sin recibos, antes de abrir Drift.
    final directorio = await Directory.systemTemp.createTemp(
      'compras-migracion-',
    );
    final archivo = File('${directorio.path}/v2.sqlite');
    final v2 = BaseLocal.enArchivo(archivo);
    await semilla(v2);
    await ComprasSqlite(
      v2,
      dispositivoId: id(6001),
    ).guardarYEncolar(solicitud(fixture()));
    await v2.customStatement('DROP TABLE recibos_guardado_local');
    await v2.customStatement('DELETE FROM versiones_esquema WHERE version=3');
    await v2.customStatement('PRAGMA user_version=2');
    await v2.close();
    final v3 = BaseLocal.enArchivo(archivo);
    try {
      expect(
        (await ComprasSqlite(
          v3,
          dispositivoId: id(6001),
        ).obtenerPorId(id(1001)))!.resumen.totalCalculado.valor,
        BigInt.from(1499),
      );
      expect(await contar(v3, 'recibos_guardado_local'), 0);
      expect(
        (await v3.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        3,
      );
      expect(await contar(v3, 'cola_sincronizacion'), 1);
    } finally {
      await v3.close();
      await directorio.delete(recursive: true);
    }
  });

  test('base manual sin versión se rechaza sin borrar tablas', () async {
    final directorio = await Directory.systemTemp.createTemp('compras-manual-');
    final archivo = File('${directorio.path}/manual.sqlite');
    final raw = sqlite.sqlite3.open(archivo.path);
    raw.execute('CREATE TABLE legado (valor TEXT)');
    raw.execute("INSERT INTO legado VALUES ('preservado')");
    raw.close();
    final protegida = BaseLocal(NativeDatabase(archivo));
    try {
      await expectLater(
        protegida.customSelect('SELECT 1').get(),
        throwsUnsupportedError,
      );
    } finally {
      await protegida.close();
      final lectura = sqlite.sqlite3.open(archivo.path);
      expect(
        lectura.select('SELECT valor FROM legado').single['valor'],
        'preservado',
      );
      lectura.close();
      await directorio.delete(recursive: true);
    }
  });
  test(
    'fallo de creación revierte el esquema y permite volver a abrir limpio',
    () async {
      final directorio = await Directory.systemTemp.createTemp(
        'compras-esquema-',
      );
      final archivo = File('${directorio.path}/nueva.sqlite');
      final fallida = BaseLocal(
        NativeDatabase(archivo),
        assets: _AssetFallido(),
      );
      await expectLater(
        fallida.customSelect('SELECT 1').get(),
        throwsA(isA<sqlite.SqliteException>()),
      );
      await fallida.close();
      final raw = sqlite.sqlite3.open(archivo.path);
      expect(
        raw
            .select(
              "SELECT count(*) n FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
            )
            .single['n'],
        0,
      );
      raw.close();
      final limpia = BaseLocal.enArchivo(archivo);
      try {
        await semilla(limpia);
        expect(await contar(limpia, 'compras'), 0);
      } finally {
        await limpia.close();
        await directorio.delete(recursive: true);
      }
    },
  );

  test('recibo persiste tras retirar una operación ya confirmada', () async {
    final s = solicitud(fixture());
    await repo.guardarYEncolar(s);
    await db.customStatement(
      "UPDATE cola_sincronizacion SET estado='confirmada'",
    );
    await db.customStatement(
      "DELETE FROM cola_sincronizacion WHERE estado='confirmada'",
    );
    await repo.guardarYEncolar(s);
    expect(await contar(db, 'cola_sincronizacion'), 0);
    expect(await contar(db, 'compras'), 1);
    expect(await contar(db, 'recibos_guardado_local'), 1);
  });

  test(
    'dos llamadas concurrentes de la misma operación producen un solo guardado',
    () async {
      final s = solicitud(fixture());
      final recibos = await Future.wait([
        repo.guardarYEncolar(s),
        repo.guardarYEncolar(s),
      ]);
      expect(recibos.map((r) => r.operacionId).toSet(), {id(5001)});
      expect(await contar(db, 'compras'), 1);
      expect(await contar(db, 'cola_sincronizacion'), 1);
    },
  );
}

class _AssetFallido extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final sql = jsonDecode(await rootBundle.loadString(key)) as List;
    return jsonEncode([...sql, 'SENTENCIA INVALIDA']);
  }

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}
