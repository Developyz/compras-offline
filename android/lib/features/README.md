# Vistas de demostración

Inicio, canasta, captura, revisión, historial, detalle de compra, productos, detalle de producto y estados ya están trasladados a Flutter.

Las Views usan datos ficticios de `lib/demo/` y estado local de presentación para filtros, selección y validación simulada. No representan ViewModels de negocio ni escriben datos.

Ya existe una primera base de modelos y reglas de revisión en `lib/domain/`, aún sin integrar. TODO: completar los modelos e incorporar interfaces de repositorios y ViewModels con pruebas antes de conectar SQLite, cámara/OCR o API. La vinculación real por QR también queda pendiente. Las Views no abren conexiones.
