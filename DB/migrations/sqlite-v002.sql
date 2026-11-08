-- Migración v1 -> v2. Ejecutar UNA vez después de DB/sqlite.sql.
-- Ejecutar sin transacción abierta; detenerse y hacer ROLLBACK ante cualquier error.
-- foreign_keys debe desactivarse FUERA de BEGIN para reconstruir compras.
PRAGMA foreign_keys = OFF;
BEGIN IMMEDIATE;
CREATE TABLE compras_v2 (
    id TEXT PRIMARY KEY NOT NULL,
    comercio_id TEXT REFERENCES comercios(id),
    sucursal_id TEXT,
    canasta_id TEXT UNIQUE REFERENCES canastas(id),
    fecha_compra TEXT NOT NULL,
    fecha_local TEXT NOT NULL CHECK (length(fecha_local) = 10),
    moneda TEXT NOT NULL CHECK (length(moneda) = 3),
    decimales_moneda INTEGER NOT NULL DEFAULT 0 CHECK (decimales_moneda BETWEEN 0 AND 4),
    estado TEXT NOT NULL DEFAULT 'borrador' CHECK (estado IN ('borrador','confirmada','anulada')),
    subtotal_menor INTEGER NOT NULL CHECK (subtotal_menor >= 0),
    descuento_productos_menor INTEGER NOT NULL DEFAULT 0 CHECK (descuento_productos_menor >= 0),
    descuento_general_menor INTEGER NOT NULL DEFAULT 0 CHECK (descuento_general_menor >= 0),
    ajuste_menor INTEGER NOT NULL DEFAULT 0,
    total_ticket_menor INTEGER CHECK (total_ticket_menor >= 0),
    total_calculado_menor INTEGER NOT NULL CHECK (total_calculado_menor >= 0),
    observaciones TEXT,
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    FOREIGN KEY (sucursal_id, comercio_id) REFERENCES sucursales(id, comercio_id),
    CHECK (sucursal_id IS NULL OR comercio_id IS NOT NULL),
    CHECK (descuento_productos_menor + descuento_general_menor <= subtotal_menor),
    CHECK (total_calculado_menor = subtotal_menor - descuento_productos_menor - descuento_general_menor + ajuste_menor)
);
INSERT INTO compras_v2 (id,comercio_id,sucursal_id,canasta_id,fecha_compra,fecha_local,moneda,decimales_moneda,estado,subtotal_menor,descuento_productos_menor,descuento_general_menor,ajuste_menor,total_ticket_menor,total_calculado_menor,observaciones,version,creado_en,actualizado_en,eliminado_en) SELECT id,comercio_id,sucursal_id,canasta_id,fecha_compra,fecha_local,moneda,decimales_moneda,estado,subtotal_menor,descuento_productos_menor,descuento_general_menor,ajuste_menor,total_ticket_menor,total_calculado_menor,observaciones,version,creado_en,actualizado_en,eliminado_en FROM compras;
DROP TABLE compras;
ALTER TABLE compras_v2 RENAME TO compras;
CREATE INDEX idx_compras_fecha_local ON compras(fecha_local);
CREATE INDEX idx_compras_comercio_id_fecha_compra ON compras(comercio_id,fecha_compra);
CREATE INDEX idx_compras_sucursal_id_comercio_id ON compras(sucursal_id,comercio_id);
ALTER TABLE detalles_compra ADD COLUMN nombre_producto_historico TEXT;
ALTER TABLE detalles_compra ADD COLUMN presentacion_historica TEXT;
ALTER TABLE detalles_compra ADD COLUMN contenido_milesimas_historico INTEGER CHECK (contenido_milesimas_historico > 0);
ALTER TABLE detalles_compra ADD COLUMN unidad_contenido_simbolo_historico TEXT;
ALTER TABLE detalles_compra ADD COLUMN dimension_contenido_historica TEXT CHECK (dimension_contenido_historica IN ('conteo','masa','volumen'));
ALTER TABLE detalles_compra ADD COLUMN factor_base_contenido_historico INTEGER CHECK (factor_base_contenido_historico > 0);
ALTER TABLE detalles_compra ADD COLUMN dimension_cantidad_historica TEXT CHECK (dimension_cantidad_historica IN ('conteo','masa','volumen'));
ALTER TABLE detalles_compra ADD COLUMN factor_base_cantidad_historico INTEGER CHECK (factor_base_cantidad_historico > 0);
-- NULL en filas antiguas significa desconocido: no inventar datos históricos.

CREATE TABLE servidores_confiables (
 id TEXT PRIMARY KEY NOT NULL,
 dispositivo_id TEXT NOT NULL,
 url_base TEXT NOT NULL CHECK (substr(url_base,1,8)='https://'),
 huella_certificado_sha256 TEXT NOT NULL CHECK (length(huella_certificado_sha256)=64),
 alias_credencial_segura TEXT NOT NULL,
 vinculado_en TEXT NOT NULL,
 zona_comercial TEXT,
 activo INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1))
);
-- El alias refiere al almacenamiento seguro de Android; NO contiene el token.
-- Las compras de v1 pertenecen a una sola instalación familiar. No asociarlas a una PC
-- diferente por defecto: confirmar pertenencia y conservar pendientes antes de sincronizar.
ALTER TABLE cola_sincronizacion ADD COLUMN servidor_id TEXT REFERENCES servidores_confiables(id);
ALTER TABLE cola_sincronizacion ADD COLUMN hash_solicitud TEXT CHECK (length(hash_solicitud)=64);
ALTER TABLE cola_sincronizacion ADD COLUMN enviado_en TEXT;
-- NULL en servidor_id es legado/sin vincular y bloquea envío hasta asociación explícita.
CREATE TABLE revisiones_confirmadas (
 servidor_id TEXT NOT NULL REFERENCES servidores_confiables(id),
 entidad TEXT NOT NULL, entidad_id TEXT NOT NULL,
 version_remota INTEGER NOT NULL CHECK (version_remota >= 0),
 ultima_operacion_id TEXT,
 confirmado_en TEXT NOT NULL,
 PRIMARY KEY (servidor_id,entidad,entidad_id)
);
CREATE TABLE descargas_snapshot (
 id TEXT PRIMARY KEY NOT NULL,
 servidor_id TEXT NOT NULL REFERENCES servidores_confiables(id),
 solicitud_id TEXT NOT NULL,
 estado TEXT NOT NULL CHECK (estado IN ('preparando','descargando','verificado','instalado','expirado','error')),
 cursor_corte INTEGER CHECK (cursor_corte >= 0),
 version_esquema INTEGER NOT NULL DEFAULT 2 CHECK (version_esquema=2),
 paginas INTEGER CHECK (paginas >= 0),
 manifiesto_json TEXT,
 creado_en TEXT NOT NULL, expira_en TEXT,
 instalado_en TEXT,
 UNIQUE (servidor_id,solicitud_id),
 CHECK (estado NOT IN ('verificado','instalado') OR (cursor_corte IS NOT NULL AND paginas IS NOT NULL AND manifiesto_json IS NOT NULL)),
 CHECK (estado <> 'instalado' OR instalado_en IS NOT NULL)
);
CREATE TABLE paginas_snapshot_locales (
 snapshot_id TEXT NOT NULL REFERENCES descargas_snapshot(id),
 numero INTEGER NOT NULL CHECK (numero > 0),
 contenido_utf8 BLOB NOT NULL,
 sha256 TEXT NOT NULL CHECK (length(sha256)=64),
 PRIMARY KEY (snapshot_id,numero)
);
CREATE TABLE conflictos_sincronizacion (
 id TEXT PRIMARY KEY NOT NULL,
 servidor_id TEXT NOT NULL REFERENCES servidores_confiables(id),
 entidad TEXT NOT NULL, entidad_id TEXT NOT NULL,
 version_base INTEGER NOT NULL CHECK (version_base >= 0),
 version_remota INTEGER NOT NULL CHECK (version_remota > 0),
 secuencia_remota INTEGER CHECK (secuencia_remota >= 0),
 copia_local_json TEXT NOT NULL, copia_remota_json TEXT NOT NULL,
 estado TEXT NOT NULL CHECK (estado IN ('pendiente','resuelto')),
 creado_en TEXT NOT NULL, resuelto_en TEXT,
 CHECK (estado <> 'resuelto' OR resuelto_en IS NOT NULL)
);
CREATE UNIQUE INDEX idx_conflicto_pendiente ON conflictos_sincronizacion(servidor_id,entidad,entidad_id) WHERE estado='pendiente';
CREATE UNIQUE INDEX idx_servidor_activo_unico ON servidores_confiables(activo) WHERE activo=1;
CREATE INDEX idx_cola_servidor_estado ON cola_sincronizacion(servidor_id,estado);
CREATE INDEX idx_descargas_servidor ON descargas_snapshot(servidor_id,estado);
CREATE TABLE versiones_esquema (
 version INTEGER PRIMARY KEY, aplicado_en TEXT NOT NULL
);
INSERT INTO versiones_esquema VALUES (2,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
-- Abortar si la reconstrucción dejó alguna FK inválida. No ignorar errores.
CREATE TEMP TABLE validar_fk (violaciones INTEGER NOT NULL CHECK (violaciones=0));
INSERT INTO validar_fk SELECT count(*) FROM pragma_foreign_key_check;
DROP TABLE validar_fk;
COMMIT;
PRAGMA foreign_keys = ON;
PRAGMA foreign_key_check;
SELECT id,moneda,decimales_moneda FROM compras WHERE moneda='PYG' AND decimales_moneda<>0;
