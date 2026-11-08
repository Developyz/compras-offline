import 'package:flutter/material.dart';

import '../widgets/demo_widgets.dart';
import '../widgets/tema_app.dart';

/// Navegación de presentación. No representa sincronización ni ViewModels de negocio.
class DemoScaffold extends StatelessWidget {
  const DemoScaffold({
    super.key,
    required this.child,
    required this.selectedTab,
  });
  final Widget child;
  final int selectedTab;
  static const destinations = [
    '/',
    '/canasta',
    '/captura',
    '/productos',
    '/historial',
  ];
  static const labels = [
    'Inicio',
    'Canasta',
    'Cámara',
    'Productos',
    'Historial',
  ];
  static const icons = [
    Icons.home_outlined,
    Icons.shopping_bag_outlined,
    Icons.camera_alt_outlined,
    Icons.inventory_2_outlined,
    Icons.receipt_long_outlined,
  ];

  void _navigate(BuildContext context, int index) {
    final destination = destinations[index];
    if (ModalRoute.of(context)?.settings.name == destination) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(destination, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: fondoApp(context),
      surfaceTintColor: Colors.transparent,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'canasta.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textoVerde(context),
          ),
        ),
      ),
      actions: [
        if (ControlTema.of(context) != null)
          IconButton(
            key: const ValueKey('alternar-tema'),
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Modo claro'
                : 'Modo oscuro',
            onPressed: ControlTema.of(context)!.alternar,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        IconButton(
          tooltip: 'Ver estados de ejemplo',
          onPressed: () => Navigator.of(context).pushNamed('/estados'),
          icon: Icon(Icons.sync_outlined, color: textoVerde(context)),
        ),
      ],
    ),
    body: child,
    bottomNavigationBar: DecoratedBox(
      decoration: BoxDecoration(
        color: fondoApp(context),
        border: Border(top: BorderSide(color: bordeApp(context))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (index) {
              final camera = index == 2;
              final selected = selectedTab == index;
              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: camera
                      ? 'Cámara: capturar ticket de ejemplo'
                      : labels[index],
                  child: ExcludeSemantics(
                    child: InkWell(
                      key: ValueKey('nav-${destinations[index]}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _navigate(context, index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: camera ? 54 : 42,
                              height: camera ? 54 : 36,
                              decoration: BoxDecoration(
                                color: camera
                                    ? (selected ? canastaLime : canastaGreen)
                                    : (selected
                                          ? suaveApp(context)
                                          : Colors.transparent),
                                borderRadius: BorderRadius.circular(
                                  camera ? 30 : 12,
                                ),
                              ),
                              child: Icon(
                                icons[index],
                                size: camera ? 28 : 23,
                                color: camera
                                    ? (selected ? canastaGreen : canastaLime)
                                    : (selected
                                          ? textoVerde(context)
                                          : textoSecundario(context)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labels[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? textoVerde(context)
                                    : textoSecundario(context),
                                fontWeight: selected || camera
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ),
  );
}
