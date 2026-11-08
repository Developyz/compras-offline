# Catálogo de productos y comparación

## Decisiones confirmadas

Además de los datos del ticket, registrar el comercio y distinguir los productos por marca, presentación y contenido cuando esos datos estén disponibles. Usar esta información para comparar precios por unidad, kilogramo o litro.

## Ficha propuesta

- Identificador interno estable.
- Nombre del producto.
- Marca, si se conoce.
- Presentación o variante, si se conoce.
- Contenido neto y unidad de medida, si se conocen.
- Código de barras opcional.

La falta de marca, contenido o código de barras no debe impedir registrar una compra. La ficha es una propuesta de diseño pendiente de completar; no es un esquema SQL implementado.

## Separación propuesta de datos

El catálogo identifica el producto. Cada renglón de compra conserva la descripción original del ticket, la referencia al producto cuando esté identificado, cantidad, unidad de compra, precio y descuentos. La compra conserva fecha, comercio y total.

El precio es una observación de una compra concreta y no debe reemplazar el historial. Una modificación posterior del catálogo no debe alterar los importes ni las cantidades históricas.

## Comparación propuesta

Comparar importes en la misma moneda y con unidades compatibles. Conservar el precio observado y mostrar explícitamente si una comparación usa precio antes o después de descuentos. La distribución de descuentos generales está pendiente de definir.

Ejemplo sin descuentos: un paquete de 500 g a 1500 equivale a 3000 por kg; uno de 1 kg a 2800 equivale a 2800 por kg. La cantidad de paquetes comprados y el contenido de cada paquete son datos distintos.

Si falta el contenido, no calcular un precio por kg o litro. Para productos vendidos por peso, registrar el peso comprado y su unidad sin tratarlos como paquetes de peso fijo.

## Identificación propuesta

Conservar la descripción original aunque se vincule con el catálogo. Sugerir coincidencias de productos durante la revisión y pedir al usuario que resuelva las ambiguas, evitando unir automáticamente productos distintos por descripciones abreviadas.

## Pendientes

- Validar la ficha propuesta y las reglas de identificación.
- Definir variantes y presentaciones múltiples.
- Definir descuentos por renglón y sobre el total.
- Definir moneda y reglas de redondeo.
- Resolver la disponibilidad de comparaciones e informes con la retención local de 30 días.
