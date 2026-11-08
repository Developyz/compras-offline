# Servidor PC — organización prevista

Este directorio contiene instrucciones de diseño. Todavía no es un proyecto Spring Boot ejecutable: no tiene constructor configurado, dependencias, controladores ni conexiones.

Stack confirmado: Java con Spring Boot y PostgreSQL en la PC Windows 10. Arquitectura por capas: controladores, servicios y repositorios. Ver [estructura y etapas](../docs/estructura-y-etapas.md).

## Límites de responsabilidad

- Controllers: solicitudes/respuestas HTTP conforme a OpenAPI.
- DTOs: mensajes de transporte, separados de modelos de persistencia.
- Services: reglas, autorización, transacciones y coordinación.
- Repositories/Persistence: acceso a PostgreSQL.
- Config/Security: red local, TLS, dispositivos y credenciales.
- Administration: generar QR y aprobar/revocar dispositivos desde la PC; interfaz pendiente.

## Pendiente antes de generar archivos

Elegir versiones de Java y Spring Boot compatibles con el equipo; confirmar Maven o Gradle, herramienta de acceso a datos y migraciones. Los ejemplos que mencionan JPA/Hibernate/Flyway no los convierten en decisiones confirmadas.

La configuración real de PostgreSQL se hará en la PC y quedará fuera de Git. No abrir puertos del router ni publicar la API en internet. El celular se comunica por la API dentro de la misma red local.

## Contratos y SQL

- [OpenAPI propuesto](../docs/api/openapi.json)
- [Reglas v2](../docs/api/decisiones-v2.md)
- [Instalación y migraciones](../DB/migrations/README.md)

No copiar los scripts completos a un ejecutor de migraciones sin adaptar su gestión de transacciones y registro de versiones. Los scripts manuales y una herramienta futura no deben aplicar la misma migración dos veces.
