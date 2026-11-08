import 'package:flutter_test/flutter_test.dart';
import 'package:compras_offline/data/local/base_local.dart';
import 'package:compras_offline/data/repositories/compras_sqlite.dart';
import 'package:compras_offline/domain/models/identidad_y_fecha.dart';
import 'package:compras_offline/domain/models/valores_compra.dart';
import 'package:compras_offline/features/inicio/viewmodels/inicio_viewmodel.dart';

import '../data/compras_sqlite_test.dart' as datos;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BaseLocal db;
  late ComprasSqlite repo;
  setUp(() async {
    db = BaseLocal.enMemoria();
    repo = ComprasSqlite(db, dispositivoId: datos.id(6001));
    await datos.semilla(db);
  });
  tearDown(() => db.close());
  test('base vacía devuelve cero sin compras de ejemplo', () async {
    final r = await repo.resumenInicio(FechaLocalCompra('2026-11-08'));
    expect(r.totalMes, BigInt.zero);
    expect(r.comprasLocales, 0);
    expect(r.ultimas, isEmpty);
  });
  test('mes calendario por fecha local y resumen completo más allá de cien compras', () async {
    for (var n = 1; n <= 101; n++) {
      await repo.guardarYEncolar(
        datos.solicitud(datos.fixture(n: n), operacion: 5000 + n),
      );
    }
    await db.customStatement(
      "UPDATE compras SET fecha_local='2026-10-31' WHERE id=?",
      [datos.id(1001)],
    );
    await db.customStatement(
      "UPDATE compras SET fecha_local='2026-12-01' WHERE id=?",
      [datos.id(1002)],
    );
    await db.customStatement("UPDATE compras SET estado='anulada' WHERE id=?", [
      datos.id(1003),
    ]);
    await db.customStatement(
      "UPDATE compras SET eliminado_en='2026' WHERE id=?",
      [datos.id(1004)],
    );
    final r = await repo.resumenInicio(FechaLocalCompra('2026-11-08'));
    expect(r.comprasMes, 97);
    expect(r.totalMes, BigInt.from(97 * 1499));
    expect(r.comprasLocales, 99);
    expect(r.totalLocal, BigInt.from(99 * 1499));
    expect(r.ultimas, hasLength(3));
    expect(r.ultimas.first.id, datos.id(1002));
  });
  test('agregados mayores a int64 se mantienen exactos', () async {
    for (var n = 1; n <= 2; n++) {
      await repo.guardarYEncolar(
        datos.solicitud(
          datos.fixture(n: n, precio: Entero64.maximo),
          operacion: 5000 + n,
        ),
      );
    }
    final r = await repo.resumenInicio(FechaLocalCompra('2026-11-08'));
    expect(r.totalMes, (Entero64.maximo - BigInt.from(301)) * BigInt.two);
  });
  test(
    'ViewModel recarga datos sin conservar un total ficticio ante error',
    () async {
      final vm = InicioViewModel(repo, reloj: () => DateTime(2026, 11, 8));
      await vm.cargar();
      expect(vm.resumen!.totalMes, BigInt.zero);
      await repo.guardarYEncolar(datos.solicitud(datos.fixture()));
      await vm.cargar();
      expect(vm.resumen!.totalMes, BigInt.from(1499));
      await db.customStatement("UPDATE compras SET moneda='USD'");
      await vm.cargar();
      expect(vm.fallo, isTrue);
      expect(vm.resumen, isNull);
      vm.dispose();
    },
  );
}
