import 'package:flutter/material.dart';

import '../../../demo/demo_data.dart';
import '../../../presentation/widgets/demo_widgets.dart';
import '../../../presentation/widgets/purchase_widgets.dart';

/// TODO: obtener resumen local y disponibilidad desde un ViewModel. Solo fixtures.
class InicioView extends StatelessWidget {
  const InicioView({super.key});
  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Cada compra cuenta.',
    eyebrow: 'Tu día a día, en orden',
    intro: 'Conocé tus gastos y prepará tu próxima canasta.',
    children: [
      const SpendingCard(),
      const SizedBox(height: 18),
      DemoAction(
        'Ver mi canasta',
        icon: Icons.shopping_bag_outlined,
        onPressed: () => Navigator.of(context).pushNamed('/canasta'),
      ),
      const DemoSection('Tu canasta en curso'),
      DemoCard(
        onTap: () => Navigator.of(context).pushNamed('/canasta'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compra de la semana',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Text(
              '3 productos · Estimación',
              style: TextStyle(color: canastaMuted, fontSize: 12),
            ),
            DemoMoneyRow('Total estimado', guaranies(6400), emphasis: true),
          ],
        ),
      ),
      const DemoSection('Última compra'),
      DemoPurchaseTile(demoPurchases.first),
      TextButton(
        onPressed: () => Navigator.of(context).pushNamed('/historial'),
        child: const Text('Ver historial'),
      ),
      const SizedBox(height: 10),
      const DemoNotice(
        'Ejemplo: 1 compra pendiente. Se enviará cuando tu PC esté disponible.',
      ),
      const SizedBox(height: 14),
      DemoAction(
        'Ver estados de compras',
        secondary: true,
        icon: Icons.sync_outlined,
        onPressed: () => Navigator.of(context).pushNamed('/estados'),
      ),
    ],
  );
}
