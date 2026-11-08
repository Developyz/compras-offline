import 'package:flutter/material.dart';

import '../../../domain/models/compra.dart';
import '../../../domain/repositories/repositorios.dart';
import '../../../presentation/widgets/compra_widgets.dart';
import '../../../presentation/widgets/demo_widgets.dart';

class ComprasLocalesView extends StatefulWidget {
  const ComprasLocalesView(this.repositorio, {super.key});
  final RepositorioCompras repositorio;
  @override
  State<ComprasLocalesView> createState() => _ComprasLocalesViewState();
}

class _ComprasLocalesViewState extends State<ComprasLocalesView> {
  late Future<List<Compra>> _compras;
  @override
  void initState() {
    super.initState();
    _compras = widget.repositorio.listarRecientes();
  }

  void _recargar() => setState(() {
    _compras = widget.repositorio.listarRecientes();
  });
  @override
  Widget build(BuildContext context) => DemoPage(
    mostrarAvisoDemo: false,
    title: 'Mis compras',
    eyebrow: 'En este celular',
    children: [
      FutureBuilder<List<Compra>>(
        future: _compras,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (estado.hasError) {
            return Column(
              children: [
                const DemoNotice(
                  'No pudimos cargar tus compras.',
                  warning: true,
                ),
                DemoAction('Reintentar', onPressed: _recargar),
              ],
            );
          }
          final compras = estado.data!;
          if (compras.isEmpty) {
            return Column(
              children: [
                const Text('Todavía no hay compras guardadas.'),
                const SizedBox(height: 16),
                DemoAction(
                  'Registrar compra',
                  onPressed: () => Navigator.of(context).pushNamed('/manual'),
                ),
              ],
            );
          }
          return Column(
            children: [
              for (final compra in compras)
                DemoCard(
                  onTap: () =>
                      Navigator.of(context)
                          .pushNamed('/compra-local', arguments: compra),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compra.fechaLocal.valor.split('-').reversed.join('/'),
                      ),
                      DemoMoneyRow(
                        '${compra.detalles.length} productos',
                        guaraniesDominio(compra.resumen.totalCalculado),
                        emphasis: true,
                      ),
                    ],
                  ),
                ),
              if (compras.length == 100)
                const Text('Se muestran las 100 compras más recientes.'),
              TextButton(onPressed: _recargar, child: const Text('Actualizar')),
            ],
          );
        },
      ),
    ],
  );
}
