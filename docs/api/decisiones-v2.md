# API y almacenamiento — decisiones propuestas v2

Estado: especificación de diseño para revisión, sin servicios ni conexiones implementados. `openapi.json` es el contrato estructural de esta revisión y este documento contiene sus reglas semánticas. Juntos precisan los borradores narrativos anteriores; no implican que el usuario haya aprobado cada parámetro técnico.

## Archivos y versión

- `docs/api/openapi.json`: OpenAPI 3.0.3, versión de contrato 0.2.0, rutas bajo `/api/v1`, esquema de almacenamiento 2.
- `DB/migrations/postgresql-v002.sql`: ejecutar una vez después de `DB/postgresql.sql`.
- `DB/migrations/sqlite-v002.sql`: ejecutar una vez después de `DB/sqlite.sql`.
- La API sigue en versión de ruta v1 porque no existe ninguna versión desplegada. `version_esquema=2` es distinto de la revisión de un producto o compra.

No ejecutar las migraciones dos veces ni ejecutar los scripts base sobre una base existente. Una futura herramienta de migraciones automatizará el orden; todavía no se eligió Flyway ni la librería de migración de SQLite.

## Tablas añadidas

PostgreSQL pasa de 16 a **24 tablas**:

| Tabla nueva | Responsabilidad |
| --- | --- |
| configuracion_servidor | Identidad estable y zona comercial de una instalación |
| sesiones_vinculacion | Hash del secreto temporal, consumo y vencimiento del QR |
| solicitudes_vinculacion | Solicitud candidata, autorización y token de consulta protegido |
| credenciales_dispositivo | Hash, expiración y estado de la credencial por dispositivo |
| entregas_vinculacion | Entrega cifrada recuperable durante la vinculación |
| snapshots_sincronizacion | Sesión, ventana, manifiesto y cursor de corte |
| paginas_snapshot | Bytes UTF-8 inmutables y hash de cada página |
| versiones_esquema | Registro de aplicación de v2 |

SQLite pasa de 15 a **21 tablas**:

| Tabla nueva | Responsabilidad |
| --- | --- |
| servidores_confiables | PC vinculada, huella y alias del almacenamiento seguro |
| revisiones_confirmadas | Última revisión remota conocida de cada raíz |
| descargas_snapshot | Progreso persistente y manifiesto de descarga |
| paginas_snapshot_locales | Páginas verificadas antes de instalar |
| conflictos_sincronizacion | Copias local y remota que no se pueden descartar |
| versiones_esquema | Registro de aplicación de v2 |

Los vínculos genéricos entidad/entidad_id se validan en el servicio: no son FK SQL hacia varias tablas. Las FK concretas sí están declaradas. El esquema es para una instalación familiar y una PC activa por base Android; no es multiempresa. No fusionar bases de distintas PC por desactivar una fila de configuración.

## Compatibilidad y ejecución SQL

SQLite reconstruye `compras` para cambiar su DEFAULT de escala a 0, conservando todas sus columnas, registros, claves y los tres índices originales. Desactiva FK antes de abrir la transacción, comprueba relaciones antes del COMMIT y vuelve a activarlas. Ejecutar sin una transacción externa. Si una instrucción falla, detener el gestor, ejecutar ROLLBACK y activar `PRAGMA foreign_keys=ON` antes de seguir. Una futura aplicación deberá hacerlo con manejo de errores y `finally`.

Los scripts v2 **no cambian importes ni convierten monedas**. El SELECT final informa compras PYG existentes con escala distinta de cero; deben revisarse y corregirse mediante una migración de datos específica antes de usarlas con la API PYG. No convertirlas simplemente cambiando un 2 por un 0.

No hay semillas de unidades, servidores, dispositivos o credenciales. Los ejemplos no crean accesos reales. Zona comercial y certificados se configurarán en la PC.

## API: límites y datos

- Cuerpos JSON UTF-8: máximo propuesto de 8 MiB sin comprimir; rechazar 413 sin aplicar nada. No partir una compra en dos operaciones. Los límites por texto y colección están en OpenAPI.
- Como máximo 1000 detalles, 1000 descuentos o 1000 items por agregado. Límites configurables en versiones futuras, no truncamiento silencioso.
- Listas: 50 registros por defecto, máximo 200. Cambios: 100 por defecto, máximo 200. Snapshot: máximo 200 raíces por página y 8 MiB por página; si una raíz no cabe, devolver límite explícito, no una copia parcial.
- Recibos/contexto: máximo 100 IDs iniciales. Periodo de consultas: desde inclusivo/hasta exclusivo; hasta debe ser posterior a desde y el rango máximo propuesto es 366 días. Para un historial más extenso, consultar por tramos. Sin límite temporal en las compras conservadas por PostgreSQL.
- Fechas: UTC con milisegundos y Z; fecha_local se valida como fecha comercial real, sin reescribirla automáticamente por la zona del dispositivo.
- PYG con escala 0. Importes/cantidades/versiones son enteros JSON dentro de int64; rechazar valores fuera de rango. Comprobar desbordamientos en cálculos antes de persistir.
- Los campos adicionales se rechazan. Un campo opcional puede omitirse o ser null solo si el esquema lo permite. Los textos obligatorios se validan también contra espacios en blanco.
- Leer `nullable` conforme a OpenAPI 3.0; no tratar el documento como JSON Schema 2020-12 sin conversión.

## Escrituras y agregados

`Operacion` tiene variantes cerradas por entidad y acción. Crear usa version_base=0; modificar/eliminar exige versión confirmada. Una operación = una transacción de raíz, hijos, recibo y evento. No se escribe SQL con nombres de tabla elegidos libremente por el cliente.

Las raíces son marcas, categorías, unidades, productos, códigos, comercios, sucursales, canastas y compras. Los descuentos y detalles viajan dentro de la compra; los items dentro de la canasta. Actualizaciones guardan el agregado completo; lo omitido se retira lógicamente, no es un PATCH.

OpenAPI separa DTO de escritura de metadatos de lectura. El servidor asigna id/revisión/metadatos de la raíz desde la envoltura y la transacción. IDs de hijos deben ser únicos en todo el agregado y no pertenecer a otra raíz. Las versiones SQL de hijos se mantienen con la revisión de su raíz. Campos del `contexto_historico` se aplanan a las columnas homónimas de detalles_compra; no se almacena como una nueva columna JSON.

El primer contrato exige al menos un detalle incluso para borradores sincronizados; borradores locales vacíos permanecen solo en Android. `canastas.confirmada` y una compra son raíces distintas; no se promete una transacción entre ambas. No confirmar automáticamente la canasta antes de confirmar la compra localmente.

Eliminar una compra equivale a retirarla lógicamente, sin perder auditoría de la PC. Anular es un estado de negocio distinto. Para catálogo referenciado, conservar tombstone y permitir lectura histórica; no admitir nuevas referencias a registros eliminados. Repetir una operación aplicada devuelve su recibo original aun si después se modificó la raíz.

## Idempotencia y hash

El cliente conserva exactamente la operación que llegó a enviar, con su hash e ID. La API calcula el mismo hash sobre una representación canónica definida así:

1. Parsear y validar JSON; rechazar nombres de propiedad duplicados y números no enteros donde se exige entero.
2. Ordenar recursivamente claves por orden de puntos de código Unicode; preservar orden de arrays y contenido de strings sin normalizar Unicode.
3. Serializar sin espacios, enteros en base 10 sin ceros iniciales, -0 como 0, null/true/false en minúsculas; escapar comillas, barra inversa y controles U+0000..001F (estos últimos como `\u00xx` en minúsculas). Los demás caracteres se emiten en UTF-8 sin escape; `/` no se escapa.
4. SHA-256 de esos bytes, en hexadecimal minúsculo. Incluye todos los campos de la operación, no solo datos.

No usar directamente RFC 8785 con conversiones IEEE-754 para enteros int64 grandes. Se necesitan vectores de conformidad entre Dart y Java antes de implementar.

Un mismo ID + otro contenido/dispositivo = 409. Una solicitud en vuelo no se modifica. Cada raíz mantiene una sola operación en vuelo; cambios posteriores esperan su recibo. Reintentos de infraestructura no crean otro ID. No expirar recibos de dispositivos activos sin protocolo adicional.

## Reglas de compra y revisión

El servidor recalcula resúmenes en enteros y verifica las igualdades del contrato; una discrepancia devuelve 422 con campo y motivo, sin modificar importes silenciosamente. Descuentos positivos y no superiores al importe al que se aplican. Una sucursal debe corresponder al comercio y un descuento al detalle de esa compra.

`ajuste_menor` distinto de cero exige observaciones no vacías con justificación. La compra confirmada requiere total_ticket_menor no null e igual a total_calculado_menor. Para carga manual, el usuario revisa y confirma ese total. Borradores pueden conservar la diferencia para revisión.

El importe bruto leído se conserva, aunque difiera de cantidad × precio unitario por redondeo/promoción. Si el usuario pide calcularlo desde cantidad/precio, usar decimal exacto y HALF_UP al guaraní; no recalcular un importe leído sin revisión. Las devoluciones y totales negativos siguen fuera de alcance.

## Historia de producto y normalización

Cada nuevo detalle incluye contexto_historico. Guarda nombre/presentación y, cuando se conozcan, contenido y factores de unidad utilizados al registrar. Los datos desconocidos son null. Cuando hay contenido, exigir contenido, símbolo, dimensión y factor positivos coherentes como grupo. Cuando se conoce la unidad de cantidad, exigir dimensión y factor como par.

La migración deja los nuevos campos en null en filas anteriores. No copiarlos del catálogo actual como si se conociera el estado de la compra antigua. La lectura de legado devuelve el objeto con null y deshabilita conversiones no demostrables. El nombre original del ticket siempre se conserva.

La normalización usa el **precio unitario antes de descuentos**, nunca el total del renglón o descuentos generales distribuidos. Ejemplos: paquete de 500 g a 1800 → 3600 PYG/kg; venta por kg a 2200 → 2200 PYG/kg. Para unidades de masa/volumen, convertir a g/ml mediante el factor histórico; para envases usar su contenido neto histórico. No combinar dimensiones.

`precio_normalizado_pyg` es una **cadena decimal con seis decimales**, calculada con decimal exacto y HALF_UP a seis posiciones; no es un importe cobrado ni una columna monetaria entera. Ejemplo: `3600.000000`. Puede mostrarse redondeada con una indicación apropiada en la UI. `base=registrada` devuelve este campo null y motivo null: se utiliza precio_unitario_menor. Para kg/l incompatible o desconocido, valor null y motivo explícito.

Actualizar el catálogo no reescribe snapshots históricos. Una corrección explícita de una compra puede modificar su contexto solo tras revisión y contra su versión vigente; nunca como efecto lateral de editar un producto.

## Listas, contexto e informes

Cursor de listas opaco, ligado a filtros y orden, con propuesta de expiración a 15 minutos. Al vencer, 410; volver a la primera página. Orden por fecha+ID en compras/precios y nombre+ID en productos. La paginación normal no promete una vista congelada si cambian los datos durante el recorrido; snapshots sí.

`/catalogo/contexto` devuelve raíces autorizadas y su cierre de referencias, incluyendo tombstones históricos. Puede paginar; el cliente mantiene las mismas raíces con el cursor. `no_encontrados` se evalúa sobre las raíces solicitadas, no autoriza omitir FK que sí deben existir. No instalar parcialmente datos con referencias rotas; si el contexto cambió, reintentar la reconciliación sin avanzar cursor. No garantiza consistencia transversal entre páginas: comprobar revisiones al aplicar y recuperar faltantes antes de confirmar.

Las consultas normales de compras/precios/resumen excluyen borradores, anuladas y eliminadas; la consulta por ID/contexto puede devolverlos para sincronización. Productos del catálogo normal excluyen eliminados. Si no hay observaciones válidas, ultimo_precio=null.

Resumen mensual: suma total_calculado_menor confirmado en la PC por fecha_local. No suma canastas ni pendientes del celular. La pantalla debe indicar fuente y periodo, sin etiquetar una ventana parcial como mes completo.

## QR, credenciales y administración

Propuesta de parámetros: QR disponible 5 minutos; solicitud candidata espera aprobación como máximo 5 minutos desde su creación. Al aprobar, empieza una ventana de entrega de 2 minutos, comunicada en expira_en. La expiración no confirmada revoca la credencial provisional.

Secretos y tokens opacos: al menos 32 bytes criptográficamente aleatorios codificados base64url sin padding. Hashes SHA-256, comparación en tiempo constante, límites por origen/sesión, sin secretos en URL/logs. La vigencia propuesta de credencial activa es 90 días; al vencer se vuelve a vincular conservando pendientes. La renovación silenciosa queda fuera de esta versión.

`token_consulta_cifrado` permite devolver el mismo token tras un reintento idéntico de la solicitud. `entrega_cifrada` permite recuperar la misma credencial provisional. Son sobres AEAD versionados con nonce/tag/key_id; clave fuera de BD y Git. El servicio debe borrar el material temporal cuando ya no sea necesario. Los hashes persistentes no reemplazan la entrega cifrada.

Solo `/estado` y los dos pasos de vinculación con secreto/token temporal no requieren Bearer. Una credencial provisional puede llamar exclusivamente a confirmaciones; credenciales activas requieren dispositivo no revocado y no vencido. Confirmar de nuevo es idempotente. Aprobar para un dispositivo existente requiere acción administrativa explícita; no reemplazar identidades por coincidencia de nombre o UUID enviado.

El canal de administración local de la PC —crear QR, autorizar, rechazar, revocar— todavía no tiene interfaz ni contrato público; no se expone mediante esta API móvil. TLS con huella del QR sigue requiriendo implementación y pruebas específicas en Flutter/Spring Boot.

## Snapshot, retención y conflictos

Manifiesto de almacenamiento v2. Páginas numeradas desde 1, al menos una aunque esté vacía. Hash de los bytes originales UTF-8 de cada página, **antes de parsear**, cotejado con hashes_paginas del manifiesto recibido por el canal autenticado. No volver a serializar para comprobar el hash. Publicar solo cuando conteos, páginas y continuidad del log están completos.

El TTL propuesto de snapshot es 24 horas. Preparando devuelve 202; listo 200; sesión vencida 410. Error de preparación devuelve 503 con código SNAPSHOT_FALLIDO. `paginas_snapshot` materializa bytes, no consultas cambiantes. El recolector no borra cambios posteriores al corte necesarios para sesiones vigentes. Mantener el orden de commit del log sigue siendo responsabilidad del servicio.

Android guarda bytes y progreso en staging; al verificarlos puede instalar, conservando pendientes bajo la misma transacción que el cursor. Un conflicto guarda copia local y remota completas y bloquea limpieza. Un nuevo evento de esa raíz actualiza la copia remota/version a la más reciente sin perder la edición local ni crear otro conflicto pendiente paralelo. No rebasa silenciosamente version_base.

La política inicial consume todos los eventos autorizados posteriores al cursor; conserva en SQLite las compras dentro de ventana o protegidas. Los cambios antiguos pueden consumirse sin guardar historial antiguo. Deben obtenerse y validarse dependencias antes de avanzar el cursor. Un reinicio conserva staging, cola, cursor y conflictos.

Retención propuesta del log: mínimo 90 días, extendida por snapshots activos; cursor vencido exige nuevo snapshot. Retención de compras en la PC: completa. Retención local: 30 días calendario incluyendo hoy, con excepción de pendientes, errores, conflictos, borradores y referencias necesarias. No eliminar adjuntos voluntarios hasta definir su política de copia.

`estado_sincronizacion` de v1 conserva el cursor; el servicio valida que servidor_id exista en servidores_confiables. No inferir confirmación por version=1 o último contacto. Filas de cola legadas con servidor_id/hash null no se envían hasta reconstruir asociación y payload de forma explícita. Un envío ya intentado no puede reescribirse para reconstruir el hash.

## Límites pendientes antes de conectar dispositivos

- Validar estas propuestas con el usuario y completar el diseño visual de autorización y resolución de conflictos.
- Elegir versiones y librerías, probar TLS/pinning, Keystore y canonicalización en ambos lenguajes.
- Diseñar el contrato de subida voluntaria de imágenes (tamaño, integridad, reanudación, retención). Este OpenAPI solo transporta metadatos; no declara cargas de archivos listas.
- Implementar validaciones semánticas, autorización, transacciones, limpieza, pruebas de fallos y recuperación; los scripts no hacen esas tareas.
- Preparar migraciones posteriores si cambian los contratos y gestionar backups de PostgreSQL.

El protocolo está formalizado como propuesta de datos y rutas; no se considera una aplicación terminada ni una sincronización verificada entre equipos reales.
