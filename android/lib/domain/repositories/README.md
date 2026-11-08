# Interfaces de repositorios

`repositorios.dart` declara lectura y escritura con encolado para compras, productos y canastas. La escritura lleva ID de operación y versión base; el recibo solo acredita persistencia local.

No existen implementaciones todavía. TODO: adaptador SQLite, validación de referencias, transacción entidad + outbox, recibos persistentes, idempotencia, rollback y paginación de catálogo. No devolver éxito ficticio ni confundir errores con ausencia.

El ViewModel de revisión aún no guarda: prepara una compra en memoria. Ver [alcance y pruebas](../../../../docs/repositorios-y-viewmodel-revision.md).
