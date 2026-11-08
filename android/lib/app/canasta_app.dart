import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../demo/demo_data.dart';
import 'sesion_local.dart';
import '../presentation/widgets/tema_app.dart';
import '../features/inicio/views/inicio_local_view.dart';
import '../features/tickets/views/registro_manual_view.dart';
import '../features/compras/views/compras_locales_view.dart';
import '../features/compras/views/compra_local_view.dart';
import '../domain/models/compra.dart';
import '../features/tickets/views/confirmacion_revision_view.dart';
import '../features/canasta/views/canasta_view.dart';
import '../features/canasta/views/lista_pendiente_view.dart';
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

/// Recorrido con ejemplos y revisión mediante ViewModel. Conexiones pendientes.
class CanastaApp extends StatefulWidget {
  const CanastaApp({this.sesionLocal, super.key});
  final SesionLocal? sesionLocal;
  @override
  State<CanastaApp> createState() => _CanastaAppState();
}

class _CanastaAppState extends State<CanastaApp> {
  ThemeMode modo = ThemeMode.system;
  SesionLocal? get sesionLocal => widget.sesionLocal;
  void alternar() {
    final oscuro =
        modo == ThemeMode.dark ||
        (modo == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    setState(() => modo = oscuro ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) => ControlTema(
    alternar: alternar,
    child: MaterialApp(
      title: 'Canasta',
      navigatorObservers: [rutasInicio],
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'PY'),
      supportedLocales: const [Locale('es', 'PY')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      themeMode: modo,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: canastaLime,
          brightness: Brightness.dark,
          surface: const Color(0xFF18221E),
        ),
        scaffoldBackgroundColor: const Color(0xFF101713),
        dividerColor: const Color(0xFF3C4B43),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: canastaGreen),
        scaffoldBackgroundColor: canastaPaper,
      ),
      onGenerateRoute: (settings) {
        final (tab, page) = switch (settings.name) {
          '/canasta' => (
            1,
            sesionLocal == null
                ? const CanastaView()
                : const ListaPendienteView(),
          ),
          '/captura' => (
            2,
            Builder(
              builder: (context) => CapturaView(
                onRegistrarManual: sesionLocal == null
                    ? null
                    : () => Navigator.of(context).pushNamed('/manual'),
              ),
            ),
          ),
          '/manual' => (
            2,
            sesionLocal == null
                ? const CapturaView()
                : RegistroManualView(sesionLocal!),
          ),
          '/revision' => (
            2,
            settings.arguments is Compra && sesionLocal != null
                ? RevisionView(
                    viewModel: sesionLocal!.revisar(
                      settings.arguments! as Compra,
                    ),
                    disposeViewModel: true,
                  )
                : const RevisionView(),
          ),
          '/historial' => (
            4,
            sesionLocal == null
                ? const HistorialView()
                : ComprasLocalesView(sesionLocal!.compras),
          ),
          '/compra-local' => (
            4,
            settings.arguments is Compra && sesionLocal != null
                ? CompraLocalView(
                    settings.arguments! as Compra,
                    unidades: sesionLocal!.simbolos,
                  )
                : const HistorialView(),
          ),
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
            settings.arguments is Compra
                ? ConfirmacionRevisionView(settings.arguments! as Compra)
                : DetalleCompraView(
                    arguments: settings.arguments is DemoPurchaseArguments
                        ? settings.arguments! as DemoPurchaseArguments
                        : DemoPurchaseArguments(demoPurchases.first),
                  ),
          ),
          '/estados' => (0, const EstadosView()),
          _ => (
            0,
            sesionLocal == null
                ? const InicioView()
                : InicioLocalView(sesionLocal!.compras),
          ),
        };
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => DemoScaffold(selectedTab: tab, child: page),
        );
      },
    ),
  );
}
