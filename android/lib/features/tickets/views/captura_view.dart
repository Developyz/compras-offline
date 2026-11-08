import '../../../presentation/widgets/tema_app.dart';

import 'package:flutter/material.dart';

import '../../../presentation/widgets/demo_widgets.dart';

/// TODO: permisos, cámara y OCR local. Eliminar capturas temporales al confirmar/cancelar.
class CapturaView extends StatelessWidget {
  const CapturaView({this.onRegistrarManual, super.key});
  final VoidCallback? onRegistrarManual;
  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Capturá tu ticket',
    eyebrow: 'Del ticket a tu registro',
    intro: 'La app leerá los productos, precios y descuentos para que los revises.',
    children: [
      if (onRegistrarManual != null) ...[
        DemoAction(
          'Registrar a mano',
          key: const ValueKey('registro-manual'),
          onPressed: onRegistrarManual,
        ),
        const SizedBox(height: 16),
      ],
      Semantics(
        label: 'Ilustración de ticket de ejemplo. No es una cámara activa.',
        image: true,
        child: ExcludeSemantics(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: suaveApp(context),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: superficieApp(context),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: textoVerde(context),
                        size: 42,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'MERCADO DEL BARRIO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        '08/11/2026 · Ejemplo',
                        style: TextStyle(fontSize: 11),
                      ),
                      const Divider(height: 26),
                      DemoMoneyRow('Arroz · 500 g', guaranies(1800)),
                      DemoMoneyRow('Leche · 2 unidades', guaranies(2400)),
                      DemoMoneyRow('Manzana · 1 kg', guaranies(2200)),
                      DemoMoneyRow('Descuento', '− ${guaranies(400)}'),
                      const Divider(),
                      DemoMoneyRow('Total', guaranies(6000), emphasis: true),
                      const SizedBox(height: 12),
                      const Text(
                        'VISTA ILUSTRATIVA',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      const DemoNotice(
        'La foto tomada desde la app será temporal. Se eliminará al confirmar o cancelar; no se guardará en la galería ni se enviará a la PC.',
      ),
      const SizedBox(height: 20),
      DemoAction(
        'Probar con ticket de ejemplo',
        icon: Icons.camera_alt_outlined,
        onPressed: () => Navigator.of(context).pushNamed('/revision'),
      ),
      const SizedBox(height: 10),
      DemoAction(
        'Elegir una foto existente',
        secondary: true,
        onPressed: () => pendingDemo(
          context,
          'En la app podrás subir y conservar una foto voluntariamente. Esta demostración no abre archivos.',
        ),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        child: const Text('Cancelar captura'),
      ),
    ],
  );
}
