import 'package:flutter/material.dart';

import '../../../domain/models/compra.dart';
import '../../../presentation/widgets/compra_widgets.dart';
import '../../../presentation/widgets/demo_widgets.dart';

/// Muestra exactamente el agregado preparado por el ViewModel; sin escritura.
class ConfirmacionRevisionView extends StatelessWidget {
  const ConfirmacionRevisionView(this.compra, {super.key});
  final Compra compra;
  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Compra revisada',
    eyebrow: 'Vista previa',
    children: [
      const DemoNotice(
        'Simulación completada. No se guardó ni envió información.',
      ),
      const SizedBox(height: 16),
      Text('${compra.fechaLocal.valor.split('-').reversed.join('/')} · PYG'),
      const DemoSection('Productos del ticket'),
      for (final detalle in compra.detalles) DetalleCompraTile(detalle),
      ResumenCompraWidget(compra),
      const SizedBox(height: 20),
      DemoAction(
        'Ver historial',
        onPressed: () =>
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/historial', (r) => r.isFirst),
      ),
    ],
  );
}
