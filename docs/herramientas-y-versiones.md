# Herramientas y versiones — propuesta para preparación

**Actualización de ejecución:** las bases mínimas ya se generaron y se prepararon Flutter 3.47.5 / Dart 3.13.4, JDK Temurin 21.0.13+9 y Maven 3.10.0 en el entorno Linux temporal. Ver [resultados](validacion-proyectos-base.md). La lista completa de plugins de este documento sigue siendo candidata y no se añadió a la base todavía. La PC Windows permanece sin comprobar.


## Estado

Se conserva el stack confirmado: Flutter/Dart/SQLite en Android y Java/Spring Boot/PostgreSQL en la PC Windows 10. Esta revisión propone las librerías y versiones concretas que faltaban. No instala herramientas en el equipo del usuario, no genera proyectos y no implementa conexiones.

Hay dos niveles distintos: **publicación y requisitos consultados** frente a **compatibilidad del conjunto probada compilando**. Se completó el primero; el segundo sigue pendiente. Las versiones listadas son candidatas, no un lockfile ni una garantía de que todos los plugins funcionen juntos.

## Base propuesta

| Componente | Elección candidata | Motivo y comprobación pendiente |
| --- | --- | --- |
| Flutter | 3.47.5, canal stable | Versión presente en la guía oficial; comprobar archivo y hash al instalar |
| Dart | El incluido en ese SDK Flutter | No instalar otro Dart; registrar versión exacta y verificar >=3.12.0 <4.0.0 para estos plugins |
| Java | Eclipse Temurin 21 LTS, x64 | Elegir parche 21.x de seguridad vigente al instalar; registrar número exacto |
| Spring Boot | 4.1.2 | Documentación y POM publicados; compatible documentalmente con Java 21 |
| Constructor servidor | Maven 3.10.0 mediante Wrapper | Versión estable documentada; no usar Maven 4 RC |
| PostgreSQL | 16.15 como candidato inicial | Mantiene la línea 16 usada en los ensayos SQL; verificar binario e instalación Windows |
| Android mínimo | API 24 (Android 7.0), propuesto | Sujetarlo al requisito mayor de los plugins y al Android real del usuario |
| SDK de compilación/target | Por cerrar al generar | Usar plantilla de Flutter y requisitos nativos vigentes; no confundir con Android mínimo |
| Editor | VS Code con extensiones Dart/Flutter | Versión estable vigente al instalar; Android Studio para SDK y dispositivos |

La página de requisitos de [Spring Boot](https://docs.spring.io/spring-boot/system-requirements.html) permite Java 21 y Maven 3.x. El [manual Flutter](https://docs.flutter.dev/install/manual) contiene la versión candidata del SDK. El Dart exacto no quedó verificado mediante metadatos de descarga: no inventarlo.

[Apache Maven](https://maven.apache.org/download.cgi) documenta 3.10.0 como estable. [Adoptium](https://adoptium.net/temurin/releases/?version=21&os=windows&arch=x64) publica JDK 21 LTS. [PostgreSQL](https://www.postgresql.org/download/windows/) ofrece instaladores Windows; su matriz de pruebas enumera principalmente Windows Server, por lo que falta comprobar la instalación concreta en Windows 10.

## Flutter: librerías propuestas

| Paquete | Versión candidata | Responsabilidad |
| --- | --- | --- |
| `flutter_riverpod` | 3.5.0 | Estado de pantallas y composición de dependencias |
| `drift` | 2.35.3 | SQLite tipado, consultas reactivas y transacciones |
| `sqlite3` | 3.9.1 | Motor SQLite nativo para Drift; no es su número de versión SQL |
| `dio` | 5.11.1 | Cliente HTTP, cancelación y tratamiento de errores |
| `camera` | 0.12.2 | Captura temporal del ticket |
| `google_mlkit_text_recognition` | 1.0.1 | OCR local; comprobar que el modelo latino esté incluido |
| `mobile_scanner` | 7.5.0 | QR de vinculación y códigos de barras; usar modelo incluido |
| `flutter_secure_storage` | 11.2.0 | Credenciales protegidas por Android |
| `workmanager` | 0.10.10 | Tareas diferibles; no garantiza sincronización inmediata |
| `fl_chart` | 1.3.0 | Gráficos de evolución de precios |
| `uuid` | 4.6.0 | Identificadores creados offline |
| `crypto` | 3.0.8 | SHA-256 de operaciones y páginas |
| `path_provider` | 2.1.6 | Directorios privados/temporales |
| `path` | 1.9.1 | Construcción de rutas locales |
| `intl` | 0.20.3 | Formato PYG sin decimales y fechas |
| `json_annotation` | 4.12.0 | DTOs JSON anotados |
| `drift_dev` | 2.35.2 | Generación de consultas/modelos SQLite |
| `build_runner` | 2.17.1 | Generación de archivos Dart |
| `json_serializable` | 6.15.2 | Generación de DTOs JSON |

Fuentes de versión y restricciones SDK: API oficial de [pub.dev](https://pub.dev/help/api), con enlace específico por paquete en [versiones-candidatas.json](toolchain/versiones-candidatas.json). Se inspeccionaron además las páginas de [Riverpod](https://pub.dev/packages/flutter_riverpod), [Drift](https://pub.dev/packages/drift) y [Workmanager](https://pub.dev/packages/workmanager).

Riverpod no cambia MVVM: el ViewModel coordina el estado y recibe servicios/repositorios por inyección. Para empezar, usar sus APIs sin generador adicional de Riverpod. Navegación mediante Navigator/Router de Flutter, sin añadir otra dependencia de rutas de entrada.

Drift utiliza SQLite; no reemplaza la base por otro motor ni sincroniza automáticamente. La propuesta abre SQLite nativo con drift + sqlite3 + path_provider/path. No se añaden sqlite3_flutter_libs ni una segunda implementación SQLite. Sus assets nativos y ABI deben probarse al compilar. El número del paquete sqlite3 no es la versión del motor SQL: verificar el motor incorporado en el binario final.

Generadores drift_dev/json_serializable/build_runner solo en dev_dependencies. Se registrarán versiones resueltas y transitivas en pubspec.lock al ejecutar el solver. No crear un lockfile a mano a partir de esta tabla.

## Cámara, OCR y escáner sin internet

- camera: capturar en almacenamiento privado temporal, fuera de la galería; eliminar al confirmar/cancelar y limpiar abandonadas con cuidado.
- google_mlkit_text_recognition: wrapper comunitario de ML Kit, no un SDK Flutter mantenido por Google. Devuelve texto y posiciones; **la interpretación de productos, cantidades, precios y descuentos requiere código y revisión propios**.
- Elegir el modelo latino incluido en la app. La documentación [ML Kit Android](https://developers.google.com/ml-kit/vision/text-recognition/v2/android) distingue el modelo incorporado de la descarga dinámica: necesitamos disponibilidad desde el primer uso offline.
- mobile_scanner: QR y códigos de barras con modelo incorporado, según su [configuración Android](https://pub.dev/packages/mobile_scanner). No activar useUnbundled=true.
- No abrir a la vez camera y mobile_scanner: soltar la cámara al cambiar de flujo. Ninguno registra imágenes permanentes por defecto de nuestra aplicación.
- Capturar un ticket no exige enviar la foto al servidor; OCR local no significa que la lectura sea perfecta.

La selección de imágenes existentes y el contrato de adjuntos voluntarios quedan para cuando se cierre su transferencia y retención. No introducir image_picker/file_picker ni subir capturas temporales como atajo.

## Red local, tareas y credenciales

Dio será el cliente HTTP. La validación TLS y la huella confiada deben implementarse y probarse; instalar Dio no las configura automáticamente. No aceptar todos los certificados para resolver un error local.

flutter_secure_storage guarda la credencial mediante mecanismos seguros de Android; SQLite conserva solo su alias. Workmanager permite tareas diferibles, no un servicio siempre activo. Mantener también sincronización al abrir/reanudar la app y una acción manual.

No bloquear la sincronización por no poder hacer una prueba de internet: la condición real es alcanzar la API de la PC en la LAN. Comprobar en la versión elegida cómo se comportan las restricciones de red de WorkManager cuando el Wi-Fi no tiene salida a internet; no asumir que una red “validada” por Android es requisito de la app. Permisos de red local dependen de la versión Android y target elegido.

## Servidor: acceso a datos y dependencias

Propuesta: **Spring JDBC con JdbcClient**, repositorios propios y transacciones Spring; **Flyway** para migraciones; Maven para construir. Se elige SQL explícito porque ya tenemos esquemas, recibos y snapshots que necesitan control transaccional. No añadir JPA/Hibernate en paralelo; nunca estuvieron confirmados.

La interfaz Repository sigue existiendo aunque no usemos Spring Data JPA. Ver [JDBC en Spring](https://docs.spring.io/spring-framework/reference/data-access/jdbc/core.html).

Componentes a incorporar por fase: Spring MVC, Validation, Security, JDBC, driver PostgreSQL y Flyway con soporte PostgreSQL. Spring Boot gestionará versiones transitivas mediante su BOM, sin mezclar versiones manuales de Spring, Jackson o Security. Para tests, starter de pruebas y JUnit de la misma plataforma. No suponer JUnit 5 o Jackson 2 copiando ejemplos antiguos de Spring Boot 3.

POM/BOM 4.1.2 consultados en Maven Central: Flyway 12.4.0, driver PostgreSQL 42.7.14, Jackson 3.1.7 y Spring Security 7.1.2. Son versiones observadas en esa plataforma, no dependencias instaladas. Registrar el árbol resuelto al crear el proyecto.

La [guía de inicialización Spring Boot](https://docs.spring.io/spring-boot/how-to/data-initialization.html) recomienda un mecanismo de esquema. Usaremos Flyway cuando se adapte el SQL: no ejecutar simultáneamente schema.sql, los scripts manuales y migraciones automáticas. No copiar BEGIN/COMMIT ni baselines sin adaptar y ensayar tanto base nueva como base v2 existente.

## Preparación de Windows 10

La [documentación de Android Studio](https://developer.android.com/studio/install) contempla Windows 10 de 64 bits y distingue memoria para IDE solo o con emulador. Esos requisitos no prueban que el equipo concreto esté listo.

Propuesta de trabajo: celular físico por USB, VS Code para Flutter y SDK administrado con Android Studio. Android Studio puede estar instalado sin tener que mantenerlo abierto al editar. No se necesita Visual Studio C++ por el solo hecho de desarrollar una app Android; no estamos compilando un cliente Flutter de escritorio Windows.

Para el servidor, JDK 21 seleccionado mediante JAVA_HOME. Flutter/Gradle puede usar el JDK incluido con Android Studio si es compatible con su plantilla: registrar ambas rutas, sin forzar a ciegas un único Java para todas las herramientas.

Faltan RAM, arquitectura/CPU, espacio libre, compilación exacta de Windows y versión Android del celular. Se pidió esa información al usuario; si no está disponible, sigue pendiente. No instalar versiones antiguas sin soporte para eludir requisitos ni modificar el equipo durante esta etapa.

## Qué se verificó

- Requisitos y páginas oficiales de Flutter, Android Studio, Spring Boot, Maven y PostgreSQL.
- Disponibilidad del POM/BOM Spring Boot 4.1.2 y versiones publicadas/requisitos SDK de los paquetes listados.
- Restricciones directas compartidas de generadores: no sustituyen la resolución transitiva.

No se ejecutaron flutter pub get, flutter analyze, compilación APK ni Maven: Flutter/Dart/Maven no están disponibles en este entorno y esta etapa no genera proyectos. La consulta de metadatos del archivo Flutter Windows devolvió 404 y la de binarios Adoptium 403; se conservan esas limitaciones en el registro. No presentar el equipo Windows como comprobado ni los archivos binarios como descargados.

## Siguiente paso

Completar el [chequeo de preparación](preparacion-windows.md) y generar los proyectos mínimos cuando pasemos a implementación. Primero resolver dependencias y compilar sin bases ni cámara; después trasladar las pantallas con datos demo. Si un candidato no resuelve, ajustar la matriz y registrar el motivo antes de fijar lockfiles.
