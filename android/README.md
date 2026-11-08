# Canasta — prototipo Flutter

Flutter **3.47.5 / Dart 3.13.4**, versión visual 0.2.0+2. Incluye nueve pantallas con datos ficticios: inicio, canasta, captura, revisión, historial, detalle de compra, productos, detalle de producto y estados.

Cámara destacada en el centro de la navegación y moneda paraguaya ₲ sin decimales. Es posible buscar productos, explorar sus precios, revisar tres escenarios de ticket y recorrer siete estados. Confirmar un ticket solamente abre una demostración; no agrega compras al historial.

Incluye una primera base de modelos y reglas de revisión en Dart puro, todavía sin integrar en las vistas. No implementa todavía ViewModels de negocio, SQLite, cámara, OCR, API ni sincronización. Funciona sin PC servidora para mostrar el prototipo.

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
- `lib/demo/`: ejemplos de presentación, separados de los futuros modelos.
- `lib/presentation/`: navegación y widgets compartidos.
- `lib/features/`: pantallas por función.
- `lib/domain/`: valores, borrador y reglas de revisión; modelos completos pendientes.
- `lib/data/`, `lib/services/`: comentarios de conexiones y responsabilidades pendientes.
- `test/widget_test.dart`: diez pruebas de importes, navegación, revisión, filtros, estados y accesibilidad.

Se incorporan `flutter_localizations`, `intl` 0.20.3 y `fl_chart` 1.3.0. Riverpod, Drift, Dio y plugins siguen pendientes. El estado local de las pantallas solamente sirve para la demostración.

## Validación y configuración nativa

La etapa visual pasó análisis, diez pruebas y compilación Dart (`flutter build bundle --debug`). La compilación de APK y la prueba en celular siguen pendientes: el intento de la etapa anterior se detuvo al extraer el NDK por falta de espacio del entorno temporal.

La plantilla conserva AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1, compile/target 36, mínimo 24 y NDK 28.2.13676358. No hay firma de publicación configurada; release conserva la configuración inicial de desarrollo. El proyecto nativo está en `android/` dentro de esta carpeta.

No versionar `local.properties`, cachés, claves ni APKs. Flutter prepara las rutas locales; no copiar rutas Linux a Windows.

La nueva base de dominio pasó análisis y 25 pruebas en total. Ver [modelos y revisión](../docs/modelos-y-revision-compra.md).

Ver [vistas, capturas y validación](../docs/vistas-flutter.md), [prototipo HTML](../prototipo/README.md) y [validación de las bases](../docs/validacion-proyectos-base.md).
