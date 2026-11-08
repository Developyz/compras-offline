# Estructura del proyecto y etapas de trabajo

**Actualización:** ya existe una primera base de [modelos y revisión](modelos-y-revision-compra.md) sin integración ni conexiones; los proyectos mínimos ya se generaron y las nueve vistas Flutter están disponibles con datos ficticios. Ver [vistas Flutter](vistas-flutter.md). Ver [validación de bases](validacion-proyectos-base.md). Este mapa conserva la planificación de las capas que todavía no están implementadas.


Estado: organización propuesta para preparar la implementación. Se generaron las bases Flutter/Spring Boot con dependencias mínimas, sin conexiones.

## 1. Qué existe y qué falta

Ya existen el prototipo HTML, scripts SQL v1, migraciones v2, OpenAPI y documentos de diseño. Se comprobó la estructura SQL y el contrato, no una app Android ni la comunicación con Windows.

Las carpetas android/ y server/ ya contienen las bases generadas. Se implementaron las vistas Flutter de demostración y el arranque Spring sin HTTP; el resto de esta estructura sigue como planificación. El prototipo HTML permanece separado: se conserva como referencia de los widgets Flutter.

## 2. Android: MVVM con repositorios

Estructura prevista dentro del proyecto Flutter:

```text
android/
  README.md
  pubspec.yaml                    # Dependencias; se generará al iniciar Flutter
  lib/
    main.dart                    # Entrada y composición de dependencias
    app/
      app.dart                   # Aplicación y tema
      routes.dart                # Navegación
    domain/
      models/                    # Producto, Compra, DetalleCompra, Canasta…
      repositories/              # Interfaces independientes de SQLite/HTTP
      services/                  # Reglas de importes, unidades y revisión
    data/
      local/
        app_database.dart        # Apertura de SQLite y transacciones
        migrations/              # Adaptación versionada de los SQL
        queries/                 # Consultas por producto/compra
      remote/
        api_client.dart          # HTTP, validación de servidor y errores
        dto/                     # JSON del contrato OpenAPI
        mappers/                 # DTO ↔ modelos de dominio
      repositories/              # Implementación de interfaces del dominio
    features/
      inicio/
        views/
        viewmodels/
      canasta/
        views/
        viewmodels/
      tickets/
        views/
        viewmodels/
      compras/
        views/
        viewmodels/
      productos/
        views/
        viewmodels/
      vinculacion/
        views/
        viewmodels/
      sincronizacion/
        views/
        viewmodels/
    services/
      camera/                    # Captura temporal y permisos
      ocr/                       # Lectura local, sin subir la captura
      secure_storage/            # Credenciales protegidas por Android
      sync/                      # Cola, snapshots, reintentos y conflictos
  test/
  integration_test/
```

Los directorios nativos de Flutter se generarán con su herramienta. Si mantenemos android/ como raíz del proyecto, habrá un subdirectorio android/android/ para el código nativo: es una consecuencia de ese nombre, no una segunda aplicación.

### Responsabilidades

| Archivo o grupo | Contiene | No debe hacer |
| --- | --- | --- |
| Modelos de dominio | Datos y tipos de compra/producto | Abrir puertos, HTTP o SQLite |
| View | Widgets, formularios y presentación de estados | Escribir SQL o decidir reintentos |
| ViewModel | Estado visual, acciones y coordinación con servicios/repositorios | Configurar conexiones o credenciales |
| Interfaz de repositorio | Operaciones que necesita el dominio | Depender de un motor concreto |
| Repositorio implementado | Acceso local y transacciones de datos/cola | Dibujar pantallas |
| Cliente API | Enviar DTOs y traducir errores de transporte | Cambiar compras sin validación de negocio |
| Servicio de sincronización | Operaciones, confirmaciones, dependencias y recuperación | Eliminar pendientes por antigüedad |
| Cámara/OCR | Capturar temporalmente y proponer datos | Guardar una imagen permanente por defecto |

El servicio de sincronización usa repositorios y cliente HTTP. Las vistas no llaman a la API directamente. Las lecturas habituales de la aplicación salen de SQLite; las consultas históricas a la PC son explícitas y muestran su disponibilidad/fuente.

## 3. PC: Spring Boot por capas

Nombre de paquete ilustrativo, sin dominio de organización confirmado:

```text
server/
  README.md
  pom.xml                        # Si elegimos Maven; aún no generado
  src/main/java/<paquete>/
    ComprasApplication.java      # Entrada de Spring Boot
    config/                      # Configuración, sin secretos en Git
    security/                    # Dispositivo, credenciales y permisos
    shared/
      error/                     # Errores API
      money/                     # Importes exactos y conversiones
    productos/
      controller/
      dto/
      service/
      domain/
      repository/
      persistence/
    compras/                     # Mismas responsabilidades por funcionalidad
    canastas/
    catalogos/
    vinculacion/
    sincronizacion/
    informes/
    administration/              # Acciones locales de PC, interfaz pendiente
  src/main/resources/
    application.example.yml      # Ejemplo sin credenciales
    db/migration/                # Si confirmamos Flyway
  src/test/
```

| Capa | Responsabilidad |
| --- | --- |
| Controller | Validar estructura de petición y devolver respuestas HTTP |
| DTO | Representar exactamente los mensajes JSON; no exponer entidades de BD |
| Service | Reglas, autorización de la operación y límites transaccionales |
| Domain | Modelos y reglas independientes del transporte |
| Repository | Contrato para leer/escribir información |
| Persistence | SQL/mapeo y adaptación a PostgreSQL |
| Config/Security | Conexión local, TLS, credenciales y acceso |
| Administration | Generar QR, autorizar/revocar dispositivos desde la PC |

Los controladores no ejecutan consultas directamente. Los servicios coordinan negocio, recibo y evento dentro de una transacción. El repositorio no decide por sí solo que una compra está sincronizada.

La conexión a PostgreSQL se configura aquí, en la PC. Flutter solo conoce la API local. Las credenciales reales se guardan fuera del repositorio. No se eligieron todavía JPA/Hibernate, JDBC, Maven/Gradle ni Flyway: los nombres y rutas dependientes de esas elecciones son propuestas.

## 4. Comentarios para archivos pendientes

Cuando se generen los proyectos reales, cada archivo aún no implementado llevará comentarios específicos, por ejemplo:

```text
Responsabilidad: obtener el historial de un producto para su ViewModel.
Pendiente: implementar la interfaz del repositorio usando SQLite.
Pendiente: mapear cantidades en milésimas e importes PYG enteros.
Pendiente: filtrar registros activos y mostrar el período disponible.
No conectar esta clase directamente a PostgreSQL.
```

No devolver una lista vacía o simular éxito silenciosamente en un método pendiente. Durante el desarrollo, usar una implementación demo identificada o un error explícito de funcionalidad no disponible. Las interfaces y los archivos se generarán con las herramientas elegidas, no se presentarán archivos vacíos como un proyecto funcionando.

## 5. Orden de implementación propuesto

| Fase | Trabajo | Criterio de finalización |
| --- | --- | --- |
| 0. Preparación | Elegir versiones/librerías y verificar herramientas en Windows | Proyecto mínimo Flutter y Spring Boot compilan en el entorno elegido |
| 1. Vistas Flutter | Trasladar prototipo a widgets con datos demo identificados | Navegación y estados revisados en pantalla Android |
| 2. Modelos y reglas | PYG, cantidades, unidades, descuentos y contexto histórico | Ejemplos de compra y comparación coherentes; contratos mapeados |
| 3. Datos locales | SQLite, migraciones y repositorios | Compra/canasta sobreviven al reinicio; dato+cola se guardan atómicamente |
| 4. Cámara y revisión | OCR local, permisos, corrección y limpieza temporal | Ticket revisable; captura eliminada al confirmar/cancelar |
| 5. Servidor y autorización | API, PostgreSQL, administración local y QR | Solo un celular autorizado accede a datos; contratos respetados |
| 6. Sincronización | Recibos, snapshots, versiones y conflictos | Cortes/reintentos no duplican ni pierden datos; pendientes preservados |
| 7. Historial y retención | Consultas de precios/gastos y limpieza de caché | Gráficos correctos, períodos explícitos, PC conserva historia completa |
| 8. Cierre | Pruebas en dispositivos, instalación y recuperación | Uso sin PC, reinicios y restauración verificados |

El orden expresa dependencias principales. No se conectará una pantalla a PostgreSQL para “probarla” antes de tener sus capas.

La conservación voluntaria de fotos requiere cerrar su transferencia y retención antes de habilitar esa opción real. La captura temporal y el registro de datos no dependen de guardar fotos permanentes.

## 6. Pendientes de decisión antes de programar

- Versiones de Java/Spring Boot/PostgreSQL y Flutter/Dart/Android compatibles con las herramientas disponibles en Windows 10.
- Constructor Java, acceso a datos, migraciones y librerías Flutter para estado, SQLite, HTTP, tareas y almacenamiento seguro.
- OCR y escaneo de QR/códigos de barras, incluyendo disponibilidad offline real.
- Administración local de PC y pantallas de autorización.
- Interfaz de resolución de conflictos y contrato de fotos voluntarias.
- Revisión de parámetros técnicos propuestos en decisiones-v2.md.

No se incorporan presupuesto mensual, categorías de gasto nuevas ni repetir compra a esta entrega. La tabla categorias ya existe como catálogo opcional, pero el informe visual por categorías quedó para el futuro.

## 7. Próximo paso concreto

Completar una matriz de herramientas y versiones, contrastarla con el equipo Windows y luego generar los dos proyectos base. En esta entrega solo se documenta la organización; no se inicia el servidor ni se configura la conexión del celular.
