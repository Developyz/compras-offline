# Modelos de dominio

- `valores_compra.dart`: importes exactos PYG y cantidades en milésimas.
- `identidad_y_fecha.dart`: UUID, texto y fecha civil.
- `producto.dart`: catálogo, unidades, contenido y contexto histórico.
- `canasta.dart`: canasta, items y estimación con precios desconocidos.
- `compra.dart`: agregado de compra, detalles y descuentos con validación local.
- `borrador_compra.dart`: entrada parcial para el servicio de revisión.

Sin SQL ni HTTP. Son modelos de dominio, no DTO de API. TODO: repositorios, existencia de referencias, transiciones de estados, versiones y sincronización; incorporar adaptadores y ViewModels antes de guardar/enviar. Ver [alcance y pruebas](../../../../docs/modelos-producto-canasta-compra.md).
