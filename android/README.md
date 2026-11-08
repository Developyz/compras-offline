# Canasta — Flutter con guardado local

Flutter **3.47.5 / Dart 3.13.4**, versión **0.4.1+5**. El arranque abre SQLite privado y prepara una sesión con identidad persistente. Cámara → **Registrar a mano** permite introducir productos, cantidades, precios, descuento general, total y fecha/hora. Revisión valida y guarda compra + cola + recibo en una transacción; Historial muestra compras locales.

Inicio muestra gastos reales del mes, resumen local y últimas compras. Canasta, Productos y Estados conservan ejemplos identificados como prototipo. Cámara/OCR y sincronización todavía no funcionan. Los tickets de ejemplo solo abren una vista previa y no se guardan. No se crean compras ficticias durante el arranque.

## Ejecutar en Windows

Con Flutter 3.47.5 y Android SDK preparados, desde esta carpeta:

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <id-del-celular>
```

Usar el identificador que muestra `flutter devices`. `.flutter-version` registra el SDK; `pubspec.lock` fija las dependencias resueltas. No copiar rutas Linux a Windows. El guardado local no requiere servidor PostgreSQL ni acceso a la PC.

## Organización

- `lib/app/`: arranque, sesión y rutas; controla la vida de la base.
- `lib/features/tickets/`: carga manual, revisión y ViewModel con progreso/error/reintento.
- `lib/features/compras/`: historial y detalle local, además del prototipo conservado.
- `lib/domain/`: modelos, validación e interfaces de repositorios.
- `lib/data/`: Drift/SQLite y adaptador transaccional de compras.
- `lib/demo/`: fixtures del prototipo, separados de compras reales.
- `assets/db/`: esquema v4 y catálogo compartido de unidades, generados desde `DB/`.
- `test/`: 90 pruebas de dominio, UI y SQLite real.

Se utilizan ChangeNotifier, intl/fl_chart, Drift 2.35.3, sqlite3 3.9.1, path_provider 2.1.6, path 1.9.1 y uuid 4.6.0. Riverpod/Dio y plugins de captura/red siguen pendientes. Se usa SQL explícito con Drift, sin generadores adicionales.

## Comprobaciones

Análisis y **90 pruebas** correctos para Inicio real. El APK anterior 0.4.0+4 se compiló, verificó e instaló correctamente según la prueba del usuario en su Redmi. GitHub Actions genera la actualización 0.4.1+5; su instalación física sigue pendiente.

La plantilla conserva AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1, compile/target 36, mínimo 24 y NDK 28.2.13676358. No hay firma de publicación configurada; release conserva la configuración inicial de desarrollo. El proyecto nativo está en `android/` dentro de esta carpeta.

No versionar bases con datos personales, `local.properties`, cachés, claves ni APKs. El arranque rechaza bases manuales sin versión o catálogos/identidades incompatibles, sin borrarlas ni usar datos ficticios como reemplazo.

Ver [flujo, captura y límites](../docs/guardado-local-en-pantalla.md), [SQLite y cola](../docs/sqlite-compras-y-cola.md) y [preparación Windows](../docs/preparacion-windows.md).

Ver [Inicio con gastos reales](../docs/inicio-gastos-reales.md).
