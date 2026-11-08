# Compras Offline

Aplicación Android para organizar compras, comparar precios y planificar la canasta familiar. Funcionamiento offline-first con sincronización entre el celular y una PC.

## Stack confirmado

| Componente | Tecnología |
| --- | --- |
| Cliente Android | Flutter con Dart |
| Base de datos local | SQLite |
| Servidor y API en la PC | Java con Spring Boot |
| Base de datos del servidor | PostgreSQL |
| Sistema de la PC | Windows 10 |
| Control de versiones | Git y GitHub |

## Arquitectura

- General: offline-first con sincronización cliente-servidor. El celular es el cliente y la PC es el servidor.
- Android: MVVM con repositorios.
- Servidor: controladores → servicios → repositorios → PostgreSQL.
- La API se implementará dentro de Spring Boot en la PC. Flutter se comunicará con ella mediante HTTP; no accederá directamente a PostgreSQL. REST con JSON: el [contrato OpenAPI propuesto](docs/api/openapi.json) y las [reglas v2](docs/api/decisiones-v2.md) formalizan las operaciones para revisión, sin implementación.

Ver [arquitectura y stack](docs/arquitectura-y-stack.md) para responsabilidades, decisiones y pendientes.

## Datos y tickets

- Moneda confirmada: guaraní paraguayo (PYG / ₲), sin decimales. Las migraciones v2 ajustan el valor predeterminado SQL sin convertir importes anteriores.

- El celular conserva los últimos 30 días de compras; la PC mantiene el historial completo. No eliminar compras pendientes de sincronización por antigüedad.
- Registrar fecha, productos, cantidades, precios, descuentos y total, además del comercio y datos de producto disponibles para comparar precios.
- Lectura automática del ticket incluida en el alcance inicial, con revisión antes de confirmar.
- Las capturas desde la app son temporales: se eliminan al confirmar o cancelar, no se guardan en la galería ni se sincronizan.
- Las imágenes que el usuario decida subir y conservar pueden adjuntarse a una compra.

## Estado

Android ya permite registrar una compra manual, revisarla y guardar compra + cola + recibo en SQLite, con historial local y reintentos sin duplicar la operación. Inicio ya muestra gastos mensuales reales, resumen local y últimas compras. Canasta, Productos y Estados conservan su prototipo identificado; la cámara y lectura asistida inicial están implementadas, pendientes de prueba física; la sincronización sigue pendiente. Ver [flujo y captura](docs/guardado-local-en-pantalla.md).

Los scripts [DB](DB/README.md) definen 24 tablas PostgreSQL v2 y 23 tablas SQLite v4. Las migraciones se comprobaron con preservación de datos. Spring Boot mantiene su base mínima sin HTTP ni persistencia; todavía no existe una API en ejecución.

## Estructura

- `DB/`: scripts iniciales de PostgreSQL y SQLite e instrucciones.
- `docs/`: decisiones y diseño, incluyendo el borrador de API en `docs/api/`.
- `prototipo/`: pantallas HTML navegables con datos ficticios y comentarios de implementación pendiente.
- `android/`: prototipo Flutter navegable, pruebas y comentarios de capas pendientes.
- `server/`: proyecto Spring Boot mínimo con Maven Wrapper, pruebas y paquetes pendientes.

## Documentación

- [Arquitectura y stack](docs/arquitectura-y-stack.md)
- [Estructura de carpetas y etapas](docs/estructura-y-etapas.md)
- [Herramientas y versiones candidatas](docs/herramientas-y-versiones.md)
- [Preparación de Windows](docs/preparacion-windows.md)
- [Cámara y lectura asistida inicial](docs/camara-y-lectura-inicial.md)
- [Modo oscuro y captura](docs/modo-oscuro.md)
- [Inicio con gastos reales](docs/inicio-gastos-reales.md)
- [Guardado local en pantalla](docs/guardado-local-en-pantalla.md)
- [SQLite: compras y cola](docs/sqlite-compras-y-cola.md)
- [Repositorios y ViewModel de revisión](docs/repositorios-y-viewmodel-revision.md)
- [Modelos de producto, canasta y compra](docs/modelos-producto-canasta-compra.md)
- [Modelos y reglas de revisión de compras](docs/modelos-y-revision-compra.md)
- [Vistas Flutter y validación visual](docs/vistas-flutter.md)
- [Validación de proyectos mínimos](docs/validacion-proyectos-base.md)
- [Registro de versiones consultadas](docs/toolchain/versiones-candidatas.json)
- [Registro de tickets e imágenes](docs/registro-de-tickets.md)
- [Objetivo y datos de compras](docs/objetivo-y-datos-de-compras.md)
- [Catálogo de productos](docs/catalogo-de-productos.md)
- [Base de datos](DB/README.md)
- [Contratos de API v1 — borrador](docs/api/contratos-v1.md)
- [OpenAPI propuesto](docs/api/openapi.json)
- [Reglas de API y almacenamiento v2](docs/api/decisiones-v2.md)
- [Migraciones SQL v2](DB/migrations/README.md)
- [Prototipo visual Android](prototipo/README.md)

## Próximas definiciones

Revisar el contrato y la matriz de versiones candidatas, completar la preparación del equipo Windows y completar catálogo/canasta y preparar captura/OCR. Después implementar y probar vinculación, TLS y sincronización, y cerrar transferencia/retención de adjuntos. Drift/sqlite3 ya están resueltos y probados para el adaptador local; la matriz completa sigue siendo candidata y no representa compatibilidad conjunta probada de todos sus plugins. La conexión está confirmada exclusivamente por red local y la vinculación por QR. Las propuestas históricas pendientes en otros documentos deben leerse junto con las decisiones vigentes de arquitectura.

No guardar credenciales, datos reales de compras ni fotos de tickets en el repositorio.
