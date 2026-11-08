import 'package:flutter/material.dart';

import '../../../domain/repositories/repositorios.dart';
import '../../../presentation/widgets/demo_widgets.dart';
import '../../../presentation/widgets/compra_widgets.dart';
import '../viewmodels/inicio_viewmodel.dart';

final rutasInicio = RouteObserver<ModalRoute<void>>();
String _importe(BigInt v) =>
    '₲ ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';

class InicioLocalView extends StatefulWidget {
  const InicioLocalView(this.repositorio, {super.key});
  final RepositorioCompras repositorio;
  @override
  State<InicioLocalView> createState() => _InicioLocalViewState();
}

class _InicioLocalViewState extends State<InicioLocalView>
    with RouteAware, WidgetsBindingObserver {
  late final InicioViewModel vm;
  @override
  void initState() {
    super.initState();
    vm = InicioViewModel(widget.repositorio)..cargar();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ruta = ModalRoute.of(context);
    if (ruta != null) rutasInicio.subscribe(this, ruta);
  }

  @override
  void didPopNext() {
    vm.cargar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) vm.cargar();
  }

  @override
  void dispose() {
    rutasInicio.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) {
      final r = vm.resumen;
      return DemoPage(
        mostrarAvisoDemo: false,
        title: 'Cada compra cuenta.',
        eyebrow: 'Tu día a día, en orden',
        children: [
          if (vm.cargando)
            const Center(child: CircularProgressIndicator())
          else if (vm.fallo) ...[
            const DemoNotice('No pudimos cargar tus gastos.', warning: true),
            DemoAction('Reintentar', onPressed: vm.cargar),
          ] else if (r != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: canastaGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GASTADO ESTE MES',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _importe(r.totalMes),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${r.comprasMes} compras · PYG',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            DemoAction(
              'Registrar compra',
              icon: Icons.camera_alt_outlined,
              onPressed: () => Navigator.of(context).pushNamed('/captura'),
            ),
            const DemoSection('Resumen del historial'),
            DemoCard(
              child: Column(
                children: [
                  DemoMoneyRow('Total en este celular', _importe(r.totalLocal)),
                  Text('${r.comprasLocales} compras guardadas'),
                ],
              ),
            ),
            const DemoSection('Últimas compras'),
            if (r.ultimas.isEmpty)
              const Text('Todavía no hay compras guardadas.'),
            for (final c in r.ultimas)
              DemoCard(
                onTap: () =>
                    Navigator.of(context)
                        .pushNamed('/compra-local', arguments: c),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.fechaLocal.valor.split('-').reversed.join('/')),
                    DemoMoneyRow(
                      '${c.detalles.length} productos',
                      guaraniesDominio(c.resumen.totalCalculado),
                      emphasis: true,
                    ),
                  ],
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/historial'),
              child: const Text('Ver historial'),
            ),
            TextButton(onPressed: vm.cargar, child: const Text('Actualizar')),
          ],
        ],
      );
    },
  );
}
