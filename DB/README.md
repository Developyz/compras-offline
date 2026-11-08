# Base de datos

El esquema actual tiene **24 tablas PostgreSQL v2 y 23 SQLite v4**. Seguir el [orden completo de migraciones](migrations/README.md): SQLite necesita las ampliaciones v002, v003 y v004 después del script inicial; PostgreSQL necesita v002.

Android ya usa un adaptador Drift/SQLite para compras manuales, cola, recibos e identidad. Ver [flujo implementado](../docs/guardado-local-en-pantalla.md). `unidades-iniciales.json` fija IDs comunes para unidad/kg/L; no generar otros IDs para esas mismas unidades al preparar el servidor.

Las secciones siguientes describen las tablas de negocio del esquema inicial y deben leerse con las migraciones actuales.

## Cómo ejecutar

- **PC / PostgreSQL 14 o posterior:** crear una base vacía, seleccionarla en pgAdmin o el gestor elegido y ejecutar todo `postgresql.sql`.
- **Android / SQLite 3.24 o posterior:** abrir una base vacía y ejecutar todo `sqlite.sql`. Activar `PRAGMA foreign_keys = ON` en **cada conexión**, fuera de una transacción. En Android, habilitar claves foráneas antes de abrir transacciones.
- Son alternativas para dos motores distintos: no ejecutar ambos archivos en la misma base.
- Los scripts usan una transacción, no borran datos y son para instalación inicial. No son scripts para ejecutar repetidamente ni sustituyen futuras migraciones.

## Tablas

Ambas bases contienen las 13 tablas de negocio: marcas, categorias, unidades_medida, productos, codigos_producto, comercios, sucursales, compras, detalles_compra, descuentos_compra, adjuntos_compra, canastas e items_canasta.

PostgreSQL agrega dispositivos, operaciones_recibidas y cambios_sincronizacion: **16 tablas**. SQLite agrega cola_sincronizacion y estado_sincronizacion: **15 tablas**.

Las claves foráneas impiden referencias inexistentes. Además se verifica que una sucursal pertenezca al comercio de la compra y que un descuento por detalle corresponda a la misma compra. No se usan borrados en cascada: las eliminaciones de negocio se representan con eliminado_en y deben sincronizarse.

## Convenciones

- La aplicación genera UUID antes de guardar, incluso sin conexión. PostgreSQL valida el tipo UUID; SQLite lo almacena como texto y la app valida su formato.
- Los campos *_en y fecha_compra son textos ISO 8601 UTC, con formato uniforme `2026-11-08T15:30:00.000Z`, validado por la aplicación. fecha_local es la fecha comercial `YYYY-MM-DD` usada para informes por día y mes.
- Los importes son enteros de 64 bits en la unidad menor de la moneda. La moneda confirmada es PYG: decimales_moneda=0 y 6400 representa ₲ 6.400. La migración v2 cambia el DEFAULT a 0 sin convertir los datos anteriores. Esta elección evita errores de coma flotante en SQLite. La app debe validar moneda ISO 4217 y su escala.
- Cantidades y contenido se almacenan en milésimas: cantidad_milesimas=1000 equivale a 1 unidad; 1250 equivale a 1,250 kg si la unidad es kg. contenido_milesimas=500000 con unidad g representa 500 g. Límite inicial: tres decimales de cantidad.
- unidades_medida.factor_base expresa cuántas unidades base hay en una unidad: g=1, kg=1000, ml=1, l=1000, unidad=1. Solo se comparan unidades de la misma dimensión. Los UUID del catálogo deben compartirse entre PC y celular; no generar catálogos independientes.
- No hay datos de ejemplo ni semillas obligatorias. Antes de registrar cantidades, crear las unidades necesarias desde la app o mediante una migración de catálogo compartida.
- Marca, categoría, identificación del producto y comercio pueden completarse después. Se conserva descripcion_ticket aunque se vincule un producto.

## Totales y descuentos

Cada detalle conserva precio unitario, importe bruto, descuento e importe final. El importe bruto leído puede diferir de cantidad × precio por redondeos o promociones: no se fuerza una igualdad que altere el ticket.

Los descuentos por producto se desglosan en descuentos_compra con detalle_compra_id; los generales llevan ese campo nulo. El descuento del detalle y los acumulados de compras son resúmenes de esos registros, **no descuentos adicionales**.

La aplicación debe validar en una única transacción, al confirmar:

1. Que exista al menos un detalle activo.
2. Que subtotal_menor sea la suma de importes brutos activos.
3. Que cada descuento del detalle coincida con sus descuentos activos.
4. Que descuento_productos_menor y descuento_general_menor coincidan con sus desgloses activos.
5. Que ajuste_menor esté justificado (por ejemplo, redondeo) y revisar diferencias entre total_ticket_menor y total_calculado_menor.

El SQL valida importes no negativos y fórmulas por fila. Las sumas entre tablas, el redondeo, las transiciones de estado y la compatibilidad de unidades deben validarse en el servicio y en Android; no están implementadas como triggers.

## Fotos

adjuntos_compra solo admite imágenes subidas voluntariamente. Guarda metadatos y una referencia lógica, no los bytes ni una ruta absoluta del teléfono. Las capturas temporales para leer tickets no se insertan ni se sincronizan. La política de retención y transferencia de adjuntos está pendiente.

## Sincronización y conservación

Estas tablas preparan el almacenamiento; **el SQL no implementa por sí solo la sincronización**.

- Guardar cambios locales y operaciones de cola atómicamente. datos_json es texto JSON en SQLite, validado por la app.
- Reutilizar operacion_id al reintentar. El servidor comprueba dispositivo y hash para rechazar la reutilización del ID con otro contenido, y conserva el resultado para responder sin duplicar efectos.
- version es una revisión controlada por el protocolo; no se incrementa automáticamente. Resolver conflictos antes de sobrescribir.
- El servidor guarda datos de negocio, recibo y cambio en una misma transacción.
- El cursor secuencia requiere **serializar las transacciones que publican cambios**, por ejemplo con un bloqueo transaccional global antes de asignar la secuencia. IDENTITY solo no garantiza orden de commit: sin esa disciplina un cliente podría saltarse cambios. Mantener el bloqueo hasta COMMIT.
- Las tablas de log usan referencias genéricas entidad/entidad_id porque representan varias tablas; no son claves foráneas. La API debe validar una lista permitida de entidades.
- Borrar físicamente una compra antigua del caché local no es eliminarla del historial: no crear una operación de eliminación por esa limpieza.
- La limpieza de 30 días requiere confirmación de sincronización de la compra y sus dependencias, sin operaciones pendientes ni conflictos. Primero quitar dependencias locales en una transacción. Conservar catálogo necesario, canastas abiertas e historial completo en la PC.
- No hay limpieza automática en estos scripts. La retención de recibos y cambios debe considerar dispositivos desconectados y resincronización completa.
- Vinculación/autenticación, cifrado y contratos API se implementarán aparte; el acceso es exclusivamente por red local. No guardar tokens de autenticación en estas tablas.

## Alcance

Modelo inicial para una instalación familiar. No incluye multiusuario ni aislamiento de varias familias, presupuestos mensuales, devoluciones o documentos con totales negativos. Esas funciones requieren diseño y migraciones posteriores. Los informes completos sin PC necesitan una política de resúmenes adicional, porque el celular conserva solo 30 días de compras.


## Diseño posterior de primera sincronización

Ver [primera sincronización y retención](../docs/api/primera-sincronizacion-y-retencion.md). El documento describe snapshots, staging persistente y revisiones en conflicto que requieren migraciones adicionales: estos scripts iniciales aún no los implementan. La ventana propuesta son 30 días calendario incluyendo hoy, nunca aplicada a compras pendientes o en conflicto. La vinculación ya está definida por QR y la conexión será exclusivamente local, sin acceso remoto.


## Contratos de esta revisión

- [OpenAPI 3.0.3](../docs/api/openapi.json)
- [Decisiones y reglas v2](../docs/api/decisiones-v2.md)
- [Ejemplos JSON](../docs/api/ejemplos-v2.json)

Migraciones comprobadas en PostgreSQL 16 y SQLite, con preservación de datos y restricciones. Estos controles no validan todavía una sincronización real entre dispositivos.
