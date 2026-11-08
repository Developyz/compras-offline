# Adaptadores de repositorios

`compras_sqlite.dart` implementa lectura de compras y creación de compras confirmadas con versión base cero. Compra, hijos, cola y recibo se guardan en una transacción. Los reintentos idénticos no duplican; los errores no se convierten en éxito ni en listas vacías.

Aún no se conecta al ViewModel. TODO: ediciones/versiones, productos/canastas, coordinación de guardado en pantalla y envío real. No eliminar pendientes ni conflictos. Ver [alcance y pruebas](../../../../docs/sqlite-compras-y-cola.md).
