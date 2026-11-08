# Canasta — proyecto Flutter mínimo

Base generada con Flutter **3.47.5 / Dart 3.13.4**, con destino Android y una pantalla de bienvenida. No implementa todavía compras, ViewModels, SQLite, cámara, OCR, API ni sincronización.

El [prototipo HTML](../prototipo/README.md) sigue siendo la referencia visual completa. Las ocho pantallas y sus estados se trasladarán después a Flutter.

## Ejecutar en Windows

Desde esta carpeta, con Flutter 3.47.5 y Android SDK preparados:

```powershell
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <id-del-celular>
```

`<id-del-celular>` se reemplaza por el identificador que muestra `flutter devices`. El archivo `.flutter-version` registra el SDK usado; no instala ni selecciona Flutter automáticamente. `pubspec.lock` registra las dependencias realmente resueltas.

La aplicación no necesita una PC servidora, PostgreSQL ni credenciales para mostrar esta bienvenida. Las herramientas de desarrollo sí descargan dependencias durante su preparación.

## Estructura creada

- `lib/main.dart`: entrada sin conexiones.
- `lib/app/canasta_app.dart`: tema y composición visual.
- `lib/features/inicio/views/bienvenida_view.dart`: bienvenida accesible y desplazable.
- `lib/domain/`, `lib/data/`, `lib/services/`: responsabilidades pendientes documentadas en cada carpeta.
- `test/widget_test.dart`: bienvenida y texto ampliado en pantalla pequeña.
- `android/`: proyecto nativo generado por Flutter. Por eso la ruta completa es `android/android/` desde la raíz del repositorio.

La base usa solamente Flutter y sus herramientas de pruebas/análisis. Riverpod, Drift, Dio y plugins se incorporarán por etapas; la matriz de candidatos no es el lockfile de esta base.

## Configuración nativa registrada

Plantilla generada: AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1; valores del SDK Flutter: compile/target 36, mínimo 24, NDK 28.2.13676358. Registrar cualquier ajuste que requiera la compilación nativa.

`local.properties`, cachés, wrappers regenerables por Flutter, claves y APKs no se versionan. Usar `flutter run`/`flutter build apk` para que Flutter prepare su configuración local; no copiar rutas de este entorno Linux a Windows.

No hay firma de publicación configurada. La plantilla release conserva la configuración inicial de desarrollo; esta entrega se comprueba en debug.

El análisis, las dos pruebas y la compilación Dart pasaron. El intento de APK se detuvo por falta de espacio del entorno temporal al extraer el NDK; no hay APK verificado en esta entrega.

Ver [validación de las bases](../docs/validacion-proyectos-base.md) para resultados y límites de las pruebas, y [estructura y etapas](../docs/estructura-y-etapas.md) para los siguientes pasos.
