# Vistas y ViewModels

Carga manual, revisión, guardado y listado/detalle local ya usan el dominio y SQLite. El ViewModel depende de RepositorioCompras; conserva una solicitud por reintento, informa progreso/error y acepta solo el recibo correspondiente. No importa Drift ni navega.

Inicio, Canasta, Productos y Estados conservan su demostración. Los tickets de ejemplo no escriben datos. Las Views de datos reales ocultan los avisos ficticios y usan textos breves.

La View libera sus listeners y su ViewModel propio, incluido el creado por la composición de rutas. La sesión pertenece al arranque y controla la base.

TODO: gastos reales en Inicio, catálogo/canasta, edición, cámara/OCR y sincronización. Las Views no abren conexiones SQL ni HTTP.
