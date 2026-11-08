# Prototipo visual de Android — versión 03

## Abrir

Descargar `index.html` y abrirlo con un navegador. Es autocontenido: no requiere instalar dependencias, servidor ni conexión a internet. GitHub muestra el código HTML; su vista de archivo no ejecuta el prototipo.

## Pantallas

1. Inicio: resumen ilustrativo de los últimos 30 días, canasta y última compra.
2. Canasta: productos y total estimado.
3. Captura de ticket: ilustración y acceso al ticket de ejemplo.
4. Revisión de compra: escenarios de lectura correcta, datos dudosos y diferencia de total. Los botones de ejemplo permiten resolver advertencias antes de ver la confirmación.
5. Historial: listado de compras ficticias.
6. Detalle: renglones, descuento, total y estado ilustrativo.
7. Productos: catálogo ficticio de arroz, leche y manzana con búsqueda visual.
8. Detalle del producto: gráfico de precios, variación frente al registro anterior, precio equivalente por kg/litro e historial de observaciones.
9. Estados de pantalla: selector de escenarios sin compras, canasta vacía, ticket ilegible, guardada localmente, pendiente, error de sincronización y sincronización confirmada.

En teléfono se muestra navegación inferior con Inicio, Canasta, Cámara, Productos e Historial. La cámara es la acción principal, con un botón circular destacado en el centro. En escritorio se agrega un índice lateral. Los botones permiten recorrer el flujo y el botón Atrás del navegador funciona mediante rutas hash.

## Alcance y límites

Es una maqueta HTML/CSS/JavaScript para revisar vistas. No es la aplicación Flutter ni un proyecto Android compilable. El nombre visual «canasta.» es provisional. La moneda confirmada es el guaraní paraguayo (PYG), representado con ₲ y sin decimales. Los importes y fechas son ficticios; no son conversiones de los ejemplos anteriores ni datos reales del usuario. En la futura integración de datos se utilizará decimales_moneda=0 para PYG.

No implementa modelos de negocio, ViewModels, reglas de cálculo, edición, almacenamiento, SQLite, API, PostgreSQL, cámara, OCR, selección de archivos, adjuntos ni sincronización. Los controles no disponibles muestran una explicación. La confirmación solo abre una pantalla de ejemplo y no modifica el historial. Al recargar no se conserva ninguna acción.

## Pendientes comentados en index.html

Cada sección tiene un comentario TODO con sus futuras responsabilidades. Al implementar Flutter, separar las Views de negocio y representar los escenarios de estado en sus pantallas correspondientes; el selector de escenarios es solo una herramienta de revisión del prototipo. Se deberán; enlazarlas a ViewModels y servicios; acceder a SQLite mediante repositorios y a la API mediante un cliente HTTP independiente. Las Views y modelos de datos no deben abrir conexiones.

La conexión a PostgreSQL pertenece exclusivamente al servidor Java/Spring Boot y se configurará en la PC. No hay credenciales ni direcciones de servidor en este prototipo.

La captura desde la app será temporal y se eliminará al confirmar o cancelar. La subida voluntaria de una foto puede conservarla como comprobante. En esta maqueta ninguna imagen se captura o almacena.

## Validación

Se verifican sintaxis JavaScript, enlaces internos, IDs de pantallas y ausencia de llamadas de red y almacenamiento. En la versión 02 se comprobaron las ocho rutas, los tres gráficos y tablas, el filtro de catálogo, porcentajes y equivalencias mediante DOM simulado, además de sintaxis JavaScript y referencias HTML. No se realizó revisión visual en navegador: la herramienta de control de navegador no está disponible en este entorno.


## Historial de precios del prototipo

Los cuatro puntos de cada gráfico son observaciones ficticias entre el 12 de octubre y el 8 de noviembre de 2026. Se muestran precios antes de descuentos por paquete de 500 g (arroz), caja de 1 L (leche) y kg (manzana). No se prorratea el descuento general de la compra. El último precio coincide con los ejemplos anteriores. Las líneas solo unen observaciones; no representan precios en vivo ni valores conocidos entre compras.

Los botones bajo el gráfico muestran fecha, comercio y precio del punto seleccionado. El catálogo y las series son ejemplos de diseño independientes del resumen de gastos; sus registros anteriores no se agregan como compras al historial del prototipo.

No se implementaron nuevas consultas, tablas, ViewModels ni conexiones. Las observaciones históricas de más de 30 días y los informes mensuales completos siguen sujetos a la definición de acceso a la PC o resúmenes locales.


## Cierre visual: revisión y estados

Se puede acceder al selector de estados desde Inicio. En Revisión, el selector de lectura permite probar advertencias de producto poco legible, cantidad dudosa y total que no coincide. La confirmación visual se bloquea hasta resolver los ejemplos. Los valores son prefijados: no se implementaron OCR, reglas reales de negocio ni edición libre.

En la implementación real, las advertencias pertenecerán al estado del ViewModel y los datos se corregirán mediante controles de edición. Guardar debe confirmar primero la transacción local. Sincronizada requiere el recibo del servidor. Un envío interrumpido no equivale a compra perdida y sus reintentos deben reutilizar el identificador de operación.

El selector de estados es una herramienta de revisión: las variantes vacías no sustituyen el catálogo ficticio en las otras pantallas. Simular reintento vuelve al estado pendiente, sin ejecutar solicitudes ni declarar éxito.

La expresión «estado de cuenta» se interpretó provisionalmente como estados del registro y sincronización, conforme a la mejora que se venía priorizando; no se implementó un estado financiero nuevo. Queda pendiente aclarar si el usuario se refería al resumen de gastos.

Se verificaron nueve destinos, siete estados y el bloqueo/desbloqueo de la revisión con DOM simulado, además de sintaxis y referencias internas. Sigue pendiente la inspección visual en navegador.

Presupuesto mensual, gastos por categoría y repetir compra quedan para futuras etapas. Antes de implementar conexiones, la siguiente fase de definición es cerrar operaciones y contratos de API y elegir las librerías pendientes.
