# Compras Server — Spring Boot mínimo

Base Java **21 / Spring Boot 4.1.2**, generada con Spring Initializr. Incluye Maven Wrapper **3.10.0**, prueba de arranque y paquetes con comentarios TODO para las capas futuras.

## Ejecutar en Windows

Se necesita un **JDK 21 completo**, no solamente un JRE. Configurar JAVA_HOME a ese JDK y, desde esta carpeta:

```powershell
.\mvnw.cmd -version
.\mvnw.cmd verify
java -jar .\target\compras-server-0.0.1-SNAPSHOT.jar
```

El wrapper descarga Maven en el primer uso; tiene checksum SHA-256 de la distribución. No exige instalar Maven global. En Linux/macOS usar `./mvnw`.

## Comportamiento actual

La aplicación arranca su contexto y termina normalmente porque `spring.main.web-application-type=none`. **No inicia un servidor HTTP ni expone los endpoints OpenAPI.** Tampoco crea un DataSource, ejecuta migraciones o abre PostgreSQL. Este comportamiento permite verificar la base sin conexiones.

No se deben introducir credenciales ni configurar bases para que pase esta prueba.

## Capas preparadas

Los archivos `package-info.java` documentan la responsabilidad pendiente de configuración, seguridad, compras, productos, canastas, vinculación, sincronización, informes y administración local.

Todavía no hay modelos, DTOs, controladores ni repositorios funcionales. JDBC, Flyway, Security y MVC se agregarán cuando toque su fase; por ahora las dependencias son el starter base y el de pruebas, gestionados por el parent Spring Boot.

- [Contrato de API](../docs/api/openapi.json)
- [Reglas de datos y sincronización](../docs/api/decisiones-v2.md)
- [SQL y migraciones manuales](../DB/migrations/README.md)
- [Resultados de validación](../docs/validacion-proyectos-base.md)

Los SQL manuales no están copiados a recursos ejecutables: al integrar Flyway se adaptarán transacciones y baselines, evitando aplicar dos veces el esquema.
