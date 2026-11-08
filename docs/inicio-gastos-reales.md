# Inicio con gastos reales

Se conserva el estilo visual actual y se conecta Inicio a SQLite mediante InicioViewModel. La sesión normal ya no presenta el gasto ficticio, la canasta ficticia ni los estados de envío de ejemplo en Inicio. El prototipo sin sesión se conserva para sus pruebas.

La tarjeta principal muestra el total del mes calendario y su número de compras, usando fecha_local. El resumen del historial muestra total y cantidad de compras disponibles en este celular. No representa el historial completo de la PC ni una ventana móvil de 30 días. Solo se incluyen compras confirmadas, no eliminadas; anuladas y borradores no suman.

El cálculo consulta todas las cabeceras correspondientes, sin el límite de 100 del listado. Suma enteros con BigInt, incluso cuando el agregado supera int64, sin double ni SUM de SQLite que pueda desbordarse. Los resúmenes y las tres últimas compras se leen en una transacción consistente. Estas últimas se ordenan por fecha local, fecha UTC e ID y abren el detalle real.

Inicio recarga al regresar desde otra pantalla, al reanudar la aplicación y mediante Actualizar. El ViewModel descarta respuestas antiguas y no notifica después de destruirse. Una lectura fallida muestra error y Reintentar, sin sustituir datos por cero o ejemplos.

Sin compras muestra cero y una invitación a registrar. Las pantallas Canasta, Productos y Estados siguen como prototipo identificado. Cámara/OCR y sincronización continúan pendientes. No cambia la base, los datos guardados, el protocolo ni el diseño general. No se aplica todavía limpieza por antigüedad; la futura retención tendrá que mantener disponible un resumen mensual verificado si retira compras sincronizadas.

Validación: 90 pruebas aprobadas y análisis sin observaciones. Se añaden pruebas de base vacía, más de 100 compras, límites de mes, exclusión de anuladas/eliminadas, importes agregados mayores a int64 y recuperación tras fallo. El recorrido existente también comprueba que, tras guardar y volver a Inicio, aparece el gasto real y desaparece el valor ficticio.

La versión 0.4.1+5 actualiza la aplicación de prueba sin cambiar el ID de paquete. GitHub Actions compila el APK ARM64 y ejecuta otra vez análisis, pruebas y verificación de firma. No se ha comprobado aún esta actualización en el Redmi del usuario.

## Claridad y actualización de prueba

El usuario pide funcionamiento entendible para personas mayores y niños, manteniendo el diseño actual. Se cambia «Total del ticket» por «¿Cuánto pagaste?» y se explica el descuento como el de toda la compra, opcional. El precio indica si corresponde a uno, kg o litro. La Canasta real deja de mostrar productos y precios ficticios: explica que es la futura lista de próximas compras y permite abrir el historial de compras guardadas. Su persistencia todavía no está implementada. Nombre provisional elegido: Alisto; el cambio visual queda para después.

Se mantienen 90 pruebas aprobadas y análisis limpio, incluyendo ausencia del precio ficticio de Canasta y regreso a Inicio con importes reales.

La compilación 42528755795 terminó correctamente, pero se compararon los certificados del APK instalado y el nuevo y difieren. El primer certificado SHA-256 es `77d952ef70a9932bc9c84b0572648f87bcf497ae881f6e93b9cc62082e508e18`; el nuevo es `af674ec2cd849878bc0a0fb421503044c9ffe45ab50c7a9ed45cec3dada21abd`. Mantener el ID de paquete no basta para actualizar: falta resolver una identidad de firma persistente para futuras compilaciones y una migración/respaldo verificable de los registros anteriores. No recomendar desinstalar la versión instalada ni afirmar que esta actualización conserva sus datos automáticamente.
