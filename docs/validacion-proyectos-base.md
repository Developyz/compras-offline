> Informe de la etapa inicial. La ampliación visual y sus diez pruebas se documentan en [vistas Flutter](vistas-flutter.md).

# Proyectos mínimos — alcance y comprobación

## Qué se generó

- `android/`: proyecto Flutter con destino Android, bienvenida de Canasta, tema visual, dos pruebas de widgets y comentarios de las capas pendientes.
- `server/`: proyecto Java/Spring Boot, Maven Wrapper, prueba de arranque y paquetes con comentarios TODO.
- Se conservan el prototipo HTML completo, SQL y contratos de API como referencias. No se modificó el esquema ni se ejecutó una base de datos para esta entrega.

## Versiones efectivamente usadas en Linux

| Componente | Versión |
| --- | --- |
| Flutter | 3.47.5; commit 6a19cca56475dbfba1478ee68d7bd0c2ef891da1 |
| Dart | 3.13.4, incluido con Flutter |
| JDK | Eclipse Temurin 21.0.13+9 |
| Spring Boot | 4.1.2 |
| Maven Wrapper / Maven | 3.3.4 (only-script) / 3.10.0 |
| Plantilla Android | AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1 |
| SDK Android | Compile/target 36, mínimo 24 |

Maven y JDK se descargaron de sus distribuidores y se comprobaron sus checksums; Gradle tiene checksum en sus propiedades de wrapper. Flutter se obtuvo del tag oficial 3.47.5 y su revisión queda registrada en `.metadata`. La prueba no acredita un archivo de instalación Windows que no se descargó.

La primera ejecución encontró solo un entorno Java sin compilador completo. Se preparó el JDK indicado y se repitieron los controles. No se redujo la versión de Java del proyecto para ocultar ese problema.

## Resultado de comprobaciones

| Comprobación | Resultado |
| --- | --- |
| `flutter pub get` | Correcto; `pubspec.lock` real generado |
| `flutter analyze` | Sin observaciones |
| `flutter test` | 2 pruebas aprobadas |
| `flutter build bundle --debug` | Correcto; compilación Dart generada |
| APK debug ARM64 | No generado: sin espacio al extraer NDK 28.2.13676358 |
| `mvnw verify` | Correcto; 1 prueba, JAR empaquetado |
| `java -jar ...` | Arranque correcto y salida normal, sin HTTP ni PostgreSQL |

El intento nativo llegó a Gradle y a la preparación del NDK. Android CLI devolvió `No space left on device` al extraer `android-ndk-r28c-linux.zip`; no se considera un APK compilado ni una validación nativa terminada. Se retiraron los archivos temporales de extracción fallida para recuperar espacio. Repetir la compilación con suficiente almacenamiento; no se modificó Flutter ni se desactivaron controles para eludir el NDK.

La prueba con pantalla de 320 × 568 y texto a escala 2 encontró un desbordamiento en la marca de bienvenida. Se corrigió permitiendo ajustar su ancho y se volvió a comprobar que la escala se aplica realmente y no hay excepciones de layout.

Las comprobaciones nativas se realizan con herramientas temporales del entorno Linux. Sus rutas, certificados de proxy, SDK y cachés no se incorporan al repositorio. No se instalaron herramientas en la PC del usuario.

## Dependencias incluidas y diferidas

Flutter incorpora solo el SDK, flutter_test y flutter_lints 6.0.0. El servidor incorpora spring-boot-starter y spring-boot-starter-test. Esta entrega no demuestra que toda la matriz de plugins candidatos resuelva o compile conjuntamente.

Riverpod, Drift, Dio, cámara, OCR, escáner, almacenamiento seguro, Workmanager y gráficos se agregarán en sus fases. MVC, Security, JDBC y Flyway tampoco están habilitados todavía. Añadirlos prematuramente haría que la prueba mínima requiriera configuración que aún no corresponde.

## Cómo reproducir en Windows

Ver [Android](../android/README.md) y [Spring Boot](../server/README.md). Usar un JDK 21 completo y comprobar las versiones efectivas; Java de Gradle y Java del servidor pueden configurarse por separado.

`android/.flutter-version` documenta el SDK; no reemplaza su instalación. El wrapper de Maven descarga la distribución fijada y sus dependencias en el primer uso. Flutter prepara su configuración y wrappers nativos locales al ejecutar sus comandos.

No versionar local.properties, contraseñas, claves, caches, SDK, carpetas build/target, APKs o JARs generados.

## Límites actuales

- No se ejecutó la app en un celular físico ni se comprobó la PC Windows 10.
- El prototipo completo aún no está trasladado a Flutter: la app mínima muestra solo la bienvenida.
- No hay modelos de compra funcionales, ViewModels de negocio ni persistencia local.
- Spring Boot tiene web-application-type=none: no escucha puertos ni implementa los 18 endpoints del contrato.
- No hay conexión con PostgreSQL, QR real, OCR, cámara, sincronización, conflictos o limpieza de datos implementados.
- No se configuró firma de publicación ni distribución de la app.

## Siguiente fase

Trasladar las vistas HTML a Flutter usando datos demo claramente identificados, conservando cámara central, guaraníes, catálogo/gráficos de ejemplo y revisión/estados. Después implementar modelos y reglas y, por separado, persistencia, cámara y red conforme al orden acordado.
