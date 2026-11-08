# Adaptadores de repositorios

`compras_sqlite.dart` implementa lectura de compras y creación de compras confirmadas con versión base cero. Compra, hijos, cola y recibo se guardan en una transacción. Los reintentos idénticos no duplican; los errores no se convierten en éxito ni en listas vacías.

Ya se conecta al ViewModel para compras manuales; lista hasta 100 compras locales. TODO: ediciones/versiones, productos/canastas, paginación y envío real. No eliminar pendientes ni conflictos. Ver [alcance y pruebas](../../../../docs/sqlite-compras-y-cola.md).
