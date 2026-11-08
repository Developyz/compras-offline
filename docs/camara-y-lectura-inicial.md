# Cámara y lectura asistida inicial

Se conecta el recorrido Cámara → Fotografiar ticket → tomar foto → lectura local → completar/revisar → confirmar → SQLite. La entrada real de captura deja de mostrar tickets ficticios. La carga manual sigue disponible cuando no hay cámara o se deniega el permiso.

Se incorpora camera 0.12.2, con cámara trasera y audio desactivado, y google_mlkit_text_recognition 1.0.1 con script latino. La dependencia Android `com.google.mlkit:text-recognition:16.0.1` incluye el modelo; no se usa el reconocimiento servido por una API ni se configura descarga mediante Play Services. La operación real sin internet aún debe comprobarse físicamente.

## Qué interpreta esta versión

El OCR devuelve texto, no una compra validada. Se conserva como referencia desplegable durante la revisión, sin persistirlo íntegro ni adjuntarlo a la compra.

Se sugiere el total solamente si existe una línea TOTAL explícita y no hay más de una coincidencia. No se confunde SUBTOTAL con TOTAL ni se interpretan decimales monetarios como guaraníes.

Se proponen productos para renglones explícitos como `ARROZ 2 x 1.000 = 2.000` o `MANZANA 0,5 kg x 4.000 = 2.000`. La propuesta requiere cantidad positiva, precio entero y bruto coherente con el cálculo exacto. La unidad ausente se propone como conteo y debe revisarse. No se crean identificaciones de catálogo por semejanza de nombre. Líneas ambiguas, precios decimales y totales incoherentes no se convierten automáticamente.

No es un parser universal de tickets: descripciones separadas en otra línea, promociones complejas, descuentos, fechas y formatos no reconocidos requieren completar/corregir el formulario. Siempre se advierte que la lectura puede estar incompleta, se permite consultar el texto y se exige marcar «Revisé fecha, productos e importes». Editar datos desmarca esa revisión. Después sigue la revisión de dominio existente, que bloquea diferencias de total; no se guarda solo por coincidir los importes.

## Fotos temporales

Solo la fotografía tomada por esta cámara se procesa como temporal. No hay selector de galería ni almacenamiento de adjuntos en este flujo.

La captura se copia a un directorio privado temporal propio `alisto_ticket_*`, se retira el original devuelto por la cámara y se procesa localmente. Se intenta borrar ambas ubicaciones con finally incluso cuando el OCR falla. La imagen se elimina al finalizar la lectura, antes de presentar el formulario, sin esperar al guardado. No queda una ruta de imagen en Compra, SQLite o cola y no se envía a la PC.

Al iniciar la aplicación se limpian directorios huérfanos con ese prefijo, sin seguir enlaces ni borrar imágenes ajenas. Si el proceso se interrumpe, la limpieza ocurre en el siguiente arranque; el cache original que un plugin pueda dejar antes de devolver la captura no se elimina indiscriminadamente. Las pruebas no permiten prometer borrado físico inmediato tras una caída del sistema.

La cámara libera su controlador antes de abrir el formulario, al abandonar la pantalla o al pasar a segundo plano, y se reinicia al regresar cuando corresponde. Se bloquean capturas dobles y lecturas concurrentes desde la pantalla. Los errores de permiso y lectura ofrecen reintento o carga manual.

## Comprobación

Se añaden seis pruebas: selección conservadora del total, renglones coherentes, eliminación de archivos con éxito/error, protección de archivos ajenos y desmarcado de revisión al editar. Los tests de archivos usan archivos temporales reales y un reconocedor inyectado; no prueban un motor ML Kit en Linux ni una cámara física.

Resultado local: 99 pruebas aprobadas y análisis sin observaciones. El pipeline Android debe comprobar además el ensamblado con los plugins nuevos. La calidad de OCR, enfoque, rotación, permisos y funcionamiento offline requieren pruebas en el Redmi con tickets reales. No se afirma que esta versión esté instalada ni probada en ese teléfono.

Se mantienen SQLite v4 y el protocolo v2. La actualización del APK sobre la instalación anterior sigue pendiente de una solución de firma y conservación de datos: no desinstalar el APK existente como atajo.

## Ensamblado Android comprobado

GitHub Actions completó correctamente la ejecución [42530958936](https://github.com/Developyz/compras-offline/actions/runs/42530958936): SDK, análisis, 99 pruebas, ensamblado del APK debug ARM64 y verificación de firma. Se confirma la compilación con ambos plugins, no el funcionamiento físico de cámara/OCR ni la compatibilidad de actualización con la firma instalada anteriormente.
