import 'package:flutter/material.dart';

import '../../../domain/models/compra.dart';
import '../../../presentation/widgets/compra_widgets.dart';
import '../../../presentation/widgets/demo_widgets.dart';

class CompraLocalView extends StatelessWidget {
  const CompraLocalView(
    this.compra, {
    required this.unidades,
    this.recienGuardada = false,
    super.key,
  });
  final Compra compra;
  final Map<String, String> unidades;
  final bool recienGuardada;
  @override
  Widget build(BuildContext context) => DemoPage(
    mostrarAvisoDemo: false,
    title: recienGuardada ? 'Guardada en el celular' : 'Tu compra',
    eyebrow: 'Registro local',
    children: [
      if (recienGuardada) const DemoNotice('Pendiente de sincronización'),
      const SizedBox(height: 16),
      Text('${compra.fechaLocal.valor.split('-').reversed.join('/')} · PYG'),
      for (final detalle in compra.detalles)
        DetalleCompraTile(detalle, unidad: unidades[detalle.unidadCantidadId]),
      ResumenCompraWidget(compra),
      const SizedBox(height: 20),
      DemoAction(
        'Ver mis compras',
        onPressed: () =>
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/historial', (r) => r.isFirst),
      ),
      const SizedBox(height: 10),
      DemoAction(
        'Registrar otra',
        secondary: true,
        onPressed: () =>
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/manual', (r) => r.isFirst),
      ),
    ],
  );
}
