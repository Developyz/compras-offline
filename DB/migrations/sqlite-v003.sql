-- Recibos locales persistentes. Ejecutar una vez sobre SQLite v2.
-- No representa confirmación del servidor ni elimina datos pendientes.
BEGIN IMMEDIATE;
CREATE TABLE recibos_guardado_local (
 operacion_id TEXT PRIMARY KEY NOT NULL,
 entidad TEXT NOT NULL,
 entidad_id TEXT NOT NULL,
 solicitud_json TEXT NOT NULL,
 creado_en TEXT NOT NULL
);
CREATE INDEX idx_recibos_entidad ON recibos_guardado_local(entidad, entidad_id);
INSERT INTO versiones_esquema VALUES (3,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
COMMIT;
