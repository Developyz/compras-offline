import 'package:flutter/material.dart';

import '../../../demo/demo_data.dart';
import '../../../presentation/widgets/demo_widgets.dart';
import '../../../presentation/widgets/purchase_widgets.dart';

/// TODO: consultar por ID vía ViewModel y mostrar el recibo real de sincronización.
class DetalleCompraView extends StatelessWidget {
  const DetalleCompraView({super.key, required this.arguments});
  final DemoPurchaseArguments arguments;
  @override
  Widget build(BuildContext context) {
    final purchase = arguments.purchase;
    return DemoPage(
      title: purchase.store,
      eyebrow: 'Detalle de compra',
      intro: '${purchase.date} · PYG',
      children: [
        if (arguments.confirmation) ...[
          const DemoNotice(
            'Simulación completada. Así se verá una compra registrada. No se guardó ni envió información.',
          ),
          const SizedBox(height: 16),
        ],
        DemoNotice(
          purchase.pending
              ? 'Ejemplo · Pendiente de sincronizar'
              : 'Ejemplo · Sincronizada',
        ),
        DemoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in purchase.lines) DemoLineTile(line),
              DemoPurchaseTotals(purchase),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const DemoNotice(
          'Sin imagen adjunta. En el flujo de captura temporal solo se conservan los datos de la compra.',
        ),
        const SizedBox(height: 18),
        DemoAction(
          'Volver al historial',
          secondary: true,
          onPressed: () =>
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/historial', (r) => r.isFirst),
        ),
      ],
    );
  }
}
