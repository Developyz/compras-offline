# Compras Offline

Aplicación Android de compras con funcionamiento offline-first y sincronización con una PC.

## Estado

Proyecto en etapa de definición. Todavía no hay una aplicación ejecutable.

## Decisiones confirmadas

- Android funcionará sin conexión y sin depender de que la PC esté encendida.
- El celular almacenará temporalmente tickets, canasta y precios.
- El celular conservará los últimos 30 días de compras; la PC mantendrá el historial completo.
- SQLite será la base de datos local de Android y PostgreSQL la de la PC.
- La PC utiliza Windows 10.
- La sincronización será automática cuando vuelva a estar disponible la conexión con el servicio de la PC.

## Propuestas pendientes de validar

- Conservar las compras pendientes de sincronización aunque superen los 30 días. Limpiar el historial local solo tras confirmar su almacenamiento en la PC.
- Primera versión: crear y editar una canasta, registrar productos, cantidades y precios, confirmar y consultar compras, sincronizar y mostrar pendientes y errores.
- Posponer el reconocimiento automático de tickets, las estadísticas avanzadas y las integraciones con supermercados.

## Orden de trabajo

1. Definir el alcance de la primera versión.
2. Definir el flujo de compra y las pantallas.
3. Elegir las tecnologías de Android y del servicio de la PC y definir su conexión.
4. Diseñar los esquemas SQL de SQLite y PostgreSQL.
5. Especificar la cola de sincronización, reintentos, prevención de duplicados, conflictos y contratos de API.
6. Implementar una compra sin conexión y su sincronización con la PC.
7. Validar cortes de conexión, reinicios, errores y recuperación.

## Preguntas abiertas

- ¿Se registrarán productos mientras se compra, al terminar o en ambos momentos?
- ¿Un ticket será el registro de la compra, una foto del comprobante o ambos?
- ¿La PC será accesible solo por la red local o también a distancia?
- ¿Se utilizará un solo celular o varios?

## Estructura prevista

Los componentes se crearán cuando estén definidas sus tecnologías:

- `android/`: aplicación móvil y almacenamiento local.
- `server/`: servicio de API y sincronización para la PC.
- `database/`: migraciones y esquemas SQL.
- `docs/`: arquitectura, contratos y decisiones.

No guardar credenciales, datos reales de compras ni fotos de tickets en el repositorio.
