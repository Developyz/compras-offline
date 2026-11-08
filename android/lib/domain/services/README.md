# Reglas de dominio

`revision_compra.dart` valida borradores de revisión y calcula importes en Dart puro. Conserva el importe leído, separa descuentos y devuelve incidencias por campo. El cálculo explícito usa HALF_UP; no guarda ni confirma compras.

TODO: completar validaciones del agregado, contexto histórico y comparación de unidades. Integrar con futuros ViewModels y repositorios. Sin widgets ni conexiones. Ver [alcance y pruebas](../../../../docs/modelos-y-revision-compra.md).
