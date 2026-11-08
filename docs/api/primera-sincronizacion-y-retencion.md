# Primera sincronización y conservación local de 30 días

**Ampliación v2:** ver [contrato OpenAPI](openapi.json), [reglas complementarias](decisiones-v2.md) y [migraciones SQL](../../DB/migrations/README.md). El texto siguiente conserva el razonamiento previo; los campos exactos y parámetros precisados están en esos documentos. Las migraciones ya están escritas y comprobadas; la lógica de servicios sigue sin implementar.


Estado: diseño propuesto para revisión. Se desarrolla la decisión de sincronizar por red local después de vincular por QR. No hay implementación de red, limpieza ni nuevas migraciones SQL en este documento.

## 1. Reglas que no pueden romperse

- La PC conserva el historial completo; 30 días es la ventana de compras del celular.
- Nunca eliminar una compra con operaciones pendientes, en vuelo, con error o conflicto, aunque sea antigua.
- Una respuesta perdida no demuestra que la PC no recibió la compra.
- Descargar datos no crea operaciones de subida. Limpiar caché tampoco crea eliminaciones de negocio.
- La vinculación identifica la PC, pero no acredita que exista una copia sincronizada de cada compra.
- No borrar la base del celular para “empezar de nuevo” ni sustituir datos locales pendientes por una descarga.
- Aplicar datos y actualizar cursor en una misma transacción local.

## 2. Qué significa “30 días”

Propuesta concreta: últimos 30 días calendario de compras, incluyendo hoy, según fecha_local. La PC define una zona horaria comercial configurable y comunica la fecha de referencia; no inferirla de la IP o ubicación del teléfono.

Ejemplo: para hoy=2026-11-08 se conserva desde 2026-10-10 inclusive hasta 2026-11-09 exclusive. Son 30 fechas, no un mes calendario.

La zona comercial del hogar debe elegirse al configurar la PC; no se fija una zona por el idioma ni por la moneda. fecha_compra sigue siendo UTC y fecha_local conserva el día de la compra.

La ventana se aplica a compras confirmadas y anuladas ya sincronizadas. Borradores, canastas abiertas y compras protegidas por pendientes/conflictos no se eliminan por ese plazo. Fechas futuras se señalan para revisión y no se eliminan automáticamente.

La fecha de corte queda congelada durante cada descarga. Si la fecha del celular parece incorrecta o no existe una referencia temporal confiable, posponer la limpieza. No eliminar datos solo porque el reloj avanzó bruscamente.

## 3. Qué recibe inicialmente el celular

Una **copia consistente o snapshot** de la PC con:

- Identidad del servidor y versión del esquema/protocolo.
- Ventana temporal y zona comercial.
- Catálogo completo de productos, marcas, categorías, unidades y códigos, incluyendo referencias necesarias.
- Comercios y sucursales.
- Canastas abiertas y cualquier canasta necesaria para compras o registros protegidos; sus items completos.
- Compras de la ventana y sus detalles, descuentos y metadatos de adjuntos.
- Revisión de cada raíz y un cursor de corte para continuar recibiendo cambios.

Los registros borrados lógicamente que sigan referenciados se incluyen como referencias históricas con eliminado_en. No ofrecerlos como nuevas opciones del catálogo. Resolver recursivamente todas las claves foráneas, no solo las del primer nivel.

Las imágenes no forman parte del snapshot: las capturas temporales nunca se envían; los adjuntos voluntarios requieren su contrato propio antes de transferir archivos o limpiar sus copias locales.

## 4. Flujo inicial

1. Comprobar servidor_id, identidad TLS y autorización del celular.
2. Registrar un estado local **Preparando sincronización**, sin impedir nuevas compras.
3. Conservar la cola y proteger las raíces afectadas y sus dependencias.
4. Consultar recibos de operaciones ya enviadas cuyo resultado sea incierto.
5. Crear y descargar un snapshot por páginas reanudables.
6. Guardar las páginas en un área temporal persistente separada de los datos visibles.
7. Verificar versión, todas las páginas, referencias y conteos del manifiesto.
8. Instalar la copia remota en una transacción, preservando las ediciones locales pendientes.
9. Guardar el cursor de corte en esa misma transacción.
10. Enviar operaciones pendientes en orden de dependencias y continuar por cambios posteriores al cursor.
11. Al quedar todo confirmado y sin conflictos, evaluar la limpieza local.

El usuario sigue trabajando en SQLite mientras se descarga. Justo antes de instalar, se vuelven a leer los pendientes bajo la transacción local: no proteger solo lo que existía al empezar.

Si dos catálogos generados sin conexión tienen el mismo nombre o símbolo pero distintos UUID, no fusionarlos silenciosamente. Proteger los datos y abrir una resolución de identidad antes de aplicar relaciones incompatibles.

## 5. Contrato propuesto de snapshot

Rutas autenticadas bajo /api/v1:

| Método | Ruta | Función |
| --- | --- | --- |
| POST | /sincronizacion/snapshots | Crear o recuperar una sesión mediante solicitud_id |
| GET | /sincronizacion/snapshots/{id} | Obtener manifiesto y estado de preparación |
| GET | /sincronizacion/snapshots/{id}/paginas/{numero} | Descargar una página inmutable |
| POST | /sincronizacion/recibos/consulta | Consultar resultados de IDs de operaciones del dispositivo |

### Crear

Cuerpo: solicitud_id UUID y dias_locales=30. El dispositivo se obtiene de la credencial, no de una identidad arbitraria enviada en el cuerpo.

202 mientras se prepara; 200 al repetir una solicitud existente. El manifiesto solo queda disponible para descarga cuando el estado es listo. Reutilizar solicitud_id con otros parámetros devuelve 409.

Propuesta de manifiesto listo:

```json
{
  "snapshot_id": "00000000-0000-4000-8000-000000000301",
  "servidor_id": "00000000-0000-4000-8000-000000000201",
  "estado": "listo",
  "version_esquema": 1,
  "cursor_corte": 150,
  "fecha_referencia": "2026-11-08",
  "desde_inclusive": "2026-10-10",
  "hasta_exclusive": "2026-11-09",
  "dias_locales": 30,
  "zona_comercial": "<zona-IANA-configurada-en-la-PC>",
  "paginas": 3,
  "creado_en": "2026-11-08T15:30:00.000Z",
  "expira_en": "2026-11-09T15:30:00.000Z"
}
```

El marcador de zona es ilustrativo y se reemplazará por un identificador IANA válido. La duración de 24 horas es una propuesta de sesión, no un requisito de conservación de compras.

### Páginas

Numeración desde 1, orden y contenido inmutables durante la sesión. Una página incluye snapshot_id, numero, total_paginas, conteos y registros agrupados por entidad raíz. Una compra o canasta se transporta completa con sus hijos: no dividir un agregado entre páginas.

Registros de catálogo primero; las dependencias se validan antes de instalar, no se asume que una página aislada sea una base íntegra.

El máximo por página y por agregado se fijará en OpenAPI. Un agregado demasiado grande produce un error explícito de límite; no truncar productos o descuentos. Verificar integridad del paquete por un manifiesto con hashes sobre los bytes UTF-8 materializados y conteos; su estructura exacta se formalizará en OpenAPI.

Repetir GET de la página devuelve los mismos bytes durante la sesión. La sesión pertenece al dispositivo autorizado. No habilitar descarga de snapshots ajenos por adivinar UUID.

### Consistencia del servidor

Materializar datos y cursor_corte desde una misma lectura PostgreSQL REPEATABLE READ, con los escritores publicando datos y log atómicamente y en orden de commit conforme al contrato de cambios.

El contenido debe conservarse en almacenamiento de snapshot después de cerrar esa transacción, no reconstruirse en cada GET usando las tablas actuales. Mientras exista la sesión, proteger del recolector los cambios necesarios desde cursor_corte, coordinando creación/expiración con esa retención.

Antes de marcar el snapshot listo, comprobar que esa continuidad sigue garantizada. Si no puede garantizarse, fallar y crear otro snapshot; no entregar un cursor que ya perdió cambios.

## 6. Reanudación ante cortes

- Página incompleta: descartar solo esa página y volver a pedirla. Nunca avanzar a la siguiente como si estuviera completa.
- Reinicio de Android: recuperar sesión y páginas verificadas desde el área temporal persistente.
- Sesión vencida: 410 SNAPSHOT_EXPIRADO. Descartar el staging de esa sesión y comenzar otro snapshot, manteniendo base visible y cola.
- Error al instalar: rollback; no cambiar el cursor.
- PC apagada: dejar el progreso pausado, continuar con las compras locales y reintentar cuando esté disponible.
- Disco sin espacio: mostrar la situación y detener descarga/instalación. No limpiar pendientes para hacer lugar.

No prometer ejecución inmediata en segundo plano: Android puede aplazar tareas.

## 7. Pendientes y conflictos durante la instalación

Para una raíz local sin cambios pendientes, instalar la revisión remota.

Para una raíz con pendientes:
- Conservar el estado local visible, su cola y su version_base.
- Si la versión remota coincide con la base conocida, mantener la edición local y continuar su envío cuando corresponda.
- Si cambió respecto de la base, guardar una copia remota duradera para resolver conflicto; no sobrescribir.
- Si la raíz no está en el snapshot, no deducir que fue eliminada: puede estar fuera de ventana.
- Para una referencia histórica necesaria, obtener el agregado autorizado por ID y sus dependencias, sin cargarlo como compra reciente ni generar una nueva operación.
- No cambiar version_base automáticamente para hacer que una edición vieja parezca compatible.

La instalación actualiza el cursor solo si puede almacenar también las revisiones remotas en conflicto. Hasta diseñar ese almacenamiento, no implementar el avance sobre eventos conflictivos ni desecharlos.

Una raíz nueva local con version_base=0 sigue pendiente aunque no aparezca en la PC. Su versión local por defecto no implica confirmación remota.

### Recibos

POST /sincronizacion/recibos/consulta recibe una lista de operacion_id (máximo propuesto 100) y devuelve, para ese dispositivo, aplicada con su recibo o sin_recibo.

sin_recibo no demuestra que una solicitud en vuelo no vaya a terminar. Reenviar únicamente el mismo ID y contenido, usando la deduplicación del servidor. Un recibo confirma la revisión de esa operación, no las ediciones posteriores.

Los recibos de dispositivos activos no se purgan con la limpieza de 30 días. Eliminar recibos requiere un protocolo de retiro/reconciliación adicional; por ahora no proponer una caducidad automática que permita repetir efectos.

## 8. Sincronización incremental y compras antiguas

Propuesta inicial de menor complejidad: el log entrega todos los cambios autorizados posteriores al cursor, sin filtrar por fecha en el servidor. No se descarga el historial completo: son cambios posteriores al corte.

El cliente procesa cada evento, aunque decida no conservar su compra por antigüedad:
- Compra dentro de la ventana o protegida: aplicar agregado y dependencias.
- Compra fuera de ventana, sin referencias locales ni pendientes: consumir el evento sin guardarla como historial local.
- Compra que cambia de fecha y entra en ventana: incorporar el agregado completo.
- Compra que sale de ventana: aplicar la revisión y evaluar desalojo seguro.
- Eliminación remota de raíz con cambios locales: conflicto; no borrar la edición.
- Cambios de catálogo: aplicar preservando el contexto histórico y las dependencias.
- Canastas: conservar abiertas y las necesarias para compras o pendientes.

Un evento fuera de ventana se procesa y su cursor se confirma en la misma transacción; no se omite una página entera por contener compras antiguas. El log puede transportar momentáneamente un agregado antiguo que se descarta sin persistir.

Si faltan dependencias, pausar la aplicación y obtenerlas por ID mediante una operación de lectura de contexto que se formalizará en OpenAPI. No avanzar el cursor mientras no se pueda aplicar o almacenar duraderamente el conflicto.

limite cuenta eventos completos. Los huecos de secuencia son válidos. La respuesta debe permitir avanzar sobre eventos consumidos; nunca usar como cursor únicamente el último registro que decidió conservarse.

Si la desconexión excedió la retención del log, devolver 410 CURSOR_EXPIRADO y volver al snapshot conservando pendientes. Propuesta inicial para cambios: mínimo 90 días, ampliado por sesiones activas; el período no limita el historial de PostgreSQL.

## 9. Limpieza segura del celular

Evaluar después de sincronizaciones correctas, con fecha confiable y sin una instalación de snapshot en curso.

Una compra solo es candidata si:
1. Está fuera de la ventana y no tiene fecha futura.
2. Su revisión actual y los datos asociados que corresponda conservar están confirmados por la PC.
3. No hay pendientes, solicitudes en vuelo, errores, conflictos ni ediciones posteriores.
4. No está siendo editada en la interfaz; la transacción vuelve a comprobar su versión.
5. Sus adjuntos voluntarios tienen una política de copia/retención confirmada.
6. No rompe referencias de otras filas conservadas.

En una transacción local, retirar primero referencias dependientes (descuentos, detalles y metadatos permitidos) y después la compra. No insertar operaciones eliminar ni marcar eliminado_en por esta limpieza.

No borrar productos, unidades, marcas, categorías o comercios por tener más de 30 días. La propuesta inicial conserva todo el catálogo para poder identificar productos sin conexión. Canastas y adjuntos no se someten automáticamente al mismo plazo.

Los errores permanentes también protegen compras: informar al usuario para resolverlos, nunca borrar por haber agotado reintentos.

## 10. Informes y gráficos

Los gráficos offline solo usan datos disponibles localmente y deben mostrar el período cubierto. El historial completo y los meses anteriores se consultan en la PC cuando está accesible.

Un total de últimos 30 días no se presenta como total mensual. Si falta parte del mes, mostrar “Datos locales parciales” y no insinuar un total completo. Resúmenes mensuales persistidos quedan para diseño posterior.

## 11. Cambios de almacenamiento pendientes

El esquema actual es una base inicial, no contiene todos los estados de este protocolo. Antes de implementar se requieren migraciones para:
- Sesiones, páginas/manifiestos materializados y retención de snapshots en la PC.
- Sesión/progreso de descarga y staging persistente en SQLite.
- Copia remota de conflictos y revisión confirmada por raíz.
- Protección de pendientes y asociación consistente con servidor_id.
- Contexto histórico de presentación/unidades y política de adjuntos.
- Datos de vinculación/credenciales conforme al documento QR.

No reutilizar ultimo_contacto_en como prueba de sincronización de todas las compras. Tampoco inferirla solo porque una página se descargó o porque una fila tiene version=1.

## 12. Verificaciones previstas

| Caso | Resultado esperado |
| --- | --- |
| Corte a mitad de página | Reanuda esa página sin duplicar ni perder la cola |
| Compra registrada mientras descarga | Se conserva y se envía después |
| Compra pendiente de hace 60 días | Permanece en el celular |
| Compra confirmada antigua sin dependencias | Puede retirarse del caché; permanece en la PC |
| PC modifica datos durante descarga | Snapshot permanece estable; cambios llegan después del corte |
| Cursor vencido | Nuevo snapshot sin borrar pendientes |
| Misma compra cambia en dos dispositivos | Se conservan ambas revisiones para resolver |
| Respuesta de envío perdida | Recibo/reintento con mismo ID evita duplicar |
| Cambio histórico entra en ventana | Se incorpora completo |
| Archivo voluntario sin copia confirmada | No se elimina automáticamente |
| Fecha del celular incorrecta | Se pospone limpieza |
| Reinicio de PC o Android | Progreso y operaciones se recuperan de almacenamiento duradero |

## Estado y próximo paso

Diseño documental: primera carga, reanudación, ventana temporal y limpieza propuestos; no comprobados con dispositivos reales. Los ejemplos JSON y fechas pueden verificarse estructuralmente, pero eso no valida la implementación futura.

El siguiente paso es formalizar las migraciones pendientes y los DTOs/contratos OpenAPI, incluyendo límites de tamaño, lectura por ID de dependencias, paginación, conflictos y adjuntos, antes de implementar servicios.
