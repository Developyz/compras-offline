import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../demo/demo_data.dart';
import '../features/canasta/views/canasta_view.dart';
import '../features/compras/views/detalle_compra_view.dart';
import '../features/compras/views/historial_view.dart';
import '../features/inicio/views/inicio_view.dart';
import '../features/productos/views/detalle_producto_view.dart';
import '../features/productos/views/productos_view.dart';
import '../features/sincronizacion/views/estados_view.dart';
import '../features/tickets/views/captura_view.dart';
import '../features/tickets/views/revision_view.dart';
import '../presentation/navigation/demo_scaffold.dart';
import '../presentation/widgets/demo_widgets.dart';

/// Recorrido visual con fixtures. TODO: componer ViewModels y servicios en su fase.
class CanastaApp extends StatelessWidget {
  const CanastaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Canasta',
    debugShowCheckedModeBanner: false,
    locale: const Locale('es', 'PY'),
    supportedLocales: const [Locale('es', 'PY')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: canastaGreen),
      scaffoldBackgroundColor: canastaPaper,
    ),
    onGenerateRoute: (settings) {
      final (tab, page) = switch (settings.name) {
        '/canasta' => (1, const CanastaView()),
        '/captura' => (2, const CapturaView()),
        '/revision' => (2, const RevisionView()),
        '/historial' => (4, const HistorialView()),
        '/productos' => (3, const ProductosView()),
        '/producto' => (
          3,
          DetalleProductoView(
            product: settings.arguments is DemoProduct
                ? settings.arguments! as DemoProduct
                : demoProducts.first,
          ),
        ),
        '/compra' => (
          4,
          DetalleCompraView(
            arguments: settings.arguments is DemoPurchaseArguments
                ? settings.arguments! as DemoPurchaseArguments
                : DemoPurchaseArguments(demoPurchases.first),
          ),
        ),
        '/estados' => (0, const EstadosView()),
        _ => (0, const InicioView()),
      };
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => DemoScaffold(selectedTab: tab, child: page),
      );
    },
  );
}
