# Migraciones SQL

Estado actual: **PostgreSQL v2, 24 tablas**; **SQLite v4, 23 tablas**. V3/v4 son ampliaciones exclusivamente locales para recibos e identidad; no cambian el protocolo ni los snapshots v2.

## Orden de ejecución manual

| Motor y base | Archivos en orden |
| --- | --- |
| PostgreSQL vacía | `DB/postgresql.sql`, `postgresql-v002.sql` |
| PostgreSQL v1 | `postgresql-v002.sql` |
| SQLite vacía | `DB/sqlite.sql`, `sqlite-v002.sql`, `sqlite-v003.sql`, `sqlite-v004.sql` |
| SQLite v1 | `sqlite-v002.sql`, `sqlite-v003.sql`, `sqlite-v004.sql` |
| SQLite v2 | `sqlite-v003.sql`, `sqlite-v004.sql` |
| SQLite v3 | `sqlite-v004.sql` |

Seleccionar la base correcta y ejecutar cada archivo completo una sola vez. No mezclar motores, repetir el script inicial ni continuar después de un error. Conservar una copia antes de migrar datos existentes.

SQLite v002 cambia `foreign_keys` fuera de BEGIN para reconstruir `compras`; ejecutarlo sin otra transacción abierta. Si falla, detenerse, ejecutar `ROLLBACK; PRAGMA foreign_keys=ON;` y comprobar `PRAGMA foreign_key_check;`. No ignorar restricciones fallidas. La migración conserva importes existentes y deja historia desconocida en null; su SELECT final señala PYG con escala antigua para revisión, sin convertirlo silenciosamente.

V003 añade `recibos_guardado_local`. V004 añade `metadatos_locales` para un UUID de instalación no secreto. No contienen tokens ni fotos.

## Ejecutor Flutter

Drift instala un esquema consolidado v4 en bases nuevas y migra bases administradas con `user_version` 2/3 a 4. `android/tool/generar_esquema_sqlite.py` deriva el asset de los SQL oficiales; no ejecuta los scripts con BEGIN/COMMIT dentro de otra transacción.

Una base manual con tablas y sin versión Drift se rechaza sin borrar datos. No marcarla como una versión administrada a ciegas: falta su adaptación/importación explícita. La integración PostgreSQL/Spring Boot sigue pendiente.

`DB/unidades-iniciales.json` define IDs estables compartidos. La sesión Android instala/verifica solo ese catálogo e identidad, sin crear compras de ejemplo. La futura preparación del servidor deberá consumir el mismo manifiesto.

## Responsabilidades preservadas

V2 incorpora vinculación, revisiones, snapshots persistentes y conflictos. El servicio debe coordinar estados y autorización; los CHECK no implementan por sí solos esa lógica. La cola sin servidor asignado no se envía automáticamente. No reasignar compras a otra PC ni eliminar pendientes/conflictos por antigüedad.

Ver [guardado en pantalla](../../docs/guardado-local-en-pantalla.md), [SQLite y cola](../../docs/sqlite-compras-y-cola.md), [decisiones v2](../../docs/api/decisiones-v2.md) y [OpenAPI](../../docs/api/openapi.json).
