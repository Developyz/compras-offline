import 'package:flutter/material.dart';

import '../../../demo/demo_data.dart';
import '../../../presentation/widgets/demo_widgets.dart';
import '../../../presentation/widgets/purchase_widgets.dart';

/// TODO: historial paginado de SQLite, distinguiendo caché y consulta completa en PC.
class HistorialView extends StatelessWidget {
  const HistorialView({super.key});
  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Historial',
    eyebrow: 'Tus compras, organizadas',
    intro: 'Últimos 30 días · Datos de ejemplo',
    children: [
      const SpendingCard(),
      const DemoSection('Noviembre 2026'),
      for (final purchase in demoPurchases) DemoPurchaseTile(purchase),
      const SizedBox(height: 16),
      const DemoNotice(
        'El historial completo estará en tu PC. El celular conservará las compras recientes y las que aún estén pendientes de sincronizar.',
      ),
    ],
  );
}
