import 'package:flutter/material.dart';

import '../../../demo/demo_data.dart';
import '../../../presentation/widgets/demo_widgets.dart';
import '../../../presentation/widgets/purchase_widgets.dart';

enum DemoReviewScenario { correct, uncertain, difference }

/// Escenarios exclusivamente visuales. TODO: confianza OCR, corrección y validación
/// vendrán del ViewModel; confirmar guardará dato+cola en una transacción local.
class RevisionView extends StatefulWidget {
  const RevisionView({super.key});
  @override
  State<RevisionView> createState() => _RevisionViewState();
}

class _RevisionViewState extends State<RevisionView> {
  DemoReviewScenario scenario = DemoReviewScenario.correct;
  bool productChecked = false;
  bool quantityChecked = false;
  bool totalChecked = false;

  @override
  Widget build(BuildContext context) {
    final uncertain = scenario == DemoReviewScenario.uncertain;
    final difference =
        scenario == DemoReviewScenario.difference && !totalChecked;
    final ready =
        (!uncertain || (productChecked && quantityChecked)) && !difference;
    final purchase = demoPurchases.first;
    return DemoPage(
      title: 'Revisá tu compra',
      eyebrow: 'Antes de registrar',
      intro: 'Probá los resultados de lectura de un ticket de ejemplo.',
      children: [
        DemoSelect<DemoReviewScenario>(
          key: const ValueKey('review-scenario'),
          label: 'Escenario de lectura · Simulación',
          value: scenario,
          options: const {
            DemoReviewScenario.correct: 'Lectura correcta',
            DemoReviewScenario.uncertain: 'Datos dudosos',
            DemoReviewScenario.difference: 'Total diferente',
          },
          onChanged: (v) => setState(() {
            scenario = v;
            productChecked = false;
            quantityChecked = false;
            totalChecked = false;
          }),
        ),
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          child: DemoNotice(
            ready
                ? 'Datos de ejemplo revisados. Podés ver la confirmación simulada.'
                : 'Revisá las advertencias antes de continuar.',
            warning: !ready,
          ),
        ),
        if (uncertain) ...[
          const DemoSection('Revisá estos dos datos'),
          DemoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Producto poco legible',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lectura: “ARR… INT 500”. Propuesta: Arroz integral · 500 g.',
                ),
                const SizedBox(height: 12),
                DemoAction(
                  productChecked
                      ? 'Producto revisado ✓'
                      : 'Confirmar producto de ejemplo',
                  key: const ValueKey('review-product'),
                  secondary: true,
                  onPressed: productChecked
                      ? null
                      : () => setState(() => productChecked = true),
                ),
              ],
            ),
          ),
          DemoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cantidad poco clara',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Leche: la lectura no distingue 2 de 7. En este ejemplo son 2 unidades.',
                ),
                const SizedBox(height: 12),
                DemoAction(
                  quantityChecked
                      ? 'Cantidad revisada ✓'
                      : 'Confirmar 2 unidades',
                  key: const ValueKey('review-quantity'),
                  secondary: true,
                  onPressed: quantityChecked
                      ? null
                      : () => setState(() => quantityChecked = true),
                ),
              ],
            ),
          ),
        ],
        if (difference) ...[
          const SizedBox(height: 16),
          DemoNotice(
            'Hay ${guaranies(500)} de diferencia. '
            'No ajustaremos los importes automáticamente.',
            warning: true,
          ),
          const SizedBox(height: 12),
          DemoAction(
            'Simular corrección a ${guaranies(6000)}',
            key: const ValueKey('review-total'),
            secondary: true,
            onPressed: () => setState(() => totalChecked = true),
          ),
        ],
        const DemoSection('Datos de la compra'),
        const DemoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comercio',
                style: TextStyle(fontSize: 12, color: canastaMuted),
              ),
              Text('Mercado del Barrio'),
              SizedBox(height: 12),
              Text(
                'Fecha · Moneda',
                style: TextStyle(fontSize: 12, color: canastaMuted),
              ),
              Text('08/11/2026 · PYG (guaraníes)'),
            ],
          ),
        ),
        const DemoSection('Productos del ticket'),
        for (final line in purchase.lines) DemoLineTile(line),
        DemoPurchaseTotals(purchase),
        const SizedBox(height: 12),
        DemoMoneyRow(
          'Total leído del ticket',
          guaranies(difference ? 6500 : 6000),
        ),
        const SizedBox(height: 10),
        DemoNotice(
          difference
              ? 'El ticket indica ₲ 6.500 y el cálculo suma ₲ 6.000.'
              : 'Total leído y calculado coinciden: ₲ 6.000.',
          warning: difference,
        ),
        const SizedBox(height: 20),
        DemoAction(
          'Ver confirmación de ejemplo',
          key: const ValueKey('review-confirm'),
          onPressed: ready
              ? () => Navigator.of(context).pushReplacementNamed(
                  '/compra',
                  arguments: DemoPurchaseArguments(
                    purchase,
                    confirmation: true,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          ready
              ? 'Esta acción no guarda ni envía información.'
              : 'La confirmación se habilita al resolver las advertencias.',
          style: const TextStyle(fontSize: 12, color: canastaMuted),
        ),
      ],
    );
  }
}
