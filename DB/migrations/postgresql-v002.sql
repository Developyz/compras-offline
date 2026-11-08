-- Migración v1 -> v2. Ejecutar UNA vez después de DB/postgresql.sql.
-- Solo estructura. No convierte importes, no abre puertos ni crea credenciales.
BEGIN;
ALTER TABLE compras ALTER COLUMN decimales_moneda SET DEFAULT 0;
ALTER TABLE detalles_compra ADD COLUMN nombre_producto_historico TEXT;
ALTER TABLE detalles_compra ADD COLUMN presentacion_historica TEXT;
ALTER TABLE detalles_compra ADD COLUMN contenido_milesimas_historico BIGINT CHECK (contenido_milesimas_historico > 0);
ALTER TABLE detalles_compra ADD COLUMN unidad_contenido_simbolo_historico TEXT;
ALTER TABLE detalles_compra ADD COLUMN dimension_contenido_historica TEXT CHECK (dimension_contenido_historica IN ('conteo','masa','volumen'));
ALTER TABLE detalles_compra ADD COLUMN factor_base_contenido_historico BIGINT CHECK (factor_base_contenido_historico > 0);
ALTER TABLE detalles_compra ADD COLUMN dimension_cantidad_historica TEXT CHECK (dimension_cantidad_historica IN ('conteo','masa','volumen'));
ALTER TABLE detalles_compra ADD COLUMN factor_base_cantidad_historico BIGINT CHECK (factor_base_cantidad_historico > 0);
-- NULL en filas antiguas significa desconocido: no inventar datos históricos.

CREATE TABLE configuracion_servidor (
 id UUID PRIMARY KEY NOT NULL,
 singleton INTEGER NOT NULL DEFAULT 1 UNIQUE CHECK (singleton=1),
 zona_comercial TEXT NOT NULL,
 version_esquema INTEGER NOT NULL DEFAULT 2 CHECK (version_esquema=2),
 creado_en TEXT NOT NULL
);
CREATE TABLE sesiones_vinculacion (
 id UUID PRIMARY KEY NOT NULL,
 secreto_hash TEXT NOT NULL UNIQUE CHECK (length(secreto_hash)=64),
 estado TEXT NOT NULL CHECK (estado IN ('disponible','consumida','cancelada','expirada')),
 creado_en TEXT NOT NULL, expira_en TEXT NOT NULL,
 CHECK (expira_en > creado_en)
);
CREATE TABLE solicitudes_vinculacion (
 id UUID PRIMARY KEY NOT NULL,
 sesion_id UUID NOT NULL UNIQUE REFERENCES sesiones_vinculacion(id),
 dispositivo_id UUID NOT NULL,
 nombre_dispositivo TEXT NOT NULL,
 hash_solicitud TEXT NOT NULL CHECK (length(hash_solicitud)=64),
 token_consulta_hash TEXT NOT NULL UNIQUE CHECK (length(token_consulta_hash)=64),
 token_consulta_cifrado BYTEA NOT NULL,
 estado TEXT NOT NULL CHECK (estado IN ('pendiente_autorizacion','autorizada','rechazada','expirada','confirmada')),
 creado_en TEXT NOT NULL, expira_en TEXT NOT NULL,
 decidido_en TEXT,
 CHECK (expira_en > creado_en)
);
-- dispositivo_id en la solicitud es una identidad candidata, no una autorización.
-- Crear el dispositivo autorizado y su credencial en la misma transacción de aprobación.
CREATE TABLE credenciales_dispositivo (
 id UUID PRIMARY KEY NOT NULL,
 dispositivo_id UUID NOT NULL REFERENCES dispositivos(id),
 token_hash TEXT NOT NULL UNIQUE CHECK (length(token_hash)=64),
 estado TEXT NOT NULL CHECK (estado IN ('provisional','activa','revocada','expirada')),
 creado_en TEXT NOT NULL, expira_en TEXT NOT NULL,
 confirmado_en TEXT, revocado_en TEXT,
 CHECK (expira_en > creado_en),
 CHECK (estado <> 'activa' OR confirmado_en IS NOT NULL)
);
CREATE TABLE entregas_vinculacion (
 solicitud_id UUID PRIMARY KEY NOT NULL REFERENCES solicitudes_vinculacion(id),
 credencial_id UUID NOT NULL UNIQUE REFERENCES credenciales_dispositivo(id),
 entrega_cifrada BYTEA NOT NULL,
 creado_en TEXT NOT NULL, expira_en TEXT NOT NULL,
 CHECK (expira_en > creado_en)
);
-- Los BYTEA cifrados son sobres AEAD versionados (incluyen nonce/tag/key_id).
-- La clave vive fuera de PostgreSQL y Git. El servicio elimina entregas al confirmar/expirar.
CREATE TABLE snapshots_sincronizacion (
 id UUID PRIMARY KEY NOT NULL,
 servidor_id UUID NOT NULL REFERENCES configuracion_servidor(id),
 dispositivo_id UUID NOT NULL REFERENCES dispositivos(id),
 solicitud_id UUID NOT NULL,
 parametros_hash TEXT NOT NULL CHECK (length(parametros_hash)=64),
 estado TEXT NOT NULL CHECK (estado IN ('preparando','listo','fallido','expirado')),
 cursor_corte BIGINT CHECK (cursor_corte >= 0),
 version_esquema INTEGER NOT NULL DEFAULT 2 CHECK (version_esquema=2),
 fecha_referencia TEXT NOT NULL,
 desde_inclusive TEXT NOT NULL, hasta_exclusive TEXT NOT NULL,
 zona_comercial TEXT NOT NULL,
 paginas INTEGER CHECK (paginas >= 0),
 manifiesto_json JSONB,
 creado_en TEXT NOT NULL, expira_en TEXT NOT NULL,
 UNIQUE (dispositivo_id, solicitud_id),
 CHECK (hasta_exclusive > desde_inclusive),
 CHECK (expira_en > creado_en),
 CHECK (estado <> 'listo' OR (cursor_corte IS NOT NULL AND paginas IS NOT NULL AND manifiesto_json IS NOT NULL))
);
CREATE TABLE paginas_snapshot (
 snapshot_id UUID NOT NULL REFERENCES snapshots_sincronizacion(id),
 numero INTEGER NOT NULL CHECK (numero > 0),
 contenido_utf8 BYTEA NOT NULL,
 sha256 TEXT NOT NULL CHECK (length(sha256)=64),
 PRIMARY KEY (snapshot_id, numero)
);
CREATE INDEX idx_sesiones_expiracion ON sesiones_vinculacion(expira_en);
CREATE INDEX idx_solicitudes_estado ON solicitudes_vinculacion(estado, expira_en);
CREATE INDEX idx_credenciales_dispositivo ON credenciales_dispositivo(dispositivo_id, estado);
CREATE UNIQUE INDEX idx_credencial_activa_unica ON credenciales_dispositivo(dispositivo_id) WHERE estado='activa';
CREATE INDEX idx_snapshots_retencion ON snapshots_sincronizacion(estado, expira_en, cursor_corte);
CREATE TABLE versiones_esquema (
 version INTEGER PRIMARY KEY, aplicado_en TEXT NOT NULL
);
INSERT INTO versiones_esquema VALUES (2, to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'));
COMMIT;
-- Auditoría: revisar antes de usar datos antiguos PYG con escala distinta de cero.
SELECT id, moneda, decimales_moneda FROM compras WHERE moneda='PYG' AND decimales_moneda<>0;
