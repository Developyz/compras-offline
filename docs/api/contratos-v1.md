# API v1 — operaciones y contratos propuestos

Estado: borrador de diseño para revisión. No hay API ejecutable, controladores, conexiones ni autenticación implementados. Las rutas y reglas de este documento son propuestas; no sustituyen una confirmación del alcance por parte del usuario.

## 1. Ubicación y propósito

Spring Boot en la PC expone la API; Flutter la consume mediante un cliente HTTP separado de las vistas y modelos. Solo el servidor accede a PostgreSQL. La app guarda y consulta su trabajo cotidiano en SQLite y puede funcionar con la PC apagada.

Base lógica: /api/v1. Conexión confirmada: únicamente dentro de la misma red local Wi-Fi. La PC también puede estar conectada por Ethernet al mismo router si ambos equipos tienen comunicación local. No se contempla acceso remoto, servidor público ni apertura de puertos del router hacia internet. La dirección local, puerto y certificados se definirán al configurar la PC. No se fija localhost como dirección del celular: allí localhost sería el propio teléfono.

API de estilo REST con cuerpos JSON UTF-8. La autenticación será obligatoria en operaciones de datos; no exponer información familiar ni permitir escrituras solo por conocer la URL. Propuesta de cabecera: Authorization: Bearer <credencial-del-dispositivo>. Vinculación, emisión, renovación, revocación y transporte seguro están pendientes de diseñar. No guardar credenciales en GitHub.

## 2. Convenciones del contrato

- Nombres en snake_case, alineados con los scripts SQL.
- IDs UUID generados antes de guardar en Android. Los códigos de barras son texto, conservando ceros iniciales.
- Moneda inicial: PYG. decimales_moneda=0. Un importe 6400 significa ₲ 6.400, no ₲ 64. No enviar símbolos o separadores en números JSON.
- Cantidades en milésimas: 1000 equivale a 1 unidad, 2000 a 2 unidades. La unidad se identifica aparte.
- Fecha/hora UTC: YYYY-MM-DDTHH:mm:ss.SSSZ. fecha_local: YYYY-MM-DD según la fecha comercial de la compra, independiente de convertir a UTC.
- Importes y cantidades: enteros de 64 bits; no usar float/double para dinero. JSON expresa estos números como enteros; los clientes deben decodificarlos sin pérdida.
- Campos obligatorios ausentes, campos desconocidos y tipos incorrectos se rechazan. Un UUID opcional desconocido no se convierte silenciosamente en null.
- created/updated no se deciden con el reloj del cliente para resolver conflictos: el servidor asigna creado_en, actualizado_en y version al aceptar. fecha_compra conserva el instante informado por el usuario.
- Borrado de negocio mediante tombstone eliminado_en; limpiar el caché local no envía una eliminación al servidor.

## 3. Mapa de operaciones

Todas las rutas siguientes se prefijan con /api/v1.

| Método | Ruta | Función | Respuesta correcta |
| --- | --- | --- | --- |
| GET | /estado | Comprobar servicio y versión de protocolo, sin datos privados | 200 |
| POST | /sincronizacion/operaciones | Enviar una operación local pendiente | 201 nueva; 200 repetición idéntica |
| GET | /sincronizacion/cambios?desde=0&limite=100 | Recibir cambios posteriores a un cursor | 200 |
| GET | /compras?desde=2026-11-01&hasta=2026-12-01&limite=50 | Consultar compras en la PC | 200 |
| GET | /compras/{id} | Consultar una compra y sus detalles/descuentos | 200 |
| GET | /productos?buscar=arroz&limite=50 | Consultar catálogo en la PC | 200 |
| GET | /productos/{id}/precios?desde=2026-11-01&hasta=2026-12-01&base=registrada&limite=50 | Consultar observaciones para el gráfico | 200 |
| GET | /resumen-gastos?desde=2026-11-01&hasta=2026-12-01 | Obtener gasto real de un período completo en la PC | 200 |

No se propone un endpoint para subir la captura temporal: el OCR se prevé local y la imagen temporal no entra en la sincronización. Las imágenes voluntariamente adjuntas necesitan un contrato de archivos separado, todavía pendiente.

No se duplican escrituras mediante POST /compras y otra ruta de sincronización: en esta propuesta todas las escrituras móviles usan operaciones identificadas. Las consultas GET son opcionales cuando la PC está disponible y no reemplazan las lecturas locales cotidianas.

## 4. Enviar una operación

Propuesta de solicitud a POST /sincronizacion/operaciones:

```json
{
  "operacion_id": "00000000-0000-4000-8000-000000000101",
  "dispositivo_id": "00000000-0000-4000-8000-000000000102",
  "entidad": "productos",
  "entidad_id": "00000000-0000-4000-8000-000000000103",
  "accion": "guardar",
  "version_base": 0,
  "datos": {
    "nombre": "Arroz integral",
    "marca_id": null,
    "categoria_id": null,
    "presentacion": "Bolsa",
    "contenido_milesimas": 500000,
    "unidad_contenido_id": "00000000-0000-4000-8000-000000000104",
    "tipo_venta": "unidad"
  }
}
```

La unidad referida debe haberse sincronizado previamente. El ID de dispositivo debe coincidir con el dispositivo autenticado. El cliente no elige identidades ajenas.

version_base=0 significa crear. Para actualizar/eliminar se envía la última versión confirmada por la PC, no un contador basado en ediciones locales. La primera versión aceptada es 1; cada cambio aceptado incrementa una revisión. Si el recurso ya existe o su versión no coincide, no sobrescribirlo.

La versión local DEFAULT 1 del esquema no demuestra confirmación del servidor: la cola conserva version_base=0 hasta recibir el recibo de creación. El diseño de modelos debe distinguir versión confirmada de ediciones pendientes.

Propuesta de entidades raíz permitidas inicialmente: marcas, categorias, unidades_medida, productos, codigos_producto, comercios, sucursales, canastas y compras. Es una lista explícita del servicio, nunca nombres SQL arbitrarios del cliente.

### Agregados atómicos

- canastas: datos contiene cabecera e items completos.
- compras: datos contiene cabecera, detalles y descuentos completos.
- items_canasta, detalles_compra y descuentos_compra no se escriben mediante operaciones independientes.
- La versión de la raíz protege todo el agregado; las filas hijas incluidas en el cambio comparten la revisión del agregado. Los IDs de hijos omitidos de una actualización completa se marcan eliminados, no se interpretan como simples parches.
- Una creación/edición se valida y aplica íntegramente en una transacción. No aceptar cabecera sin detalles cuando se confirme una compra.
- Las referencias a productos, unidades, comercios y canastas deben existir, estar activas y pertenecer al ámbito autorizado. Sincronizar dependencias primero.
- Cambiar la compra y cerrar la canasta como una sola operación multirrecurso requiere un contrato adicional; por ahora no asumir atomicidad entre dos raíces.

### Cabecera de compra y campos

Compra: comercio_id y sucursal_id opcionales coherentes, canasta_id opcional, fecha_compra, fecha_local, moneda=PYG, decimales_moneda=0, estado, subtotal_menor, descuento_productos_menor, descuento_general_menor, ajuste_menor, total_ticket_menor, total_calculado_menor y observaciones opcionales.

Cada detalle: id, numero_linea, producto_id opcional, descripcion_ticket, cantidad_milesimas, unidad_cantidad_id, precio_unitario_menor, importe_bruto_menor, descuento_menor e importe_final_menor.

Cada descuento: id, detalle_compra_id opcional, descripcion e importe_menor. El servicio asigna compra_id a hijos y verifica relaciones. Los hijos no incluyen su propia versión base.

Los campos null permitidos corresponden a los opcionales del esquema. La lista exacta de campos obligatorios por estado y los límites de tamaños pasarán a OpenAPI antes de implementar.

### Respuesta de aceptación

```json
{
  "operacion_id": "00000000-0000-4000-8000-000000000101",
  "entidad": "productos",
  "entidad_id": "00000000-0000-4000-8000-000000000103",
  "version": 1,
  "estado": "aplicada",
  "confirmado_en": "2026-11-08T15:30:00.000Z"
}
```

El servidor guarda atómicamente los datos de negocio, el resultado en operaciones_recibidas y el evento de cambios. Solo después de COMMIT responde éxito. El cliente persiste el recibo antes de marcar la cola confirmada.

La respuesta acredita esa revisión concreta. Si hay ediciones locales posteriores, siguen pendientes aunque la creación haya sido confirmada.

### Duplicados y reintentos

- Ante timeout o desconexión, reenviar la misma operacion_id y exactamente el mismo contenido. No generar otro ID.
- Comparar dispositivo autenticado y hash de JSON canónico, con campos ordenados y representación numérica estable. Canonicalización exacta pendiente de fijar en el contrato formal.
- Si ya se aplicó, devolver el mismo recibo almacenado con 200. No incrementar versiones ni repetir efectos.
- Si se reutiliza el ID con distinto contenido, devolver 409 OPERACION_REUTILIZADA.
- Un error de validación no confirma ni consume el ID. Corregir el contenido crea una operación nueva; conservar el registro local del error.
- Mantener como máximo una operación en vuelo por raíz. Las ediciones posteriores esperan el recibo y una nueva version_base, con otro operacion_id. No modificar un payload ya enviado.
- Reintentar fallas de transporte, 408, 429 y fallas transitorias 5xx con espera exponencial y variación aleatoria. Respetar Retry-After. 401 requiere renovar/vincular; 403, 409 y 422 requieren tratamiento específico.
- El servidor debe serializar y deduplicar solicitudes concurrentes del mismo ID dentro de la transacción; una restricción UNIQUE por sí sola no es toda la lógica.

## 5. Conflictos y errores

Estructura común propuesta:

```json
{
  "error": {
    "codigo": "VERSION_CONFLICTO",
    "mensaje": "La compra cambió en otro dispositivo.",
    "reintentable": false,
    "campos": [],
    "version_actual": 4
  },
  "solicitud_id": "00000000-0000-4000-8000-000000000105"
}
```

| HTTP | Código orientativo | Tratamiento |
| --- | --- | --- |
| 400 | SOLICITUD_INVALIDA | JSON, parámetros o tipos incorrectos |
| 401 | NO_AUTENTICADO | Vincular/renovar credencial; conservar pendientes |
| 403 | ACCESO_DENEGADO | No repetir automáticamente |
| 404 | RECURSO_NO_ENCONTRADO | Revisar ID o estado |
| 409 | VERSION_CONFLICTO | Conservar edición local y consultar versión vigente |
| 409 | OPERACION_REUTILIZADA | No reenviar otro contenido con el mismo ID |
| 410 | CURSOR_EXPIRADO | Ejecutar recuperación completa consistente |
| 413 | SOLICITUD_DEMASIADO_GRANDE | Dividir por agregados; no partir una compra |
| 422 | DATOS_INCONSISTENTES | Mostrar campos a corregir; no confirmar |
| 429 | LIMITE_TEMPORAL | Respetar Retry-After |
| 503 | SERVICIO_NO_DISPONIBLE | Reintentar después; conservar la compra |

No resolver conflictos con “gana el último reloj”. Mostrar ambas revisiones y permitir elegir o combinar; reenviar la decisión como nueva operación contra la versión vigente. Esa interfaz está pendiente. La API no cambia los precios o totales silenciosamente.

## 6. Recibir cambios

Solicitud: GET /sincronizacion/cambios?desde=120&limite=100.

Propuesta de respuesta:

```json
{
  "cambios": [
    {
      "secuencia": 121,
      "entidad": "productos",
      "entidad_id": "00000000-0000-4000-8000-000000000103",
      "version": 1,
      "accion": "guardar",
      "datos": {
        "id": "00000000-0000-4000-8000-000000000103",
        "nombre": "Arroz integral",
        "marca_id": null,
        "categoria_id": null,
        "presentacion": "Bolsa",
        "contenido_milesimas": 500000,
        "unidad_contenido_id": "00000000-0000-4000-8000-000000000104",
        "tipo_venta": "unidad",
        "version": 1,
        "creado_en": "2026-11-08T15:30:00.000Z",
        "actualizado_en": "2026-11-08T15:30:00.000Z",
        "eliminado_en": null
      }
    }
  ],
  "siguiente_cursor": 121,
  "hay_mas": false
}
```

El ejemplo supone que las dependencias ya se recibieron. Secuencias estrictamente crecientes, con posibles huecos. desde es exclusivo. limite predeterminado 100, rango propuesto 1–200. Cada agregado cuenta como un evento indivisible, no una fila hija.

El servidor debe garantizar orden de publicación compatible con COMMIT mediante la serialización transaccional documentada en DB/README.md. Un IDENTITY no garantiza ese orden por sí solo.

El cliente aplica la página y persiste el cursor en la misma transacción local. Si falla, no avanza. No sobrescribe datos con cambios locales pendientes: conserva la edición y registra el conflicto o posterga la aplicación. La forma de almacenar la copia remota para resolver conflictos exige diseño adicional antes de implementar.

Los eventos eliminar llevan id, version y eliminado_en. Una raíz eliminada se aplica a sus hijos de forma consistente. No se envían archivos temporales.

### Primera sincronización y retención: decisión pendiente

No usar simplemente desde=0 sobre un log truncado. Se necesita un snapshot consistente que incluya catálogo, canastas y compras de la ventana local con sus dependencias, más un cursor de corte; después se reciben cambios posteriores a ese corte.

El contrato de snapshot, sus páginas y expiración aún no está cerrado. Tampoco está cerrado cómo filtrar cambios históricos fuera de 30 días sin romper referencias o perder el avance del cursor. No implementar la limpieza ni el arranque inicial hasta resolverlo. Las operaciones pendientes nunca se eliminan por la ventana temporal.

## 7. Consultas, listas y períodos

- desde inclusivo, hasta exclusivo, fechas YYYY-MM-DD. Noviembre completo se pide desde=2026-11-01 y hasta=2026-12-01.
- Para gastos se utiliza fecha_local. Excluir borradores, anuladas y registros eliminados.
- Listas: limite predeterminado 50, máximo propuesto 200. Respuesta con items, siguiente_cursor nullable y hay_mas. El cursor es opaco y queda ligado a filtros/orden; enviar cursor en páginas posteriores.
- Orden de compras: fecha_compra descendente y UUID como desempate; catálogo: nombre e ID. Orden de observaciones: fecha de compra e ID de detalle.
- Los límites de período y la consistencia entre páginas ante nuevas escrituras se fijarán en OpenAPI. No prometer un snapshot histórico usando paginación normal.
- GET /compras/{id} devuelve cabecera, detalles activos y descuentos activos, incluyendo revisión. No incluye bytes de fotos.
- GET /productos devuelve identidad, presentación y última observación disponible, indicando fecha y comercio; precio desconocido es null, no cero.
- Un catálogo remoto o historial consultado bajo demanda no implica guardar todo en SQLite. Nunca marcar compras antiguas como pendientes solo por consultarlas.

## 8. Gráfico de precios y resumen de gastos

GET /productos/{id}/precios devuelve observaciones reales de detalles confirmados, sin interpolar días no registrados.

Cada observación: detalle_compra_id, compra_id, fecha_compra, fecha_local, comercio_id/nombre, cantidad_milesimas, unidad_cantidad_id, precio_unitario_menor, importe_bruto_menor, descuento_menor, importe_final_menor, moneda y decimales_moneda. El contexto de presentación/contenido se incluye para interpretar la unidad.

Propuesta inicial: base=registrada devuelve el precio unitario guardado antes de descuentos. base=kg o base=l devuelve comparación normalizada solo cuando el contenido o la unidad de venta permiten convertir sin ambigüedad; si no, precio_normalizado_menor es null y se indica motivo. El esquema de precisión y redondeo de precios normalizados debe definirse antes de formalizar esas variantes; no truncarlos a guaraníes silenciosamente.

No repartir descuentos generales entre productos sin una regla confirmada. Comparar misma moneda y unidades compatibles. Distinguir precio unitario de importe de renglón y cantidad de envases de contenido neto.

El historial debe preservar la base usada al comprar. Actualmente detalles_compra no guarda una copia histórica del contenido/presentación: antes de implementar hay que elegir entre hacer inmutables las presentaciones (crear otro producto al cambiar contenido) o agregar snapshots con una migración. No recalcular precios históricos usando una ficha modificada.

GET /resumen-gastos propone responder:

```json
{
  "desde": "2026-11-01",
  "hasta": "2026-12-01",
  "moneda": "PYG",
  "decimales_moneda": 0,
  "total_gastado_menor": 48000,
  "cantidad_compras": 3,
  "fuente": "pc",
  "calculado_en": "2026-11-08T15:30:00.000Z"
}
```

El importe suma total_calculado_menor de compras confirmadas activas; exige revisar diferencias con el ticket antes de confirmar. No incluye canastas estimadas. Este total refleja el estado del servidor en ese momento: no incluye operaciones aún pendientes en el celular.

Un resumen de últimos 30 días no se etiqueta como total mensual. Sin PC y sin resumen local definido, el total histórico mensual puede estar no disponible; no inventarlo. Esta consulta de gastos desarrolla el objetivo ya acordado y no incorpora presupuestos ni categorías nuevas.

## 9. Validación de una compra

Antes de aceptar: al menos un detalle; referencias válidas; moneda PYG/escala 0; cantidades positivas; importes enteros y no negativos; sumas de renglones, descuentos y total coherentes; sucursal y comercio coincidentes.

subtotal = suma de importes brutos.
descuento_productos = suma de descuentos asociados a detalles.
descuento_general = suma de descuentos sin detalle.
total_calculado = subtotal - descuento_productos - descuento_general + ajuste.

Los resúmenes almacenados no son descuentos adicionales. ajuste requiere justificación y no se utiliza para ocultar discrepancias. Diferencias frente a total_ticket deben resolverse en revisión antes de confirmar. La política exacta de redondeo y ajustes está pendiente.

## 10. Diferencias con los scripts y próximos pasos

No se modificó el SQL en esta fase. Los scripts iniciales aún tienen DEFAULT 2 para decimales_moneda de compras: al implementar PYG debe enviarse 0 explícitamente y preparar la migración/corrección de ese valor predeterminado. No multiplicar importes existentes por 100 ni reinterpretarlos sin revisar sus datos.

Antes de pasar a implementación:
1. Revisar y confirmar este mapa de operaciones.
2. Cerrar vinculación/autenticación y configuración del transporte dentro de la red local ya confirmada.
3. Diseñar snapshot inicial, retención, conflictos y almacenamiento de revisiones pendientes.
4. Completar DTOs/esquemas exactos por entidad, límites, validaciones y ejemplos de compra completa en OpenAPI.
5. Definir preservación histórica de presentación y redondeo de normalización.
6. Diseñar carga voluntaria de adjuntos con límites y retención.
7. Elegir librerías y versiones, y solo entonces crear los controladores y clientes reales.

Este documento describe el contrato propuesto; no demuestra conectividad, seguridad implementada, sincronización funcional ni una especificación OpenAPI ya validada.


## Decisión confirmada: conexión local

Solo se sincronizará cuando celular y PC puedan comunicarse dentro de la misma red local. No hace falta que el proveedor de internet esté disponible si la red local funciona. Compartir el nombre de Wi-Fi no garantiza conectividad: redes de invitados o aislamiento de clientes pueden impedirla.

La PC y Spring Boot deben estar encendidos y accesibles. Fuera de esa red, la app sigue con SQLite y conserva los pendientes. La sincronización automática se intentará cuando el sistema operativo permita ejecutarla; no se promete ejecución inmediata con la app cerrada o el teléfono en suspensión.

Propuesta de configuración para revisar al implementar: reserva DHCP para la PC, puerto de API configurable y regla de firewall de Windows limitada a la red privada local. PostgreSQL permanecerá accesible solo para el servidor en la PC; no abrir su puerto al celular. No se configura nada de esto durante la etapa documental.

La vinculación inicial deberá identificar y autorizar el celular. Método confirmado: QR mostrado por la PC. El [diseño de vinculación](vinculacion-qr.md) propone dirección local, identidad verificable del servidor, secreto temporal y autorización explícita en la PC. No incluir credenciales permanentes en el QR. Definir transporte cifrado y validación del servidor sin desactivar comprobaciones TLS. La red local no reemplaza la autorización.


## Vinculación por QR

El usuario confirmó el QR como método de vinculación inicial. Ver [flujo y contratos propuestos](vinculacion-qr.md): solicitud, aprobación local, entrega y confirmación de credencial, revocación y recuperación de dirección. Los detalles técnicos están documentados para revisión; no hay endpoints implementados. Vincular no equivale a sincronizar: el snapshot inicial sigue pendiente.
