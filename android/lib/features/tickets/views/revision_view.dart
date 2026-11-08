import 'package:flutter/material.dart';

import '../../../demo/revision_demo.dart';
import '../../../presentation/widgets/compra_widgets.dart';
import '../../../presentation/widgets/demo_widgets.dart';
import '../viewmodels/revision_ticket_viewmodel.dart';

/// Revisión con dominio y ViewModel; ejemplos separados de las reglas.
/// TODO: edición completa, OCR y guardado local transaccional.
class RevisionView extends StatefulWidget {
  const RevisionView({this.viewModel, super.key});
  final RevisionTicketViewModel? viewModel;
  @override
  State<RevisionView> createState() => _RevisionViewState();
}

class _RevisionViewState extends State<RevisionView> {
  DemoReviewScenario scenario = DemoReviewScenario.correct;
  late RevisionTicketViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel =
        widget.viewModel ??
        RevisionTicketViewModel(crearRevisionDemo(scenario));
    viewModel.addListener(_actualizar);
  }

  void _actualizar() => setState(() {});

  @override
  void didUpdateWidget(covariant RevisionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      viewModel.removeListener(_actualizar);
      if (oldWidget.viewModel == null) {
        viewModel.dispose();
      }
      viewModel =
          widget.viewModel ??
          RevisionTicketViewModel(crearRevisionDemo(scenario));
      viewModel.addListener(_actualizar);
    }
  }

  @override
  void dispose() {
    viewModel.removeListener(_actualizar);
    if (widget.viewModel == null) {
      viewModel.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esDemo = widget.viewModel == null;
    final uncertain = esDemo && scenario == DemoReviewScenario.uncertain;
    final difference = !viewModel.totalCoincide;
    final ready = viewModel.puedeContinuar;
    final productChecked = !viewModel.camposPendientes.contains(
      campoProductoDemo,
    );
    final quantityChecked = !viewModel.camposPendientes.contains(
      campoCantidadDemo,
    );
    final purchase = viewModel.borrador;
    final totalCalculado = guaraniesDominio(purchase.resumen.totalCalculado);
    final totalLeido = purchase.totalTicket == null
        ? 'Pendiente'
        : guaraniesDominio(purchase.totalTicket!);
    return DemoPage(
      title: 'Revisá tu compra',
      eyebrow: 'Antes de registrar',
      intro: 'Probá los resultados de lectura de un ticket de ejemplo.',
      children: [
        if (esDemo)
          DemoSelect<DemoReviewScenario>(
            key: const ValueKey('review-scenario'),
            label: 'Escenario de lectura · Simulación',
            value: scenario,
            options: const {
              DemoReviewScenario.correct: 'Lectura correcta',
              DemoReviewScenario.uncertain: 'Datos dudosos',
              DemoReviewScenario.difference: 'Total diferente',
            },
            onChanged: (v) {
              scenario = v;
              viewModel.cargarBorrador(crearRevisionDemo(v));
            },
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
                      : () => viewModel.marcarCampoRevisado(campoProductoDemo),
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
                      : () => viewModel.marcarCampoRevisado(campoCantidadDemo),
                ),
              ],
            ),
          ),
        ],
        if (difference) ...[
          const SizedBox(height: 16),
          DemoNotice('Revisá el total del ticket.', warning: true),
          const SizedBox(height: 12),
          if (esDemo)
            DemoAction(
              'Simular corrección a $totalCalculado',
              key: const ValueKey('review-total'),
              secondary: true,
              onPressed: () => viewModel.actualizarTotalTicket(
                purchase.resumen.totalCalculado,
              ),
            ),
        ],
        const DemoSection('Datos de la compra'),
        DemoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comercio',
                style: TextStyle(fontSize: 12, color: canastaMuted),
              ),
              Text(esDemo ? 'Mercado del Barrio' : 'Comercio según registro'),
              SizedBox(height: 12),
              Text(
                'Fecha · Moneda',
                style: TextStyle(fontSize: 12, color: canastaMuted),
              ),
              Text(
                '${purchase.fechaLocal.valor.split('-').reversed.join('/')} · PYG (guaraníes)',
              ),
            ],
          ),
        ),
        const DemoSection('Productos del ticket'),
        for (final line in purchase.detalles) DetalleCompraTile(line),
        ResumenCompraWidget(purchase),
        const SizedBox(height: 12),
        DemoMoneyRow('Total leído del ticket', totalLeido),
        const SizedBox(height: 10),
        DemoNotice(
          difference
              ? 'El ticket indica $totalLeido y el cálculo suma $totalCalculado.'
              : 'Total leído y calculado coinciden: $totalCalculado.',
          warning: difference,
        ),
        const SizedBox(height: 20),
        DemoAction(
          'Ver confirmación de ejemplo',
          key: const ValueKey('review-confirm'),
          onPressed: ready
              ? () => Navigator.of(context).pushReplacementNamed(
                  '/compra',
                  arguments: viewModel.prepararConfirmacion(),
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
