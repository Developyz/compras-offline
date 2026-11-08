> Ampliación local SQLite v3: ejecutar `sqlite-v003.sql` después de v2 añade `recibos_guardado_local` (22 tablas SQLite). No cambia PostgreSQL ni el protocolo v2. El adaptador Drift instala v3 en bases nuevas y migra bases Drift v2; no adopta automáticamente bases manuales. Ver [SQLite y cola](../../docs/sqlite-compras-y-cola.md).

# Migraciones de diseño v2

Estas migraciones amplían los scripts iniciales del proyecto. No implementan API, autenticación, sincronización ni limpieza automática.

## Orden de ejecución

| Motor | Base vacía | Base inicial v1 existente |
| --- | --- | --- |
| PostgreSQL 14+ | Ejecutar `DB/postgresql.sql`, luego `DB/migrations/postgresql-v002.sql` | Solo `postgresql-v002.sql` |
| SQLite 3.24+ | Ejecutar `DB/sqlite.sql`, luego `sqlite-v002.sql` y `sqlite-v003.sql` | `sqlite-v002.sql` y luego `sqlite-v003.sql` |

Seleccionar primero la base correcta en el gestor. Ejecutar cada archivo completo una sola vez. No mezclar motores ni volver a ejecutar el script inicial sobre una base existente. Hacer una copia de la base antes de migrarla. Una migración fallida debe detenerse y revertirse: no continuar ignorando errores.

En SQLite, ejecutar sin una transacción abierta: el script cambia temporalmente `foreign_keys` para reconstruir `compras`. En caso de error, ejecutar `ROLLBACK; PRAGMA foreign_keys=ON;` y comprobar `PRAGMA foreign_key_check;`. Al terminar correctamente se reactivan y comprueban las FK. No ejecutar el script dentro de una transacción que abra automáticamente el gestor.

La tabla `versiones_esquema` registra la aplicación de v2. El adaptador Flutter instala un esquema consolidado v3 y migra bases Drift v2; la adopción de bases manuales sigue pendiente. La integración de migraciones en Java también sigue pendiente.

## Resultado

- PostgreSQL: 24 tablas después de v2.
- SQLite: 21 tablas después de v2.
- Ambas: campos de contexto histórico en detalles y DEFAULT 0 para decimales de compras.
- La migración preserva datos existentes, no convierte moneda y deja snapshots históricos desconocidos en NULL.
- El SELECT final señala PYG con escala antigua distinta de cero: requiere revisión manual y una migración de datos específica antes de usar esos registros con la API.

Los scripts iniciales siguen representando v1; por eso instalar solo esos archivos no alcanza para v2.

## Relaciones y responsabilidades

En PC: sesión de QR → solicitud → entrega cifrada/credencial → dispositivo. Snapshot → dispositivo/servidor → páginas. La solicitud contiene un dispositivo candidato que no está autorizado hasta aprobación local.

En Android: servidor confiado → revisiones confirmadas, descargas, conflictos y cola asociada. Descarga → páginas. Solo una PC activa por base; las filas de cola sin servidor asignado no se envían automáticamente.

El servicio debe coordinar estados entre tablas en transacciones. Los estados declarados en CHECK no son una máquina de estados completa ni sustituyen autorización o validaciones de negocio.

Ver [decisiones v2](../../docs/api/decisiones-v2.md), [OpenAPI](../../docs/api/openapi.json) y [ejemplos](../../docs/api/ejemplos-v2.json).
