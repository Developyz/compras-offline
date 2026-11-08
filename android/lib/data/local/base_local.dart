import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// SQL explícito sobre Drift, sin generación de tablas ni conexiones remotas.
class BaseLocal extends GeneratedDatabase {
  BaseLocal(super.executor, {AssetBundle? assets})
    : _assets = assets ?? rootBundle;
  final AssetBundle _assets;

  static BaseLocal enMemoria() => BaseLocal(
    NativeDatabase.memory(setup: (db) => db.execute('PRAGMA foreign_keys=ON')),
  );

  static BaseLocal enArchivo(File archivo) => BaseLocal(
    NativeDatabase.createInBackground(
      archivo,
      setup: (db) => db.execute('PRAGMA foreign_keys=ON'),
    ),
  );

  /// Invocar desde composición de dependencias, nunca desde una View.
  static Future<BaseLocal> abrirPrivada() async {
    final directorio = await getApplicationSupportDirectory();
    await directorio.create(recursive: true);
    return enArchivo(File(path.join(directorio.path, 'compras.sqlite')));
  }

  @override
  int get schemaVersion => 4;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) => transaction(() async {
      final existentes = await customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      ).get();
      if (existentes.isNotEmpty) {
        throw UnsupportedError(
          'Base manual sin versión Drift: migrar explícitamente; no se recrea',
        );
      }
      final sql = (jsonDecode(
        await _assets.loadString('assets/db/esquema_v4.json'),
      ) as List).cast<String>();
      for (final sentencia in sql) {
        await customStatement(sentencia);
      }
    }),
    onUpgrade: (m, desde, hasta) => transaction(() async {
      if ((desde != 2 && desde != 3) || hasta != 4) {
        throw UnsupportedError('Migración no soportada: $desde → $hasta');
      }
      final sql = (jsonDecode(
        await _assets.loadString('assets/db/esquema_v4.json'),
      ) as List).cast<String>();
      for (final sentencia in sql.where(
        (s) =>
            (desde == 2 &&
                (s.startsWith('CREATE TABLE recibos_guardado_local') ||
                    s.startsWith('CREATE INDEX idx_recibos_entidad') ||
                    s.startsWith(
                      'INSERT INTO versiones_esquema VALUES (3,',
                    ))) ||
            s.startsWith('CREATE TABLE metadatos_locales') ||
            s.startsWith('INSERT INTO versiones_esquema VALUES (4,'),
      )) {
        await customStatement(sentencia);
      }
    }),
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys=ON');
      final errores = await customSelect('PRAGMA foreign_key_check').get();
      if (errores.isNotEmpty) {
        throw StateError('La base contiene referencias inválidas');
      }
    },
  );
}
