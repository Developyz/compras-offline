-- Identidad no secreta de instalación. No contiene token ni servidor asignado.
BEGIN IMMEDIATE;
CREATE TABLE metadatos_locales (
 clave TEXT PRIMARY KEY NOT NULL,
 valor TEXT NOT NULL
);
INSERT INTO versiones_esquema VALUES (4,strftime('%Y-%m-%dT%H:%M:%fZ','now'));
COMMIT;
