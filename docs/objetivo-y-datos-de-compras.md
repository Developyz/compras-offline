# Objetivo y datos de compras

## Objetivo confirmado

Ayudar al usuario a organizar sus compras y los datos de sus productos, comparar precios en el futuro y armar una mejor canasta familiar. El registro debe permitir entender cuánto gasta, en qué productos y cómo evoluciona su gasto diario y mensual.

Este objetivo orienta el diseño de datos. No implica que todos los informes y comparaciones estén implementados en la primera versión.

## Datos confirmados del ticket

- Compra y fecha de la compra.
- Productos comprados.
- Cantidades.
- Precios.
- Descuentos, cuando existan.
- Total de la compra con los descuentos aplicados.

La lectura automática deberá permitir revisar y corregir estos datos antes de confirmar, conforme a registro-de-tickets.md.

## Propuestas de modelado pendientes de validar

- Guardar el comercio para comparar compras entre lugares.
- Distinguir precio unitario e importe de cada renglón.
- Distinguir descuentos por producto y descuentos sobre la compra completa, evitando descontarlos dos veces.
- Registrar moneda y usar importes decimales exactos.
- Conservar la descripción original del ticket y vincularla con un producto del catálogo para reconocer el mismo producto entre compras.
- Registrar marca, presentación, contenido y unidad de medida cuando se conozcan, para comparar precios por unidad, kilogramo o litro de forma consistente.
- Diferenciar el total leído del ticket del total calculado; señalar diferencias para revisión sin modificar silenciosamente los importes.

## Aspectos pendientes

- Confirmar los campos adicionales y el tratamiento de descuentos.
- Definir cómo se identifica y organiza un producto, incluyendo productos vendidos por peso.
- Definir informes diarios y mensuales y el acceso al historial completo desde el celular cuando la PC esté disponible.
- Resolver cómo mostrar meses completos y comparaciones cuando el celular solo conserva 30 días, sin asumir acceso al historial completo durante el uso sin conexión.
- Definir si habrá presupuesto mensual y categorías de gastos; todavía no son requisitos confirmados.
