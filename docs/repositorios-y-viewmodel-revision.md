> Etapa anterior. El guardado ya está conectado al formulario/revisión y al historial local: [estado actual](guardado-local-en-pantalla.md). SQLite usa esquema v4 con identidad persistente.

> Actualización: ya existe un [adaptador SQLite de compras](sqlite-compras-y-cola.md) con dependencias resueltas y pruebas. El guardado en pantalla sigue pendiente. El resto de este documento conserva su etapa de referencia.

# Repositorios y ViewModel de revisión

La pantalla de revisión ya utiliza las reglas de dominio mediante `RevisionTicketViewModel`. Sigue mostrando datos de ejemplo; no hay persistencia, cámara, OCR ni conexión con la PC.

## Separación implementada

```text
RevisionView → RevisionTicketViewModel → Compra / RevisionCompra
                    ↓
             Compra para vista previa
```

- La View presenta los datos y comunica acciones. Ya no calcula la habilitación de confirmación con booleanos propios.
- El ViewModel expone el borrador, campos pendientes, coincidencia del total y disponibilidad para continuar. Las modificaciones reconstruyen el agregado y vuelven a ejecutar sus reglas.
- El dominio conserva importes, descuentos, referencias y contexto histórico. El ViewModel no conoce los ejemplos ni navega.
- `lib/demo/revision_demo.dart` construye los tres escenarios ficticios. El selector de escenarios pertenece exclusivamente a la demostración.

Se usa `ChangeNotifier` del SDK Flutter, sin agregar dependencias. La View libera el ViewModel que crea; cuando recibe uno externo, solo retira su listener. También desprende correctamente el anterior si se reemplaza.

## Operaciones del ViewModel

| Operación | Resultado |
| --- | --- |
| `cargarBorrador` | Sustituye el ticket y sus comprobaciones; solo acepta estado borrador |
| `marcarCampoRevisado` | Retira una incertidumbre existente tras la acción explícita |
| `actualizarTotalTicket` | Cambia o deja pendiente el total leído y revalida |
| `prepararConfirmacion` | Exige revisión completa y devuelve una compra confirmada **en memoria**, sin escritura |

No se corrigen importes al abrir o confirmar. Corregir el total de la demostración es una acción explícita y usa el resumen del dominio. El borrador original es inmutable. Preparar la vista previa no agrega compras al historial ni genera una operación de sincronización.

La vista previa recibe el agregado preparado por el ViewModel y muestra sus detalles y totales, sin volver a sustituirlos por un fixture. Las rutas de historial y sus tres compras de demostración se conservan. La ruta `/compra` distingue argumentos de demostración históricos y una compra preparada para revisión.

Los widgets de compra formatean `BigInt` directamente, sin convertir importes a double. Las cantidades se muestran con coma decimal y hasta tres posiciones, sin inventar decimales monetarios. La edición completa de productos/cantidades y la resolución general de incidencias quedan pendientes; los botones actuales de revisión de campos son los del escenario ilustrativo.

## Interfaces de repositorios

`lib/domain/repositories/repositorios.dart` define:

- `RepositorioCompras`: lectura por ID y guardado con encolado.
- `RepositorioProductos`: lectura por ID, búsqueda acotada y guardado con encolado.
- `RepositorioCanastas`: lectura por ID y guardado con encolado.
- `EscrituraLocal<T>`: entidad, UUID de operación y versión base int64 no negativa.
- `ReciboGuardadoLocal`: IDs de entidad y operación; representa confirmación local, no recepción de la PC.

Son **contratos sin implementaciones**. Ninguno devuelve listas vacías o éxito para ocultar una conexión pendiente. El ViewModel de revisión todavía no llama a estos contratos: se incorporará el comando de guardado al implementar la persistencia transaccional.

La futura implementación debe verificar referencias, confirmar entidad y outbox de forma atómica, persistir el recibo, conservar el ID/contenido en reintentos y rechazar reutilización del mismo ID con contenido distinto. Un error se propaga; null significa ausencia comprobada. La búsqueda deberá validar su límite y definir paginación antes de usarse con catálogos grandes. No se ejecuta ni se comprueba todavía ninguna de estas garantías de almacenamiento.

## Verificación

Se añadieron 12 pruebas de ViewModel, formato e integración. Se prueban incertidumbres independientes, total ausente/diferente, recarga sin arrastrar comprobaciones, conservación del original y contexto, metadatos, descuentos y versión exacta. Las pruebas de widgets usan un total distinto (₲ 9.137) para comprobar que la vista y la confirmación realmente reciben datos del ViewModel. También se verifica reemplazo/liberación y la vista previa a 320 × 568 con texto al 200 %.

`flutter test`: **51 pruebas aprobadas** (39 anteriores + 12 nuevas). `flutter analyze`: sin observaciones. `flutter build bundle --debug`: compilación Dart aprobada. No se modifican dependencias, SQL ni servidor. APK y ejecución en Android real siguen pendientes.

## Pendiente

Implementar el adaptador SQLite y sus pruebas de transacción/rollback, recibos y cola antes de habilitar un guardado real desde pantalla. Después incorporar el comando de guardado en el ViewModel, con estados de progreso/error y prevención de duplicados. La API, sincronización por la misma red local, OCR y política de fotos temporales siguen pendientes de implementación.

La decisión visual se mantiene: pocos textos en la versión final; retirar etiquetas y explicaciones de demostración al habilitar funciones reales.
