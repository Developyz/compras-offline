# Prototipo visual de Android — versión 01

## Abrir

Descargar `index.html` y abrirlo con un navegador. Es autocontenido: no requiere instalar dependencias, servidor ni conexión a internet. GitHub muestra el código HTML; su vista de archivo no ejecuta el prototipo.

## Pantallas

1. Inicio: resumen ilustrativo de los últimos 30 días, canasta y última compra.
2. Canasta: productos y total estimado.
3. Captura de ticket: ilustración y acceso al ticket de ejemplo.
4. Revisión de compra: datos de lectura simulados, descuentos y total.
5. Historial: listado de compras ficticias.
6. Detalle: renglones, descuento, total y estado ilustrativo.

En teléfono se muestra navegación inferior. En escritorio se agrega un índice lateral. Los botones permiten recorrer el flujo y el botón Atrás del navegador funciona mediante rutas hash.

## Alcance y límites

Es una maqueta HTML/CSS/JavaScript para revisar vistas. No es la aplicación Flutter ni un proyecto Android compilable. El nombre visual «canasta.» es provisional. ARS y fechas se usan únicamente en los ejemplos; no son una decisión de moneda ni datos reales del usuario.

No implementa modelos de negocio, ViewModels, reglas de cálculo, edición, almacenamiento, SQLite, API, PostgreSQL, cámara, OCR, selección de archivos, adjuntos ni sincronización. Los controles no disponibles muestran una explicación. La confirmación solo abre una pantalla de ejemplo y no modifica el historial. Al recargar no se conserva ninguna acción.

## Pendientes comentados en index.html

Cada sección tiene un comentario TODO con sus futuras responsabilidades. Al implementar Flutter, separar las seis Views; enlazarlas a ViewModels y servicios; acceder a SQLite mediante repositorios y a la API mediante un cliente HTTP independiente. Las Views y modelos de datos no deben abrir conexiones.

La conexión a PostgreSQL pertenece exclusivamente al servidor Java/Spring Boot y se configurará en la PC. No hay credenciales ni direcciones de servidor en este prototipo.

La captura desde la app será temporal y se eliminará al confirmar o cancelar. La subida voluntaria de una foto puede conservarla como comprobante. En esta maqueta ninguna imagen se captura o almacena.

## Validación

Se verifican sintaxis JavaScript, enlaces internos, IDs de pantallas y ausencia de llamadas de red y almacenamiento. La revisión visual en navegador se indicará por separado según la disponibilidad del entorno.
