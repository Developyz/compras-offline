import 'compra.dart';

/// Importes agregados exactos: pueden superar int64 aunque cada compra no lo haga.
final class ResumenInicio {
  ResumenInicio({
    required this.totalMes,
    required this.totalLocal,
    required this.comprasMes,
    required this.comprasLocales,
    required List<Compra> ultimas,
  }) : ultimas = List.unmodifiable(ultimas);
  final BigInt totalMes;
  final BigInt totalLocal;
  final int comprasMes;
  final int comprasLocales;
  final List<Compra> ultimas;
}
