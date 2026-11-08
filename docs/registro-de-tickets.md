# Registro de tickets e imágenes

## Decisión confirmada

La primera versión incluirá lectura automática del ticket para extraer datos y registrar una compra. El usuario podrá revisar y corregir los datos antes de confirmar.

### Captura desde la app

- La imagen se utiliza temporalmente para leer el ticket.
- No se conserva como adjunto, no se guarda en la galería y no se sincroniza con la PC.
- Al confirmar la compra se guardan los datos del registro y se elimina la imagen temporal.
- Al cancelar también se elimina la imagen temporal.
- Si falla la lectura, el usuario puede reintentar o cargar los datos manualmente.

### Imagen subida por el usuario

- Si el usuario selecciona una foto existente y decide adjuntarla, la app permite conservarla como comprobante de la compra.
- Esta acción es explícita y se distingue de tomar una foto desde la app.
- La política de sincronización y retención de estos adjuntos aún debe definirse.

## Consecuencias para el diseño

- La lectura de tickets forma parte del alcance inicial; reemplaza la propuesta previa de posponerla.
- Los datos de compra y los archivos adjuntos tendrán ciclos de vida separados.
- La captura temporal no debe entrar en la cola de sincronización de archivos.

## Propuestas técnicas por validar

- Procesar la lectura en el celular para mantener el funcionamiento sin conexión.
- Usar almacenamiento temporal privado, excluido de copias de seguridad.
- Limpiar capturas abandonadas tras un cierre inesperado sin eliminar borradores ni compras pendientes.

## Pendientes

- Elegir el motor de lectura y validar su funcionamiento sin conexión.
- Definir los campos extraídos, la revisión y el manejo de tickets ilegibles.
- Definir tamaño máximo, sincronización y retención de imágenes adjuntas, incluyendo su relación con los 30 días de historial local.
