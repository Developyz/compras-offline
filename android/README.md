# Cliente Android — organización prevista

Este directorio contiene instrucciones de diseño. Todavía no es un proyecto Flutter compilable: no tiene pubspec.yaml, dependencias ni aplicación generada.

Stack confirmado: Flutter, Dart y SQLite. Arquitectura: MVVM con repositorios. Ver [estructura y etapas](../docs/estructura-y-etapas.md).

## Límites de responsabilidad

- Models: datos de productos, compras, canastas y estados; sin conexiones.
- Views: widgets y presentación.
- ViewModels: estado visual y coordinación de acciones.
- Repositorios: acceso a datos locales y transacciones.
- Cliente HTTP: API Spring Boot de la PC, exclusivamente en red local.
- Servicios de cámara/OCR: captura temporal, revisión y eliminación de imagen.
- Servicio de sincronización: cola, recibos, snapshots, conflictos y limpieza segura.

No conectar Android a PostgreSQL. Las credenciales se almacenarán mediante almacenamiento seguro del dispositivo, no en estas instrucciones ni en SQLite.

## Pendiente antes de generar archivos

Elegir versiones y librerías; generar con Flutter; separar implementaciones demo de las reales; adaptar migraciones de DB a la librería seleccionada. Después crear archivos Dart con comentarios TODO específicos conforme al mapa de carpetas.

El [prototipo HTML](../prototipo/README.md) es una referencia visual separada, no código Flutter reutilizable directamente. Los datos demo no deben aparecer como compras reales.

La configuración nativa aparecerá al generar el proyecto; usar android/ como raíz puede producir android/android/ como subdirectorio nativo.
