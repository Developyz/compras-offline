# Vinculación del celular con la PC mediante QR

## Alcance confirmado

La vinculación inicial se realizará escaneando desde Android un QR mostrado en la PC. La comunicación será exclusivamente por la misma red local. El celular conserva su funcionamiento offline-first.

Este documento diseña el flujo; no implementa cámara, QR, pantallas de PC, endpoints ni conexiones. Los detalles técnicos siguientes son propuestas para formalizar en OpenAPI.

## Recorrido del usuario

1. En la PC, el usuario abre la herramienta local de administración del servidor y elige **Vincular celular**.
2. La PC crea una sesión temporal y muestra un QR con cuenta regresiva y opción de cancelar.
3. En Android, **Conectar con mi PC → Escanear QR** solicita permiso de cámara para leer ese código.
4. Android identifica el servidor y envía la solicitud de vinculación.
5. La PC muestra el nombre del celular y pide **Autorizar** o **Rechazar**. No autorizar automáticamente por compartir Wi-Fi.
6. Tras autorizar, el celular recibe su credencial y muestra **PC vinculada**.
7. El arranque de sincronización usa el contrato de snapshot aún pendiente. Vinculada no significa datos sincronizados.

La cámara de vinculación tiene un propósito distinto de la captura de tickets: no ejecuta OCR ni registra compras. No almacena imágenes del QR.

La herramienta de administración de PC todavía no existe y su tecnología visual queda pendiente. Las acciones administrativas de vincular y revocar serán locales a esa PC; no se abrirá una administración sin autenticación a toda la red.

## Contenido propuesto del QR

JSON UTF-8, versión de formato 1:

```json
{
  "tipo": "compras_offline_vinculacion",
  "version": 1,
  "servidor_id": "00000000-0000-4000-8000-000000000201",
  "url_base": "https://192.168.1.50:8443/api/v1",
  "huella_certificado_sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "sesion_id": "00000000-0000-4000-8000-000000000202",
  "secreto_temporal": "<valor-aleatorio-de-un-solo-uso>",
  "expira_en": "2026-11-08T15:35:00.000Z"
}
```

Dirección, puerto, UUID y huella son ejemplos. El secreto entre corchetes es un marcador, no un secreto utilizable. El QR no contiene compras, contraseñas de PostgreSQL ni credenciales permanentes.

Propuestas de parámetros: sesión válida durante 5 minutos, secreto criptográfico de al menos 256 bits generado al azar, número limitado de intentos y una sola solicitud candidata por sesión. La PC decide la expiración con su reloj. Renovar el QR cancela el anterior.

## Identidad del servidor y transporte

- El servidor mantiene un servidor_id estable y un certificado TLS propio cuya huella SHA-256 se incluye en el QR.
- La app valida por un mecanismo de confianza limitada al certificado escaneado: comprueba huella y vigencia antes de enviar el secreto. No usar un callback que acepte cualquier certificado, ni un cliente global que omita validación TLS.
- El mecanismo exacto de validación y actualización del certificado debe probarse con la librería HTTP elegida en Flutter y configurarse en Spring Boot. La propuesta no presupone que Android confíe automáticamente en un certificado local.
- Solo se admiten URLs HTTPS con puerto explícito y ruta esperada, sin usuario/contraseña ni redirecciones hacia otro servidor. Validar que el destino esté dentro de las redes privadas admitidas; el soporte inicial puede limitarse a IPv4 privada y documentar esa limitación.
- Escanear el QR directamente desde la herramienta de la PC es el paso de confianza inicial. El nombre del equipo o una IP coincidente no prueban identidad.
- Si la huella cambia, detener la comunicación y solicitar nueva verificación/vinculación. No aceptar el cambio silenciosamente.

## Contratos propuestos

Todas las rutas móviles se prefijan con /api/v1.

| Acción | Operación propuesta | Protección |
| --- | --- | --- |
| Solicitar vinculación | POST /vinculacion/solicitudes | TLS fijado por QR, secreto temporal |
| Consultar resultado | POST /vinculacion/resultado | Token temporal de la solicitud, enviado en cuerpo |
| Confirmar recepción | POST /vinculacion/confirmaciones | Credencial emitida al dispositivo |
| Comprobar conexión posterior | GET /estado y una consulta autenticada | Identidad del servidor y credencial del dispositivo |

Crear sesión, autorizar, rechazar y revocar pertenecen al canal administrativo local de PC, cuyos endpoints y autorización aún deben definirse. No se mezclan con las operaciones de sincronización.

### Solicitud

Cuerpo: solicitud_id UUID generado en Android, dispositivo_id UUID persistente de la instalación, nombre_dispositivo visible y editable, sesion_id y secreto_temporal.

Respuesta 202: solicitud_id, estado=pendiente_autorizacion, token_consulta y expira_en. Consumir y asociar el secreto a esa solicitud de forma atómica. El dispositivo no obtiene acceso a compras en este paso.

Repetir exactamente la misma solicitud_id/contenido permite recuperar la misma solicitud tras un corte. Otro contenido con ese ID devuelve conflicto. Un secreto ya consumido no permite vincular un segundo dispositivo.

No basta con un UUID o nombre para autenticar un dispositivo. El token_consulta es aleatorio y distinto del secreto inicial. No colocarlo en URLs ni logs.

### Espera y autorización

Android consulta el resultado con solicitud_id y token_consulta, con intervalo mínimo propuesto de 3 segundos y respetando Retry-After. La PC muestra nombre del celular y hora de solicitud.

Posibles respuestas: pendiente_autorizacion, rechazada, expirada y autorizada. Solo autorizada incluye dispositivo_id, servidor_id y credencial_dispositivo. Si se rechaza o expira, la solicitud no emite credenciales y debe generarse un nuevo QR para reintentar.

Un reintento de solicitud/resultados nunca crea un segundo dispositivo ni emite múltiples credenciales activas por accidente.

### Entrega resistente a cortes

La credencial autorizada debe poder recuperarse mediante el mismo token de consulta durante una ventana corta hasta confirmación o expiración. Persistir de forma segura la información necesaria para esa recuperación: almacenar solo un hash del token permanente no basta para volver a entregarlo.

Propuesta: guardar temporalmente la entrega cifrada, protegida con una clave local de la PC; eliminarla al confirmar o al vencer la ventana. Conservar el hash de validación de la credencial para solicitudes posteriores.

Android guarda la credencial mediante almacenamiento protegido por Android Keystore, separado de SQLite y sin incluirla en copias no protegidas. Luego envía la confirmación de recepción, idempotente.

Si no se confirma dentro de la ventana, revocar la credencial provisional y solicitar una vinculación nueva. La sincronización se habilita después de esa confirmación. Confirmar de nuevo tras perder la respuesta no cambia la credencial.

Los detalles de ventanas, recuperación ante reinicio y errores se formalizarán antes de implementar.

## Después de vincular

La app guarda servidor_id, dirección local y huella junto con la asociación al dispositivo. La credencial viaja en Authorization: Bearer y se valida contra el dispositivo autorizado y no revocado en cada operación.

No habrá QR en cada sincronización. Se vuelve a usar para una nueva instalación, cambio de identidad/certificado, credencial revocada o recuperación explícita de la vinculación.

La propuesta inicial usa una credencial aleatoria revocable por dispositivo, no requiere JWT ni un servicio externo. Su duración, rotación y eventual renovación deben fijarse antes de implementar.

## Si cambia la IP de la PC

Primera opción de configuración: reserva DHCP en el router para mantener la dirección local estable.

Si cambia de todos modos, mostrar **No encontramos tu PC**, conservar los pendientes y ofrecer **Actualizar dirección con QR**. Un QR de dirección contiene tipo=compras_offline_direccion, version, servidor_id, url_base y huella, sin secreto de vinculación. Solo se acepta si servidor_id y huella coinciden con los ya confiados; después comprobar la conexión con la credencial existente.

Cambiar de red o IP no permite reemplazar el servidor_id de una cola pendiente. Una PC nueva o una base restaurada con otra identidad requiere un flujo de recuperación; no redirigir compras automáticamente.

El descubrimiento automático por mDNS queda fuera del alcance inicial. No abrir puertos del router ni recurrir a un servidor remoto.

## Errores que deberá mostrar la interfaz

| Situación | Mensaje o acción |
| --- | --- |
| Cámara sin permiso | Explicar el permiso y permitir volver a intentarlo desde ajustes |
| QR inválido | No es un código de vinculación compatible |
| QR vencido o utilizado | Generar un nuevo QR en la PC |
| PC no accesible | Revisar la misma red local y que Spring Boot esté encendido |
| En espera | Confirmá la solicitud en tu PC |
| Rechazada | La PC no autorizó este celular |
| Identidad/certificado diferente | Detener conexión y volver a verificar en la PC |
| Credencial revocada | Conservar pendientes y solicitar nueva vinculación |
| Interrupción tras autorizar | Recuperar la misma entrega o reiniciar el flujo si expiró |

## Cambios de almacenamiento pendientes

Las tablas actuales no implementan estas funciones por sí solas. Se deberán diseñar migraciones para sesiones temporales, solicitudes, autorización, entrega provisional y hash/revocación de credenciales. dispositivos puede ampliarse o relacionarse con nuevas tablas; no guardar secretos en texto plano.

En Android se necesita configuración del servidor confiado y almacenamiento seguro de credenciales. Las compras pendientes y el cursor deben permanecer asociados al servidor correcto.

No se modificaron los scripts SQL ni se agregaron credenciales o puertos abiertos en esta etapa.

## Criterios para verificar al implementar

- Un QR vencido/reutilizado no autoriza otro celular.
- Dos solicitudes concurrentes no consumen la misma sesión para dos dispositivos.
- Una solicitud no accede a datos antes de autorización y confirmación.
- Reintentos tras cortes no crean dispositivos ni credenciales duplicadas.
- Identidad/huella incorrecta impide enviar secretos o credenciales.
- Cancelar, rechazar y revocar tienen efecto real en el servidor.
- PC apagada o red aislada no provoca pérdida de compras.
- Cambiar IP conservando identidad permite recuperar la conexión.
- No se guardan fotos del QR ni secretos en logs o GitHub.

El siguiente paso de diseño es el snapshot inicial y la sincronización de los últimos 30 días después de vincular.
