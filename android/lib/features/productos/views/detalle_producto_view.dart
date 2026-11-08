import '../../../presentation/widgets/tema_app.dart';

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../demo/demo_data.dart';
import '../../../presentation/widgets/demo_widgets.dart';

/// TODO: historial local/remoto por producto, unidades compatibles y período disponible.
/// Dobles solo para coordenadas del dibujo; los precios de ejemplo son enteros PYG.
class DetalleProductoView extends StatefulWidget {
  const DetalleProductoView({super.key, required this.product});
  final DemoProduct product;
  @override
  State<DetalleProductoView> createState() => _DetalleProductoViewState();
}

class _DetalleProductoViewState extends State<DetalleProductoView> {
  late int selected = widget.product.points.length - 1;
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final latest = product.points.last.price;
    final previous = product.points[product.points.length - 2].price;
    final difference = latest - previous;
    final percentFormat = NumberFormat.decimalPattern('es_PY')
      ..maximumFractionDigits = 1;
    final percentage =
        '${difference >= 0 ? '+' : '−'}${percentFormat.format((difference / previous * 100).abs())} %';
    final point = product.points[selected];
    return DemoPage(
      title: product.name,
      eyebrow: 'Evolución de precios',
      intro: product.presentation,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stats = [
              _ProductStat(
                'Último precio registrado',
                guaranies(latest),
                '${product.priceUnit} · 08 nov 2026',
              ),
              _ProductStat(
                'Frente al registro anterior',
                percentage,
                '${difference >= 0 ? 'Subió' : 'Bajó'} ${guaranies(difference.abs())}',
                color: difference > 0
                    ? Theme.of(context).colorScheme.error
                    : textoVerde(context),
              ),
            ];
            if (constraints.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(14) > 20) {
              return Column(
                children: [stats[0], const SizedBox(height: 12), stats[1]],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: stats[0]),
                const SizedBox(width: 12),
                Expanded(child: stats[1]),
              ],
            );
          },
        ),
        const DemoSection('Subidas y bajadas'),
        Text(
          'Últimos 30 días · Ejemplo\nPYG · Precio antes de descuentos · ${product.priceUnit}',
          style: TextStyle(color: textoSecundario(context), fontSize: 12),
        ),
        const SizedBox(height: 18),
        DemoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                image: true,
                label:
                    'Evolución de precios de ${product.name}. '
                    'Los valores y comercios se detallan debajo del gráfico.',
                child: ExcludeSemantics(child: _chart(context)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  product.points.length,
                  (index) => ChoiceChip(
                    key: ValueKey('price-point-$index'),
                    label: Text(product.points[index].date),
                    selected: selected == index,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => selected = index),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: DemoNotice(
                  '${point.date} 2026 · ${point.store}\n'
                  '${guaranies(point.price)} ${product.priceUnit}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Cada punto es una compra de ejemplo. Las líneas solo unen registros: '
          'no indican el precio real entre esas fechas.',
          style: TextStyle(color: textoSecundario(context), fontSize: 12),
        ),
        const DemoSection('Historial del producto'),
        for (final entry in product.points.reversed)
          DemoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.date} 2026',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.store,
                  style: TextStyle(
                    color: textoSecundario(context),
                    fontSize: 12,
                  ),
                ),
                DemoMoneyRow(product.priceUnit, guaranies(entry.price)),
              ],
            ),
          ),
        const SizedBox(height: 14),
        DemoNotice(
          'Último precio equivalente: ${guaranies(latest * product.equivalentFactor)} '
          'por ${product.equivalentUnit}. Antes de descuentos.',
        ),
        const SizedBox(height: 12),
        const DemoNotice(
          'Solo se muestran registros de ejemplo de los últimos 30 días. '
          'El historial completo quedará en tu PC.',
          warning: true,
        ),
      ],
    );
  }

  Widget _chart(BuildContext context) {
    final points = widget.product.points;
    final low =
        (points.map((p) => p.price).reduce(math.min) * .85 / 100).floor() *
        100.0;
    final high =
        (points.map((p) => p.price).reduce(math.max) * 1.1 / 100).ceil() *
        100.0;
    final largeText = MediaQuery.textScalerOf(context).scale(12) > 16;
    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, right: 12),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            minY: low,
            maxY: high,
            lineTouchData: const LineTouchData(enabled: false),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: (high - low) / 3,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: Color(0xFFE2E8DF),
                strokeWidth: 1,
                dashArray: [3, 4],
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: !largeText,
                  interval: 1,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if ((value - index).abs() > .01 ||
                        index < 0 ||
                        index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        points[index].date,
                        style: TextStyle(
                          fontSize: 10,
                          color: textoSecundario(context),
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: !largeText,
                  reservedSize: 48,
                  interval: (high - low) / 3,
                  getTitlesWidget: (value, meta) => Text(
                    NumberFormat.decimalPattern('es_PY').format(value.round()),
                    style: TextStyle(
                      fontSize: 10,
                      color: textoSecundario(context),
                    ),
                  ),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), points[i].price.toDouble()),
                ],
                isCurved: false,
                color: textoVerde(context),
                barWidth: 3,
                belowBarData: BarAreaData(show: true, color: suaveApp(context)),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: index == selected ? 6 : 4,
                        color: index == selected
                            ? canastaLime
                            : superficieApp(context),
                        strokeWidth: 2,
                        strokeColor: textoVerde(context),
                      ),
                ),
              ),
            ],
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }
}

class _ProductStat extends StatelessWidget {
  const _ProductStat(this.label, this.value, this.description, {this.color});
  final String label;
  final String value;
  final String description;
  final Color? color;
  @override
  Widget build(BuildContext context) => DemoCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textoSecundario(context)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: color ?? textoVerde(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: textoSecundario(context)),
        ),
      ],
    ),
  );
}
