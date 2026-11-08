# Primera base de dominio: revisión de compras

Se incorporan modelos inmutables de entrada para revisar un ticket y un servicio de cálculo en Dart puro. No dependen de Flutter, SQLite, HTTP, cámara ni OCR. Las nueve pantallas mantienen sus datos ficticios y su funcionamiento anterior; todavía no consumen este servicio.

## Archivos y responsabilidades

| Archivo dentro de `android/lib/domain/` | Responsabilidad |
| --- | --- |
| `models/valores_compra.dart` | Importes PYG enteros, cantidades en milésimas y límites int64 |
| `models/borrador_compra.dart` | Borrador de revisión, detalles, descuentos y resumen calculado |
| `services/revision_compra.dart` | Cálculo explícito y lista de incidencias por campo |

Estos modelos son una entrada parcial de revisión, no un DTO OpenAPI ni una compra persistible. Los IDs locales enlazan descuentos con detalles; no se validan como UUID de API en esta capa. No se han implementado aún producto/canasta completos, fecha de compra, comercio/sucursal, contexto histórico, versiones ni estado de sincronización. Deben incorporarse y validarse antes de guardar o enviar una compra.

## Reglas implementadas

- Guaraníes enteros no negativos, con cantidades positivas en milésimas. No se usa `double` para dinero ni cantidades. La lectura textual del dominio es canónica, sin separadores de miles: `1800` y `3.2`. El futuro adaptador de entrada localizará lo escrito por el usuario.
- Los valores y resultados almacenables respetan int64. Los cálculos intermedios usan `BigInt`, evitando desbordamientos incluso en cantidad × precio. Todavía no se serializan a JSON; el futuro adaptador debe conservar enteros exactos conforme al contrato.
- Se conserva el importe bruto leído, aunque difiera de cantidad × precio. `calcularBruto` es una acción explícita independiente, con HALF_UP al guaraní; nunca se llama para reemplazar automáticamente una lectura.
- Subtotal = suma de importes brutos. Los descuentos positivos se agrupan por detalle o como generales. No se cuentan dos veces ni se distribuyen descuentos generales entre productos.
- Los descuentos acumulados por detalle no pueden exceder su importe bruto; los generales no pueden exceder el saldo después de descuentos por producto. Un ajuste no permite saltar estos límites.
- Total calculado = subtotal − descuentos por producto − descuentos generales + ajuste. Un ajuste puede ser positivo o negativo, exige justificación y no puede producir un total negativo.
- Entre 1 y 1000 detalles y hasta 1000 descuentos; IDs no vacíos ni duplicados dentro de cada colección; descripción obligatoria; descuentos referidos solo a detalles existentes en el borrador.
- Para continuar la revisión, debe existir total de ticket, coincidir con el calculado y no quedar campos dudosos. Los borradores pueden mantener esas incidencias y el resumen para corregirlas posteriormente.

Un resultado `puedeContinuar` solo indica que estas comprobaciones de revisión pasaron. **No confirma ni guarda una compra** y no sustituye las futuras validaciones del agregado completo, referencias y servidor. Si la estructura o las cifras son inválidas, el resumen es null; si solo falta revisar campos o el total, el resumen queda disponible.

Los códigos de incidencia y sus campos se separan del texto de pantalla. El futuro ViewModel mostrará mensajes breves, siguiendo la decisión de mantener pocos textos en la app.

## Pruebas

Se añadieron 15 pruebas de dominio: precisión superior a double, límites int64, cantidades fraccionarias, HALF_UP, productos intermedios grandes, conservación de lectura, descuentos combinados y acumulados, referencias, totales ausentes o diferentes, campos dudosos, ajustes, duplicados, límites de listas e inmutabilidad.

Validación: `flutter analyze` sin observaciones y `flutter test` con **25 pruebas aprobadas**: 15 de dominio y 10 de las vistas existentes. No se modifican dependencias, vistas, SQL, API ni servidor. No se repite la compilación nativa: APK y ejecución en celular siguen pendientes, como se explicó en la validación visual.

## Pendiente

Completar los modelos de producto, canasta y compra con fechas, referencias y contexto histórico. Después definir interfaces de repositorios y ViewModels, integrar este servicio en la revisión y probar esa integración. Las implementaciones de SQLite, cámara/OCR, fotos temporales y sincronización siguen pendientes; no hay operaciones que devuelvan un éxito de guardado ficticio.

Referencias: [reglas vigentes v2](api/decisiones-v2.md), [contrato OpenAPI](api/openapi.json) y [vistas Flutter](vistas-flutter.md).
