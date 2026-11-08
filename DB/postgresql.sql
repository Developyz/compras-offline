-- Compras Offline: esquema inicial v1. Ejecutar en una base vacía.
-- UUID generados por la aplicación. Fechas UTC en ISO 8601.
-- Importes: enteros en unidades monetarias menores (escala guardada en compra).
-- Cantidades y contenido: enteros en milésimas de la unidad indicada.
BEGIN;
CREATE TABLE marcas (
    id UUID PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE categorias (
    id UUID PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE unidades_medida (
    id UUID PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL, simbolo TEXT NOT NULL UNIQUE,
    dimension TEXT NOT NULL CHECK (dimension IN ('conteo','masa','volumen')),
    factor_base BIGINT NOT NULL CHECK (factor_base > 0),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE productos (
    id UUID PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    marca_id UUID REFERENCES marcas(id),
    categoria_id UUID REFERENCES categorias(id),
    presentacion TEXT,
    contenido_milesimas BIGINT CHECK (contenido_milesimas > 0),
    unidad_contenido_id UUID REFERENCES unidades_medida(id),
    tipo_venta TEXT NOT NULL DEFAULT 'unidad' CHECK (tipo_venta IN ('unidad','peso','volumen')),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    CHECK ((contenido_milesimas IS NULL) = (unidad_contenido_id IS NULL))
);

CREATE TABLE codigos_producto (
    id UUID PRIMARY KEY NOT NULL,
    producto_id UUID NOT NULL REFERENCES productos(id),
    codigo TEXT NOT NULL UNIQUE CHECK (length(trim(codigo)) > 0),
    formato TEXT,
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE comercios (
    id UUID PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL CHECK (length(trim(nombre)) > 0),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE sucursales (
    id UUID PRIMARY KEY NOT NULL,
    comercio_id UUID NOT NULL REFERENCES comercios(id),
    nombre TEXT NOT NULL, direccion TEXT,
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    UNIQUE (id, comercio_id)
);

CREATE TABLE canastas (
    id UUID PRIMARY KEY NOT NULL,
    nombre TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'abierta' CHECK (estado IN ('abierta','confirmada','cancelada')),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT
);

CREATE TABLE items_canasta (
    id UUID PRIMARY KEY NOT NULL,
    canasta_id UUID NOT NULL REFERENCES canastas(id),
    producto_id UUID REFERENCES productos(id),
    descripcion TEXT NOT NULL CHECK (length(trim(descripcion)) > 0),
    cantidad_milesimas BIGINT NOT NULL CHECK (cantidad_milesimas > 0),
    unidad_cantidad_id UUID NOT NULL REFERENCES unidades_medida(id),
    precio_estimado_menor BIGINT CHECK (precio_estimado_menor >= 0),
    moneda TEXT CHECK (length(moneda) = 3),
    decimales_moneda INTEGER CHECK (decimales_moneda BETWEEN 0 AND 4),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    CHECK (precio_estimado_menor IS NULL OR (moneda IS NOT NULL AND decimales_moneda IS NOT NULL))
);

CREATE TABLE compras (
    id UUID PRIMARY KEY NOT NULL,
    comercio_id UUID REFERENCES comercios(id),
    sucursal_id UUID,
    canasta_id UUID UNIQUE REFERENCES canastas(id),
    fecha_compra TEXT NOT NULL,
    fecha_local TEXT NOT NULL CHECK (length(fecha_local) = 10),
    moneda TEXT NOT NULL CHECK (length(moneda) = 3),
    decimales_moneda INTEGER NOT NULL DEFAULT 2 CHECK (decimales_moneda BETWEEN 0 AND 4),
    estado TEXT NOT NULL DEFAULT 'borrador' CHECK (estado IN ('borrador','confirmada','anulada')),
    subtotal_menor BIGINT NOT NULL CHECK (subtotal_menor >= 0),
    descuento_productos_menor BIGINT NOT NULL DEFAULT 0 CHECK (descuento_productos_menor >= 0),
    descuento_general_menor BIGINT NOT NULL DEFAULT 0 CHECK (descuento_general_menor >= 0),
    ajuste_menor BIGINT NOT NULL DEFAULT 0,
    total_ticket_menor BIGINT CHECK (total_ticket_menor >= 0),
    total_calculado_menor BIGINT NOT NULL CHECK (total_calculado_menor >= 0),
    observaciones TEXT,
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    FOREIGN KEY (sucursal_id, comercio_id) REFERENCES sucursales(id, comercio_id),
    CHECK (sucursal_id IS NULL OR comercio_id IS NOT NULL),
    CHECK (descuento_productos_menor + descuento_general_menor <= subtotal_menor),
    CHECK (total_calculado_menor = subtotal_menor - descuento_productos_menor - descuento_general_menor + ajuste_menor)
);

CREATE TABLE detalles_compra (
    id UUID PRIMARY KEY NOT NULL,
    compra_id UUID NOT NULL REFERENCES compras(id),
    producto_id UUID REFERENCES productos(id),
    numero_linea INTEGER NOT NULL CHECK (numero_linea > 0),
    descripcion_ticket TEXT NOT NULL CHECK (length(trim(descripcion_ticket)) > 0),
    cantidad_milesimas BIGINT NOT NULL CHECK (cantidad_milesimas > 0),
    unidad_cantidad_id UUID NOT NULL REFERENCES unidades_medida(id),
    precio_unitario_menor BIGINT NOT NULL CHECK (precio_unitario_menor >= 0),
    importe_bruto_menor BIGINT NOT NULL CHECK (importe_bruto_menor >= 0),
    descuento_menor BIGINT NOT NULL DEFAULT 0 CHECK (descuento_menor >= 0),
    importe_final_menor BIGINT NOT NULL CHECK (importe_final_menor >= 0),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    UNIQUE (compra_id, numero_linea), UNIQUE (id, compra_id),
    CHECK (descuento_menor <= importe_bruto_menor),
    CHECK (importe_final_menor = importe_bruto_menor - descuento_menor)
);

CREATE TABLE descuentos_compra (
    id UUID PRIMARY KEY NOT NULL,
    compra_id UUID NOT NULL REFERENCES compras(id),
    detalle_compra_id UUID,
    descripcion TEXT NOT NULL,
    importe_menor BIGINT NOT NULL CHECK (importe_menor > 0),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
    creado_en TEXT NOT NULL,
    actualizado_en TEXT NOT NULL,
    eliminado_en TEXT,
    FOREIGN KEY (detalle_compra_id, compra_id) REFERENCES detalles_compra(id, compra_id)
);

CREATE TABLE adjuntos_compra (
    id UUID PRIMARY KEY NOT NULL,
    compra_id UUID NOT NULL REFERENCES compras(id),
    referencia_archivo TEXT NOT NULL,
    tipo_archivo TEXT NOT NULL CHECK (tipo_archivo IN ('image/jpeg','image/png','image/webp')),
    tamano_bytes BIGINT NOT NULL CHECK (tamano_bytes > 0),
    sha256 TEXT NOT NULL CHECK (length(sha256) = 64),
    origen TEXT NOT NULL DEFAULT 'subida_usuario' CHECK (origen = 'subida_usuario'),
    version BIGINT NOT NULL DEFAULT 1 CHECK (version > 0),
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

-- Tablas del servidor. La API escribe estas tablas dentro de la transacción de negocio.
CREATE TABLE dispositivos (
 id UUID PRIMARY KEY NOT NULL, nombre TEXT NOT NULL,
 registrado_en TEXT NOT NULL, ultimo_contacto_en TEXT, revocado_en TEXT
);
CREATE TABLE operaciones_recibidas (
 operacion_id UUID PRIMARY KEY NOT NULL,
 dispositivo_id UUID NOT NULL REFERENCES dispositivos(id),
 hash_solicitud TEXT NOT NULL CHECK (length(hash_solicitud)=64),
 resultado_json JSONB NOT NULL, recibida_en TEXT NOT NULL
);
CREATE TABLE cambios_sincronizacion (
 secuencia BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 entidad TEXT NOT NULL, entidad_id UUID NOT NULL,
 version BIGINT NOT NULL CHECK (version > 0),
 accion TEXT NOT NULL CHECK (accion IN ('guardar','eliminar')),
 datos_json JSONB NOT NULL, creado_en TEXT NOT NULL,
 UNIQUE (entidad, entidad_id, version)
);
CREATE INDEX idx_operaciones_dispositivo ON operaciones_recibidas(dispositivo_id);
CREATE INDEX idx_cambios_entidad ON cambios_sincronizacion(entidad, entidad_id);
COMMIT;
