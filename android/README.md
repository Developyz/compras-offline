# Canasta — prototipo Flutter

Flutter **3.47.5 / Dart 3.13.4**, versión 0.3.0+3. Incluye nueve pantallas principales y una vista previa de revisión, con datos ficticios: inicio, canasta, captura, revisión, historial, detalle de compra, productos, detalle de producto y estados.

Cámara destacada en el centro de la navegación y moneda paraguaya ₲ sin decimales. Es posible buscar productos, explorar sus precios, revisar tres escenarios de ticket y recorrer siete estados. Continuar la revisión prepara una compra en memoria y abre su vista previa; no agrega compras al historial.

Incluye modelos de producto, canasta y compra y reglas de revisión en Dart puro, integradas en la revisión del ticket mediante un ViewModel. ComprasSqlite implementa creación y lectura con cola/recibos, aún sin conectar el botón de guardado. Productos/canastas mantienen interfaces sin implementación; cámara, OCR, API y sincronización siguen pendientes. Funciona sin PC servidora para mostrar el prototipo.

## Ejecutar en Windows

Con Flutter y Android SDK preparados, desde esta carpeta:

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <id-del-celular>
```

Reemplazar `<id-del-celular>` por el identificador de `flutter devices`. `.flutter-version` registra el SDK; `pubspec.lock` registra las dependencias resueltas. Las herramientas descargan dependencias durante su preparación.

## Organización

- `lib/app/`: tema, idioma español y rutas.
- `lib/demo/`: ejemplos de presentación, separados del dominio y sus reglas.
- `lib/presentation/`: navegación y widgets compartidos.
- `lib/features/`: pantallas por función y ViewModel del ticket.
- `lib/domain/`: producto, canasta, compra, valores y reglas de revisión; adaptadores pendientes.
- `lib/data/`: base Drift/SQLite, codec y repositorio de compras; adaptadores restantes pendientes.
- `lib/services/`: comentarios de responsabilidades de captura/red pendientes.
- `test/widget_test.dart`: diez pruebas de importes, navegación, revisión, filtros, estados y accesibilidad.
- `test/domain/` y `test/viewmodels/`: modelos, reglas, ViewModel e integración de revisión.

Se incorporan `flutter_localizations`, `intl` 0.20.3 y `fl_chart` 1.3.0. Se incorporan Drift 2.35.3, sqlite3 3.9.1, path_provider 2.1.6 y path 1.9.1. Riverpod, Dio y los plugins de captura/red siguen pendientes. La revisión utiliza ChangeNotifier y reglas de dominio; el resto de las pantallas mantiene el estado de demostración.

## Validación y configuración nativa

La etapa visual pasó análisis, diez pruebas y compilación Dart (`flutter build bundle --debug`). La compilación de APK y la prueba en celular siguen pendientes: el intento de la etapa anterior se detuvo al extraer el NDK por falta de espacio del entorno temporal.

La plantilla conserva AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1, compile/target 36, mínimo 24 y NDK 28.2.13676358. No hay firma de publicación configurada; release conserva la configuración inicial de desarrollo. El proyecto nativo está en `android/` dentro de esta carpeta.

No versionar `local.properties`, cachés, claves ni APKs. Flutter prepara las rutas locales; no copiar rutas Linux a Windows.

La etapa SQLite pasó análisis, 69 pruebas y compilación Dart. Ver [SQLite y cola](../docs/sqlite-compras-y-cola.md). La etapa anterior de ViewModel pasó 51 pruebas. Ver [repositorios y ViewModel](../docs/repositorios-y-viewmodel-revision.md). La ampliación previa de modelos pasó 39 pruebas. Ver [modelos ampliados](../docs/modelos-producto-canasta-compra.md). Ver [modelos y revisión](../docs/modelos-y-revision-compra.md).

Ver [vistas, capturas y validación](../docs/vistas-flutter.md), [prototipo HTML](../prototipo/README.md) y [validación de las bases](../docs/validacion-proyectos-base.md).
