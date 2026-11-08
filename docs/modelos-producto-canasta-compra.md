> Informe de la etapa anterior. La integración de revisión se documenta en [repositorios y ViewModel](repositorios-y-viewmodel-revision.md).

# Modelos de producto, canasta y compra

Se amplía el dominio Dart con entidades inmutables y validaciones locales. Todavía no se conectan las pantallas ni se implementan repositorios, SQL, cámara, OCR o API. Los datos ficticios de la demostración permanecen separados.

## Modelos

| Archivo en `android/lib/domain/models/` | Contenido |
| --- | --- |
| `identidad_y_fecha.dart` | UUID, límites de texto y fecha civil válida |
| `producto.dart` | Producto, tipo de venta, unidad, contenido y contexto histórico |
| `canasta.dart` | Canasta, items y estimación completa o parcial |
| `compra.dart` | Compra, detalle, descuento y referencia de sucursal |
| `valores_compra.dart` | Importes PYG y cantidades exactas de la etapa anterior |
| `borrador_compra.dart` | Entrada de revisión y resumen de la etapa anterior |

Los IDs se reciben del futuro coordinador, se validan como UUID y se normalizan a minúsculas. No hay generación de IDs ni búsquedas implícitas. Los campos opcionales desconocidos permanecen null. Se validan longitudes de texto y se rechazan IDs duplicados; las colecciones conservan copias inmutables.

## Productos e historia

Producto incluye nombre, presentación, tipo de venta, marca/categoría opcionales y contenido opcional. El contenido agrupa cantidad y unidad para impedir datos incompletos. Las unidades tienen dimensión (conteo, masa o volumen) y factor entero positivo hacia unidad, gramo o mililitro.

El contexto histórico almacena nombre/presentación conocidos y, cuando se conocen, contenido, símbolo, dimensión y factor. La escala de cantidad también puede ser desconocida. Los grupos se representan con objetos completos para impedir combinaciones parciales.

`ContextoHistorico.desdeProducto` permite tomar una copia explícita al registrar y exige la unidad de contenido correspondiente cuando el producto lo tiene. No se ejecuta al editar el catálogo. Los detalles conservan además la descripción original del ticket. Para datos antiguos se admite contexto desconocido sin rellenarlo con el catálogo actual. La normalización de precios por kg/l queda pendiente.

## Canasta

Los items contienen descripción, producto opcional, cantidad, unidad y precio unitario estimado opcional. Una canasta vacía es válida. Se admiten hasta 1000 items con IDs únicos; moneda PYG y cero decimales son constantes.

La estimación utiliza el cálculo exacto HALF_UP existente. Distingue el subtotal conocido y el número de items sin precio. El total completo es null cuando falta algún precio: no se confunde desconocido con cero. Una canasta vacía suma cero. Si un resultado no cabe en int64 se rechaza, sin truncarlo.

## Compra

Compra incorpora fecha UTC con precisión de milisegundos y fecha civil del comercio separada. La fecha civil valida el calendario (incluidos años bisiestos); no se deriva de la zona horaria actual del celular. El adaptador de captura tendrá que aportar ambas fechas correctamente.

Incluye referencias opcionales a comercio, sucursal y canasta. La referencia de sucursal incluye su comercio y se exige que coincida con el de la compra. Esto comprueba la coherencia del objeto recibido; no prueba que las referencias existan en la base de datos. Esa comprobación corresponde a repositorios/servicios y al servidor.

Cada detalle incluye UUID, número de línea único entre 1 y 1000, producto opcional, descripción original, cantidad/unidad, precio, bruto y contexto histórico. Cada descuento tiene UUID, descripción, importe y detalle opcional. Se reutiliza `RevisionCompra` para verificar descuentos y sumas.

El resumen y los importes finales por detalle se derivan de los detalles/descuentos, evitando resúmenes contradictorios. Los descuentos generales no se reparten entre productos. La compra confirmada exige total de ticket coincidente y ningún campo pendiente; el borrador puede conservar esas discrepancias para revisión. El estado anulada conserva el tratamiento del contrato, sin imponer la coincidencia exigida a confirmadas. No se implementan transiciones de estado ni acciones de anulación.

Construir una compra válida **no guarda ni sincroniza datos**. No se cambia el importe leído por cantidad × precio, no se crean fotos y no se devuelve un recibo de guardado ficticio.

## Relación con el contrato

Son modelos de dominio, no DTO JSON. Se agrupan datos relacionados en objetos y se calculan resúmenes en vez de aceptar campos redundantes. El futuro adaptador traducirá estos valores a la estructura OpenAPI sin perder enteros ni contexto histórico. Los metadatos de versión, tombstones, cola, retención y estado de sincronización siguen pendientes en la capa de almacenamiento/sincronización.

No se validan todavía existencia de producto/unidad/marca/categoría/comercio/canasta, compatibilidad de catálogos externos ni transiciones de estados. Esta entrega no habilita persistencia ni envío por API.

## Verificación

Se añadieron 14 pruebas sobre fechas, UUID, contenido, factores, conservación histórica, precios desconocidos, redondeo, desbordamiento, referencias, estados, duplicados, descuentos e inmutabilidad. Junto con las 25 anteriores, `flutter test` aprueba **39 pruebas**. `flutter analyze` termina sin observaciones.

No se modifican vistas, dependencias, SQL ni servidor. APK y prueba en celular siguen pendientes; esta entrega valida dominio y regresión de las vistas en pruebas Flutter.

## Siguiente etapa

Definir interfaces de repositorios y un ViewModel para integrar la revisión en pantalla. Mantener la implementación SQLite/HTTP pendiente hasta preparar sus adaptadores y pruebas.
