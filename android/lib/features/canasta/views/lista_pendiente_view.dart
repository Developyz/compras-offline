import 'package:flutter/material.dart';

import '../../../presentation/widgets/demo_widgets.dart';

/// La canasta aún no tiene persistencia. No mostrar productos ficticios como propios.
class ListaPendienteView extends StatelessWidget {
  const ListaPendienteView({super.key});
  @override
  Widget build(BuildContext context) => DemoPage(
    mostrarAvisoDemo: false,
    title: 'Mi lista de compras',
    eyebrow: 'Para tu próxima compra',
    children: [
      const DemoNotice('Esta función todavía está en preparación.'),
      const SizedBox(height: 16),
      const Text('Las compras que ya hiciste están en Historial.'),
      const SizedBox(height: 20),
      DemoAction(
        'Ver compras guardadas',
        onPressed: () => Navigator.of(context).pushNamed('/historial'),
      ),
    ],
  );
}
