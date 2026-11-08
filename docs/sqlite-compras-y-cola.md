# SQLite: compras, cola y recibos locales

Se implementa `ComprasSqlite`, primer adaptador de `RepositorioCompras`, con Drift 2.35.3 y sqlite3 3.9.1. Se prueba con SQLite nativo real, en memoria y en archivo, desde Flutter en Linux. No es una base simulada.

El adaptador todavía **no está conectado al botón de la app**. La revisión mantiene su vista previa sin escritura. Los repositorios de productos/canastas, cámara, OCR, envío a PC y limpieza de datos siguen pendientes. El código no crea compras ficticias al iniciar la aplicación.

## Guardado atómico

`guardarYEncolar` acepta inicialmente compras confirmadas nuevas con versión base 0. En una sola transacción:

1. Busca un recibo persistente de la operación y compara la solicitud completa.
2. Comprueba que no se reutilicen IDs ni se sobrescriba una compra existente.
3. Verifica referencias activas a comercio, sucursal, canasta, productos y unidades; comprueba comercio de la sucursal.
4. Inserta cabecera, detalles, contexto histórico y descuentos, preservando los importes leídos.
5. Inserta la operación pendiente en `cola_sincronizacion`.
6. Inserta el recibo local y confirma la transacción.

Si falla cualquier inserción, se revierten cabecera, hijos, cola y recibo. El recibo se devuelve después del commit; no acredita recepción de la PC.

Los IDs de compra y operación los aporta el futuro coordinador. Un reintento idéntico devuelve el recibo sin duplicar ni reiniciar la fila de cola. Reutilizar el ID con otro contenido/dispositivo falla. Otra operación sobre una compra existente también falla: **ediciones, anulaciones y versiones base mayores a cero aún no se implementan**. La validación rechaza escrituras de borradores.

Los recibos se conservan independientemente de retirar operaciones ya confirmadas; no hay tarea de borrado implementada. Un error de lectura se propaga y no se convierte en null: null solo indica compra ausente o eliminada lógicamente.

## Cola sin PC vinculada

Las filas nuevas quedan `pendiente`, sin `servidor_id` y sin `hash_solicitud`. Esto impide asumir pertenencia a una PC o inventar un envío. Todavía no existe trabajador de sincronización, asignación de servidor ni cálculo del hash de API.

`datos_json` contiene el agregado de compra con enteros JSON exactos y contexto histórico. La solicitud completa guardada en el recibo sirve para comparar reintentos locales. Su orden estable **no implementa ni reemplaza la canonicalización/hash del protocolo v2**. El transporte deberá preparar su sobre final y preservar operaciones en vuelo conforme al contrato.

## Precisión e historia

La conversión BigInt → int se comprueba sin pérdida y exige rango int64. Esta implementación es para Android/VM nativo, no web. Se comprueba el máximo `9223372036854775807` tanto en columnas INTEGER como en JSON y después de leerlo de nuevo.

La lectura reconstruye el dominio desde cabecera e hijos, y verifica sus resúmenes almacenados. Rechaza números no enteros, fechas UTC no canónicas, discrepancias de totales/renglones y moneda incompatible. No corrige datos manuales ni convierte importes anteriores silenciosamente. Editar el catálogo no reescribe el contexto histórico del ticket.

## Esquema y migraciones

- SQLite v3 tiene **22 tablas**: las 21 de v2 y `recibos_guardado_local`.
- PostgreSQL sigue en su esquema v2 de 24 tablas; v3 es una ampliación local.
- `DB/migrations/sqlite-v003.sql` permite añadir recibos a una base manual v2.
- `android/tool/generar_esquema_sqlite.py` ejecuta los SQL oficiales v1→v2→v3 en una SQLite temporal y genera `android/assets/db/esquema_v3.json`. No inventa otro esquema independiente ni toca bases del usuario.
- Drift instala ese asset en bases nuevas, dentro de una transacción. Activa FK y comprueba integridad al abrir.
- La migración de una base administrada por Drift con `user_version=2` añade recibos dentro de una transacción y preserva sus compras y cola. No fabrica recibos para operaciones antiguas.
- Una base manual con `user_version=0` y tablas existentes se rechaza sin borrarlas. V1 y otras migraciones no soportadas requieren adaptación/importación explícita; no se marca una base manual como Drift a ciegas.

La versión local 3 no cambia la versión 2 del protocolo ni de sus snapshots. Los SQL manuales con BEGIN/COMMIT no se ejecutan dentro de las transacciones de Drift; el asset contiene únicamente sus sentencias de esquema ya consolidadas.

Regenerar y revisar el asset cuando cambien los SQL:

```powershell
python android/tool/generar_esquema_sqlite.py
```

Se usa Drift con SQL explícito y sin tablas generadas; `drift_dev` y `build_runner` todavía no son necesarios. No hay consultas reactivas implementadas en esta etapa.

## Apertura y ciclo de vida

`BaseLocal.abrirPrivada()` prepara una conexión en el directorio de soporte de la aplicación mediante path_provider/path. El archivo se abre en un isolate con `NativeDatabase.createInBackground`; la base es propia de la aplicación y no una carpeta pública de fotografías.

La composición de dependencias deberá crear una instancia, conservarla y cerrarla correctamente. La apertura privada mediante plugin y el binario Android aún requieren prueba en dispositivo. Los tests de archivo aportan una ruta temporal real y verifican cierre/reapertura; no simulan path_provider.

No se implementa retención de 30 días: no se borra ninguna compra por antigüedad. Antes de añadirla se debe preservar todo pendiente o conflicto y verificar confirmación remota. No se almacena ni se transmite ninguna foto.

## Validación

- 18 pruebas nuevas de datos con SQLite real: esquema/FK, lectura completa, fallos en cuatro etapas de inserción, rollback, reintentos, identidad de solicitudes, ausencia/errores, referencias, int64, historia, archivo, migración, protección de base manual, fallo de creación y concurrencia.
- `flutter test`: **69 pruebas aprobadas** (51 anteriores + 18 nuevas).
- `flutter analyze`: sin observaciones.
- `flutter build bundle --debug`: compilación Dart aprobada; no equivale a compilar un APK ni a verificar los ABI nativos Android.

Se resolvieron las dependencias y se actualizó pubspec.lock. El paquete sqlite3 usa assets nativos; el motor incorporado en Android y los plugins deberán verificarse al generar/ejecutar el APK. La prueba anterior de APK se detuvo por falta de espacio al extraer el NDK; esta etapa no repite esa descarga ni afirma haber comprobado Windows o un celular real.

## Siguiente paso

Conectar el guardado al ViewModel con IDs estables, prevención de dobles pulsaciones, progreso, reintento y error. Sustituir la vista previa por un estado «guardada en el celular» solo tras recibir el commit local. Preparar antes los catálogos necesarios sin convertir los fixtures visuales en compras reales.
