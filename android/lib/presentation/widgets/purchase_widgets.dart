import 'package:flutter/material.dart';

import '../../demo/demo_data.dart';
import 'demo_widgets.dart';
import 'tema_app.dart';

class DemoPurchaseTile extends StatelessWidget {
  const DemoPurchaseTile(this.purchase, {super.key});
  final DemoPurchase purchase;
  @override
  Widget build(BuildContext context) => DemoCard(
    onTap: () =>
        Navigator.of(context)
            .pushNamed('/compra', arguments: DemoPurchaseArguments(purchase)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          purchase.store,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 5),
        Text(
          '${purchase.shortDate} · ${purchase.lines.length} productos',
          style: TextStyle(color: textoSecundario(context), fontSize: 12),
        ),
        const SizedBox(height: 10),
        DemoMoneyRow(
          purchase.pending ? 'Ejemplo · Pendiente' : 'Ejemplo · Sincronizada',
          guaranies(purchase.total),
        ),
        const Text(
          'Ver detalle →',
          style: TextStyle(color: canastaGreen, fontSize: 12),
        ),
      ],
    ),
  );
}

class DemoLineTile extends StatelessWidget {
  const DemoLineTile(this.line, {super.key});
  final DemoLine line;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          '${line.quantity} · ${guaranies(line.unitPrice)} ${line.unitLabel}',
          style: TextStyle(color: textoSecundario(context), fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          guaranies(line.total),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Divider(height: 20, color: Color(0xFFE2E8DF)),
      ],
    ),
  );
}

class DemoPurchaseTotals extends StatelessWidget {
  const DemoPurchaseTotals(this.purchase, {super.key});
  final DemoPurchase purchase;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      DemoMoneyRow('Subtotal', guaranies(purchase.subtotal)),
      DemoMoneyRow('Descuento general', '− ${guaranies(purchase.discount)}'),
      const Divider(),
      DemoMoneyRow('Total · PYG', guaranies(purchase.total), emphasis: true),
    ],
  );
}
