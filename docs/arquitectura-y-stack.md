# Arquitectura y stack confirmados

## Decisiones vigentes

- Cliente: aplicación Android desarrollada con Flutter y Dart.
- Persistencia del cliente: SQLite.
- Servidor: aplicación Java con Spring Boot, ejecutada en la PC con Windows 10.
- Persistencia del servidor: PostgreSQL en la PC.
- Arquitectura general: offline-first con sincronización cliente-servidor. El cliente es el celular y el servidor es la PC.
- Organización de Android: MVVM con repositorios y servicios para reglas de negocio y sincronización.
- Organización del servidor: capas de controladores, servicios y repositorios.
- Control de versiones: Git y GitHub.

Flask, Python, SQLAlchemy y Alembic no forman parte del stack del servidor. Su mención anterior fue un error y queda sustituida por Java con Spring Boot.

## Dónde está la API

La API será una interfaz HTTP implementada dentro del servidor Spring Boot, en la PC. No es una base de datos ni una aplicación externa adicional. Los controladores de Spring Boot expondrán las operaciones que el celular podrá solicitar.

Flujo de una solicitud:

Celular Flutter → HTTP → controladores Spring Boot → servicios de negocio → repositorios → PostgreSQL.

La respuesta vuelve al celular por HTTP. Se propone usar una API REST con mensajes JSON; rutas, formato, autenticación, versionado y contratos aún deben definirse. El celular no se conectará directamente a PostgreSQL.

El servidor Spring Boot será un proceso en ejecución en la PC; no presupone una interfaz gráfica de escritorio. Una eventual interfaz para la PC requiere definir su alcance y tecnología.

## Funcionamiento sin conexión

La app lee y guarda en SQLite. Al registrar una compra, guarda el dato y su operación pendiente en la misma transacción local. El servicio de sincronización envía los pendientes cuando puede alcanzar la API de la PC y recibe los cambios del servidor.

Tener internet no equivale a tener la API disponible: también deben estar encendidos y accesibles la PC y su servicio. No se ha decidido si la conexión será solo por red local o también remota. No se requiere publicar la API en internet para trabajar por red local.

El celular conserva los últimos 30 días de compras y la PC el historial completo. Las compras pendientes de sincronización no deben eliminarse por antigüedad. Las capturas temporales para leer tickets no se sincronizan ni se conservan como adjuntos.

## Responsabilidades

### Android

- Vista: pantallas Flutter e interacción.
- ViewModel: estado de la pantalla y coordinación de acciones.
- Modelos y servicios: datos y reglas de negocio.
- Repositorios: acceso a SQLite.
- Servicio de sincronización y cliente HTTP: intercambio con la API y gestión de pendientes.

### PC

- Controladores: recibir solicitudes y devolver respuestas.
- Servicios: validar compras, coordinar transacciones, resolver sincronización y aplicar reglas.
- Repositorios: acceso a PostgreSQL.

## Estado real de implementación

Los scripts DB/postgresql.sql y DB/sqlite.sql están creados. Se comprobó la ejecución del esquema en PostgreSQL 16 y SQLite, con pruebas adicionales de integridad en SQLite. El modelo contiene 13 tablas de negocio; PostgreSQL agrega 3 de sincronización (16 en total) y SQLite agrega 2 (15 en total).

Esto no significa que exista ya una app ejecutable, una API implementada ni una sincronización funcional. Tampoco se verificó todavía el despliegue del stack en la PC Windows 10 del usuario.

## Pendiente de elegir o especificar

- Versiones de Java, Spring Boot, Flutter y Dart compatibles con el entorno de desarrollo y despliegue.
- Spring Data JPA/Hibernate y Flyway: propuestas, aún no confirmadas.
- Librerías Flutter de SQLite, gestión de estado, HTTP y trabajo en segundo plano.
- Motor OCR para tickets y lector de códigos de barras.
- Contratos de API, autenticación y vinculación de dispositivos, acceso local/remoto y resolución de conflictos.
- Política de adjuntos y disponibilidad de informes históricos con solo 30 días de datos locales.
