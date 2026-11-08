import 'package:flutter/material.dart';

import '../../../demo/demo_data.dart';
import '../../../presentation/widgets/demo_widgets.dart';

/// TODO: catálogo/última observación desde ViewModel; esta búsqueda filtra fixtures.
class ProductosView extends StatefulWidget {
  const ProductosView({super.key});
  @override
  State<ProductosView> createState() => _ProductosViewState();
}

class _ProductosViewState extends State<ProductosView> {
  final search = TextEditingController();
  String query = '';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = demoProducts
        .where(
          (p) => '${p.name} ${p.presentation}'.toLowerCase().contains(
            query.trim().toLowerCase(),
          ),
        )
        .toList();
    return DemoPage(
      title: 'Mis productos',
      eyebrow: 'Conocé lo que comprás',
      intro: 'Compará los precios registrados de un mismo producto a lo largo del tiempo.',
      children: [
        TextField(
          key: const ValueKey('product-search'),
          controller: search,
          decoration: InputDecoration(
            labelText: 'Buscar producto',
            hintText: 'Arroz, leche, manzana…',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      search.clear();
                      setState(() => query = '');
                    },
                  )
                : null,
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const DemoSection('Tu catálogo'),
        Text(
          '${products.length} de ${demoProducts.length} productos de ejemplo',
          style: const TextStyle(fontSize: 12, color: canastaMuted),
        ),
        const SizedBox(height: 10),
        if (products.isEmpty)
          const DemoNotice(
            'No encontramos ese producto en este catálogo de ejemplo.',
          ),
        for (final product in products)
          DemoCard(
            key: ValueKey('product-${product.id}'),
            onTap: () =>
                Navigator.of(context)
                    .pushNamed('/producto', arguments: product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  product.id == 'manzana'
                      ? Icons.eco_outlined
                      : Icons.inventory_2_outlined,
                  color: canastaGreen,
                ),
                const SizedBox(height: 10),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.presentation,
                  style: const TextStyle(fontSize: 12, color: canastaMuted),
                ),
                const SizedBox(height: 12),
                Text(
                  '${guaranies(product.points.last.price)} ${product.priceUnit}',
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ver evolución de precios →',
                  style: TextStyle(fontSize: 12, color: canastaGreen),
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),
        const DemoNotice(
          'Los precios corresponden a compras registradas. No son precios en vivo del supermercado.',
        ),
      ],
    );
  }
}
