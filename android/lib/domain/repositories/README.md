# Interfaces de repositorios

`repositorios.dart` declara lectura y escritura con encolado para compras, productos y canastas. La escritura lleva ID de operación y versión base; el recibo solo acredita persistencia local.

ComprasSqlite implementa lectura y creación de compras confirmadas; ver [SQLite](../../../../docs/sqlite-compras-y-cola.md). Productos/canastas todavía no tienen implementación. TODO: conectar el guardado al ViewModel, implementar ediciones/versiones y completar repositorios/paginación de catálogo. No devolver éxito ficticio ni confundir errores con ausencia.

El ViewModel de revisión aún no guarda: prepara una compra en memoria. Ver [alcance y pruebas](../../../../docs/repositorios-y-viewmodel-revision.md).
