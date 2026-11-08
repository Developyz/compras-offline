# SQLite local

`base_local.dart` abre Drift/SQLite en memoria, archivo o directorio privado; instala el esquema consolidado v4 y migra bases Drift v2/v3. SesionLocal conserva identidad y prepara las unidades compartidas. `compra_codec.dart` conserva enteros exactos, contexto histórico y resúmenes.

El asset procede de los SQL oficiales mediante `android/tool/generar_esquema_sqlite.py`. No ejecutar los scripts manuales con BEGIN/COMMIT dentro de Drift. Una base manual sin versión no se recrea ni se adopta automáticamente.

TODO: migraciones adicionales, retención segura y prueba de apertura privada/ABI en Android real. Ver [alcance y pruebas](../../../../docs/sqlite-compras-y-cola.md).
