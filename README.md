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
- La API se implementará dentro de Spring Boot en la PC. Flutter se comunicará con ella mediante HTTP; no accederá directamente a PostgreSQL. REST con JSON es la propuesta de contrato pendiente de especificar.

Ver [arquitectura y stack](docs/arquitectura-y-stack.md) para responsabilidades, decisiones y pendientes.

## Datos y tickets

- El celular conserva los últimos 30 días de compras; la PC mantiene el historial completo. No eliminar compras pendientes de sincronización por antigüedad.
- Registrar fecha, productos, cantidades, precios, descuentos y total, además del comercio y datos de producto disponibles para comparar precios.
- Lectura automática del ticket incluida en el alcance inicial, con revisión antes de confirmar.
- Las capturas desde la app son temporales: se eliminan al confirmar o cancelar, no se guardan en la galería ni se sincronizan.
- Las imágenes que el usuario decida subir y conservar pueden adjuntarse a una compra.

## Estado

Ya están creados los scripts SQL iniciales en [DB](DB/README.md): 13 tablas de negocio, más las tablas técnicas correspondientes a cada motor. Se comprobó el esquema en PostgreSQL 16 y SQLite. Aún no hay app ejecutable, API ni sincronización implementadas.

## Estructura

- `DB/`: scripts iniciales de PostgreSQL y SQLite e instrucciones.
- `docs/`: decisiones y diseño.
- `android/`: ubicación prevista de la aplicación Flutter; todavía no creada.
- `server/`: ubicación prevista del servidor Spring Boot; todavía no creada.

## Documentación

- [Arquitectura y stack](docs/arquitectura-y-stack.md)
- [Registro de tickets e imágenes](docs/registro-de-tickets.md)
- [Objetivo y datos de compras](docs/objetivo-y-datos-de-compras.md)
- [Catálogo de productos](docs/catalogo-de-productos.md)
- [Base de datos](DB/README.md)

## Próximas definiciones

Versiones del stack, librerías complementarias, contratos de API, autenticación y vinculación, conexión local o remota, conflictos de sincronización y política de adjuntos. Las propuestas históricas pendientes en otros documentos deben leerse junto con las decisiones vigentes de arquitectura.

No guardar credenciales, datos reales de compras ni fotos de tickets en el repositorio.
