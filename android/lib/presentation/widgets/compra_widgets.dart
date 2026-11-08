import 'package:flutter/material.dart';

import '../../domain/models/compra.dart';
import '../../domain/models/valores_compra.dart';
import 'demo_widgets.dart';

/// Presentación exacta sin convertir BigInt a double/int ni perder dígitos.
String guaraniesDominio(ImportePyg importe) =>
    '₲ ${importe.valor.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';

String cantidadDominio(CantidadCompra cantidad) {
  final entero = cantidad.milesimas ~/ BigInt.from(1000);
  final resto = (cantidad.milesimas % BigInt.from(1000))
      .toString()
      .padLeft(3, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return resto.isEmpty ? '$entero' : '$entero,$resto';
}

class DetalleCompraTile extends StatelessWidget {
  const DetalleCompraTile(this.detalle, {super.key});
  final DetalleCompra detalle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detalle.descripcionTicket,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          '${cantidadDominio(detalle.cantidad)} × ${guaraniesDominio(detalle.precioUnitario)}',
          style: const TextStyle(color: canastaMuted, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          guaraniesDominio(detalle.importeBruto),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Divider(height: 20, color: Color(0xFFE2E8DF)),
      ],
    ),
  );
}

class ResumenCompraWidget extends StatelessWidget {
  const ResumenCompraWidget(this.compra, {super.key});
  final Compra compra;
  @override
  Widget build(BuildContext context) {
    final resumen = compra.resumen;
    return Column(
      children: [
        DemoMoneyRow('Subtotal', guaraniesDominio(resumen.subtotal)),
        if (resumen.descuentoProductos.valor != BigInt.zero)
          DemoMoneyRow(
            'Descuentos por producto',
            '− ${guaraniesDominio(resumen.descuentoProductos)}',
          ),
        DemoMoneyRow(
          'Descuento general',
          '− ${guaraniesDominio(resumen.descuentoGeneral)}',
        ),
        if (resumen.ajuste != BigInt.zero)
          DemoMoneyRow(
            'Ajuste',
            '${resumen.ajuste.isNegative ? '−' : '+'} ${guaraniesDominio(ImportePyg(resumen.ajuste.abs()))}',
          ),
        const Divider(),
        DemoMoneyRow(
          'Total · PYG',
          guaraniesDominio(resumen.totalCalculado),
          emphasis: true,
        ),
      ],
    );
  }
}
