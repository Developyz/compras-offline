import '../../../presentation/widgets/tema_app.dart';

import 'package:flutter/material.dart';

import '../../../demo/demo_data.dart';
import '../../../presentation/widgets/demo_widgets.dart';
import '../../../presentation/widgets/purchase_widgets.dart';

/// TODO: edición y recuperación local mediante ViewModel/repositorio. No guarda datos.
class CanastaView extends StatelessWidget {
  const CanastaView({super.key});
  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Mi canasta',
    eyebrow: 'Planificá antes de comprar',
    intro: 'Compra de la semana · 3 productos de ejemplo',
    children: [
      for (final line in demoBasketLines) DemoLineTile(line),
      DemoAction(
        'Agregar producto',
        secondary: true,
        icon: Icons.add,
        onPressed: () => pendingDemo(
          context,
          'La edición se incorporará después. Este recorrido no guarda compras.',
        ),
      ),
      const SizedBox(height: 18),
      DemoMoneyRow('Total estimado', guaranies(6400), emphasis: true),
      Text(
        'PYG · Los precios reales pueden variar.',
        style: TextStyle(color: textoSecundario(context), fontSize: 12),
      ),
      const SizedBox(height: 22),
      DemoAction(
        'Revisar compra de ejemplo',
        onPressed: () => Navigator.of(context).pushNamed('/revision'),
      ),
      const SizedBox(height: 10),
      DemoAction(
        'Registrar desde un ticket',
        secondary: true,
        icon: Icons.camera_alt_outlined,
        onPressed: () => Navigator.of(context).pushNamed('/captura'),
      ),
    ],
  );
}
