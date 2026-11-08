# Preparación en Windows — todavía sin conexiones

Objetivo: comprobar el entorno antes de generar Flutter y Spring Boot. Esta guía no se ha ejecutado en la PC del usuario.

## Datos del equipo pendientes

- Windows 10 de 64 bits: edición y compilación.
- CPU/arquitectura, RAM y espacio libre.
- Versión Android y modelo del celular.
- Herramientas ya instaladas y sus versiones.

No enviar claves, tokens o contraseñas al chat ni al repositorio.

## Preparación propuesta

1. Verificar los datos del equipo y comparar con requisitos oficiales.
2. Instalar Git y un editor compatible.
3. Descargar la versión candidata de Flutter desde el archivo oficial, verificar el checksum y registrar la versión Dart incluida. Mantener el SDK fuera de carpetas que requieran elevación.
4. Instalar Android Studio/SDK, aceptar las licencias personalmente y preparar el celular por USB para pruebas de desarrollo.
5. Instalar JDK 21 x64 desde el proveedor seleccionado y comprobar la ruta efectiva.
6. Cuando se genere Spring Boot, incorporar Maven Wrapper y su versión fijada; no hace falta mantener Maven global si usamos el wrapper.
7. PostgreSQL se instalará/configurará en una fase posterior de persistencia. No abrir puertos ahora.

Las descargas y dependencias requieren internet durante el desarrollo. Eso no cambia el objetivo de funcionamiento offline de la app instalada.

## Comandos de diagnóstico para el usuario, cuando esté en la PC

Ejecutar en PowerShell tras instalar las herramientas correspondientes:

```powershell
git --version
java -version
where.exe java
flutter --version
flutter doctor -v
flutter devices
```

Muestran versiones/estado y no crean bases ni servidores. No interpretar un comando ausente como fallo de arquitectura: significa que la herramienta no está instalada o no está en PATH.

La aceptación de licencias se hace después con flutter doctor --android-licenses, revisando sus términos. No la ejecutamos ni aceptamos por el usuario desde este chat.

## Verificación al generar los proyectos

Solo en la fase de implementación:

- Crear un proyecto Flutter mínimo con destino Android y datos demo, ejecutar flutter pub get y guardar pubspec.lock real.
- Registrar AGP, Gradle Wrapper, SDK de compilación/target, JDK de Gradle y ABI elegidos por la plantilla. No confundir el Wrapper Gradle Android con Maven del servidor.
- flutter analyze y flutter test; construir APK debug y ejecutar en el celular.
- Crear Spring Boot mínimo con Maven Wrapper y verificar .\mvnw.cmd -version y .\mvnw.cmd test sin base real ni credenciales.
- Desactivar/configurar por perfil las integraciones que requieran datos hasta su fase; no simular éxito de sincronización o conexión.

## Criterio para pasar a las vistas Flutter

Deben compilar los proyectos mínimos y estar identificado un dispositivo de prueba. En ese momento trasladaremos Inicio, Canasta, Captura/Revisión, Historial, Productos/Detalle y estados, inicialmente con datos ficticios claramente señalados.

Cámara real, OCR, SQLite y API se agregan por sus etapas. Los modelos que se necesitan offline deben estar incluidos en el APK antes de probar el primer uso sin internet.

Consultar [versiones propuestas](herramientas-y-versiones.md) y [registro de candidatos](toolchain/versiones-candidatas.json). Ninguno sustituye una resolución de dependencias y prueba de compilación.
