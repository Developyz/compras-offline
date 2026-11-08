PRAGMA foreign_keys = ON;
-- Compras Offline: esquema inicial v1. Ejecutar en una base vacía.
-- TEXT generados por la aplicación. Fechas UTC en ISO 8601.
-- Importes: enteros en unidades monetarias menores (escala guardada en compra).
-- Cantidades y contenido: enteros en milésimas de la unidad indicada.
BEGIN;
CREATE TABLE marcas (
    id TEXT PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE categorias (
    id TEXT PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE unidades_medida (
    id TEXT PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL, simbolo TEXT NOT NULL UNIQUE,
    dimension TEXT NOT NULL CHECK (dimension IN ('conteo','masa','volumen')),
    factor_base INTEGER NOT NULL CHECK (factor_base > 0),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE productos (
    id TEXT PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    marca_id TEXT REFERENCES marcas(id),
    categoria_id TEXT REFERENCES categorias(id),
    presentacion TEXT,
    contenido_milesimas INTEGER CHECK (contenido_milesimas > 0),
    unidad_contenido_id TEXT REFERENCES unidades_medida(id),
    tipo_venta TEXT NOT NULL DEFAULT 'unidad' CHECK (tipo_venta IN ('unidad','peso','volumen')),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    CHECK ((contenido_milesimas IS NULL) = (unidad_contenido_id IS NULL))
);

CREATE TABLE codigos_producto (
    id TEXT PRIMARY KEY NOT NULL,
    producto_id TEXT NOT NULL REFERENCES productos(id),
    codigo TEXT NOT NULL UNIQUE CHECK (length(trim(codigo)) > 0),
    formato TEXT,
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE comercios (
    id TEXT PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE sucursales (
    id TEXT PRIMARY KEY NOT NULL,
    comercio_id TEXT NOT NULL REFERENCES comercios(id),
    nombre TEXT NOT NULL, direccion TEXT,
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    UNIQUE (id, comercio_id)
);

CREATE TABLE canastas (
    id TEXT PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'abierta' CHECK (estado IN ('abierta','confirmada','cancelada')),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE items_canasta (
    id TEXT PRIMARY KEY NOT NULL,
    canasta_id TEXT NOT NULL REFERENCES canastas(id),
    producto_id TEXT REFERENCES productos(id),
    descripcion TEXT NOT NULL CHECK (length(trim(descripcion)) > 0),
    cantidad_milesimas INTEGER NOT NULL CHECK (cantidad_milesimas > 0),
    unidad_cantidad_id TEXT NOT NULL REFERENCES unidades_medida(id),
    precio_estimado_menor INTEGER CHECK (precio_estimado_menor >= 0),
    moneda TEXT CHECK (length(moneda) = 3),
    decimales_moneda INTEGER CHECK (decimales_moneda BETWEEN 0 AND 4),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    CHECK (precio_estimado_menor IS NULL OR (moneda IS NOT NULL AND decimales_moneda IS NOT NULL))
);

CREATE TABLE compras (
    id TEXT PRIMARY KEY NOT NULL,
    comercio_id TEXT REFERENCES comercios(id),
    sucursal_id TEXT,
    canasta_id TEXT UNIQUE REFERENCES canastas(id),
    fecha_compra TEXT NOT NULL,
    fecha_local TEXT NOT NULL CHECK (length(fecha_local) = 10),
    moneda TEXT NOT NULL CHECK (length(moneda) = 3),
    decimales_moneda INTEGER NOT NULL DEFAULT 2 CHECK (decimales_moneda BETWEEN 0 AND 4),
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

CREATE TABLE detalles_compra (
    id TEXT PRIMARY KEY NOT NULL,
    compra_id TEXT NOT NULL REFERENCES compras(id),
    producto_id TEXT REFERENCES productos(id),
    numero_linea INTEGER NOT NULL CHECK (numero_linea > 0),
    descripcion_ticket TEXT NOT NULL CHECK (length(trim(descripcion_ticket)) > 0),
    cantidad_milesimas INTEGER NOT NULL CHECK (cantidad_milesimas > 0),
    unidad_cantidad_id TEXT NOT NULL REFERENCES unidades_medida(id),
    precio_unitario_menor INTEGER NOT NULL CHECK (precio_unitario_menor >= 0),
    importe_bruto_menor INTEGER NOT NULL CHECK (importe_bruto_menor >= 0),
    descuento_menor INTEGER NOT NULL DEFAULT 0 CHECK (descuento_menor >= 0),
    importe_final_menor INTEGER NOT NULL CHECK (importe_final_menor >= 0),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    UNIQUE (compra_id, numero_linea), UNIQUE (id, compra_id),
    CHECK (descuento_menor <= importe_bruto_menor),
    CHECK (importe_final_menor = importe_bruto_menor - descuento_menor)
);

CREATE TABLE descuentos_compra (
    id TEXT PRIMARY KEY NOT NULL,
    compra_id TEXT NOT NULL REFERENCES compras(id),
    detalle_compra_id TEXT,
    descripcion TEXT NOT NULL,
    importe_menor INTEGER NOT NULL CHECK (importe_menor > 0),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    FOREIGN KEY (detalle_compra_id, compra_id) REFERENCES detalles_compra(id, compra_id)
);

CREATE TABLE adjuntos_compra (
    id TEXT PRIMARY KEY NOT NULL,
    compra_id TEXT NOT NULL REFERENCES compras(id),
    referencia_archivo TEXT NOT NULL,
    tipo_archivo TEXT NOT NULL CHECK (tipo_archivo IN ('image/jpeg','image/png','image/webp')),
    tamano_bytes INTEGER NOT NULL CHECK (tamano_bytes > 0),
    sha256 TEXT NOT NULL CHECK (length(sha256) = 64),
    origen TEXT NOT NULL DEFAULT 'subida_usuario' CHECK (origen = 'subida_usuario'),
    version INTEGER NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);
CREATE INDEX idx_productos_marca_id ON productos (marca_id);
CREATE INDEX idx_productos_categoria_id ON productos (categoria_id);
CREATE INDEX idx_productos_unidad_contenido_id ON productos (unidad_contenido_id);
CREATE INDEX idx_codigos_producto_producto_id ON codigos_producto (producto_id);
CREATE INDEX idx_sucursales_comercio_id ON sucursales (comercio_id);
CREATE INDEX idx_items_canasta_canasta_id ON items_canasta (canasta_id);
CREATE INDEX idx_items_canasta_producto_id ON items_canasta (producto_id);
CREATE INDEX idx_items_canasta_unidad_cantidad_id ON items_canasta (unidad_cantidad_id);
CREATE INDEX idx_compras_fecha_local ON compras (fecha_local);
CREATE INDEX idx_compras_comercio_id_fecha_compra ON compras (comercio_id, fecha_compra);
CREATE INDEX idx_compras_sucursal_id_comercio_id ON compras (sucursal_id, comercio_id);
CREATE INDEX idx_detalles_compra_producto_id_compra_id ON detalles_compra (producto_id, compra_id);
CREATE INDEX idx_detalles_compra_unidad_cantidad_id ON detalles_compra (unidad_cantidad_id);
CREATE INDEX idx_descuentos_compra_compra_id ON descuentos_compra (compra_id);
CREATE INDEX idx_descuentos_compra_detalle_compra_id_compra_id ON descuentos_compra (detalle_compra_id, compra_id);
CREATE INDEX idx_adjuntos_compra_compra_id ON adjuntos_compra (compra_id);

-- Tablas locales. La app escribe la cola en la misma transacción que los datos.
CREATE TABLE cola_sincronizacion (
 operacion_id TEXT PRIMARY KEY NOT NULL,
 dispositivo_id TEXT NOT NULL,
 entidad TEXT NOT NULL, entidad_id TEXT NOT NULL,
 version_base INTEGER NOT NULL CHECK (version_base >= 0),
 accion TEXT NOT NULL CHECK (accion IN ('guardar','eliminar')),
 datos_json TEXT NOT NULL,
 estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente','enviando','confirmada','error','conflicto')),
 intentos INTEGER NOT NULL DEFAULT 0 CHECK (intentos >= 0),
 creado_en TEXT NOT NULL, proximo_intento_en TEXT, ultimo_error TEXT,
 confirmado_en TEXT
);
CREATE INDEX idx_cola_estado_fecha ON cola_sincronizacion(estado, proximo_intento_en);
CREATE INDEX idx_cola_entidad ON cola_sincronizacion(entidad, entidad_id);
CREATE TABLE estado_sincronizacion (
 servidor_id TEXT PRIMARY KEY NOT NULL,
 dispositivo_id TEXT NOT NULL,
 ultima_secuencia INTEGER NOT NULL DEFAULT 0 CHECK (ultima_secuencia >= 0),
 ultima_sincronizacion_en TEXT
);
COMMIT;
