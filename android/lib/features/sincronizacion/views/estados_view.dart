import 'package:flutter/material.dart';

import '../../../demo/demo_data.dart';
import '../../../presentation/widgets/demo_widgets.dart';

enum DemoPurchaseState {
  empty,
  emptyBasket,
  unreadable,
  saved,
  pending,
  error,
  synced,
}

class _StateExample {
  const _StateExample(
    this.icon,
    this.title,
    this.description,
    this.detail,
    this.action,
    this.destination,
  );
  final IconData icon;
  final String title;
  final String description;
  final String detail;
  final String action;
  final String destination;
}

const _examples = {
  DemoPurchaseState.empty: _StateExample(
    Icons.receipt_long_outlined,
    'Tu primera compra empieza acá',
    'Cuando registres un ticket, encontrarás sus productos en el historial.',
    'Sin compras todavía. Este escenario no muestra gastos como si fueran reales.',
    'Probar captura de ejemplo',
    '/captura',
  ),
  DemoPurchaseState.emptyBasket: _StateExample(
    Icons.shopping_bag_outlined,
    'Prepará tu próxima compra',
    'Agregá los productos que necesitás para organizar tu canasta.',
    'Sin productos · Total estimado: ₲ 0. El botón abre una canasta ya preparada de ejemplo.',
    'Ver canasta de ejemplo',
    '/canasta',
  ),
  DemoPurchaseState.unreadable: _StateExample(
    Icons.camera_alt_outlined,
    'No pudimos leer este ticket',
    'Probá con más luz, el ticket completo y la cámara enfocada.',
    'No se registró ninguna compra. En la app también podrás cargar los datos manualmente.',
    'Volver a captura',
    '/captura',
  ),
  DemoPurchaseState.saved: _StateExample(
    Icons.check_circle_outline,
    'Tu compra quedó registrada',
    'Podés consultar sus datos y seguir usando la app sin conexión.',
    'Ejemplo: guardado en el celular. La foto temporal se elimina y la sincronización se informa por separado.',
    'Ver detalle de ejemplo',
    '/compra',
  ),
  DemoPurchaseState.pending: _StateExample(
    Icons.sync_outlined,
    'Esperando a tu PC',
    'La compra está guardada en el celular y se enviará cuando la PC esté accesible.',
    'Ejemplo: 1 compra pendiente. No hace falta registrarla otra vez. Tener internet no garantiza que la PC esté disponible.',
    'Ver compra pendiente de ejemplo',
    '/compra',
  ),
  DemoPurchaseState.error: _StateExample(
    Icons.sync_problem_outlined,
    'No pudimos confirmar el envío',
    'Los datos siguen en el celular. La app reintentará sin duplicar la compra.',
    'Ejemplo: conexión interrumpida. La PC pudo haber recibido la operación; no se generará otra compra al reintentar.',
    'Simular reintento',
    'retry',
  ),
  DemoPurchaseState.synced: _StateExample(
    Icons.cloud_done_outlined,
    'Tu compra está sincronizada',
    'El servidor confirmó el registro en el historial de la PC.',
    'Escenario visual. En la app real, este estado requiere la confirmación del servidor; no basta con iniciar el envío.',
    'Volver al inicio',
    '/',
  ),
};

/// TODO: derivar estos estados del ViewModel/cola y exigir recibos reales.
/// El selector solo revisa diseños; ninguna opción hace conexiones ni borra datos.
class EstadosView extends StatefulWidget {
  const EstadosView({super.key});
  @override
  State<EstadosView> createState() => _EstadosViewState();
}

class _EstadosViewState extends State<EstadosView> {
  DemoPurchaseState selected = DemoPurchaseState.empty;
  bool retried = false;
  @override
  Widget build(BuildContext context) {
    final example = _examples[selected]!;
    return DemoPage(
      title: 'Estado de tus compras',
      eyebrow: 'Siempre sabés dónde quedó tu compra',
      intro: 'Escenarios de ejemplo, no el estado real de ningún dispositivo.',
      children: [
        DemoSelect<DemoPurchaseState>(
          key: const ValueKey('state-scenario'),
          label: 'Elegí un estado',
          value: selected,
          options: const {
            DemoPurchaseState.empty: 'Sin compras',
            DemoPurchaseState.emptyBasket: 'Canasta vacía',
            DemoPurchaseState.unreadable: 'Ticket ilegible',
            DemoPurchaseState.saved: 'Guardada en el celular',
            DemoPurchaseState.pending: 'Pendiente',
            DemoPurchaseState.error: 'Error al sincronizar',
            DemoPurchaseState.synced: 'Sincronizada',
          },
          onChanged: (v) => setState(() {
            selected = v;
            retried = false;
          }),
        ),
        const SizedBox(height: 18),
        DemoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(example.icon, color: canastaGreen, size: 48),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  example.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: canastaGreen,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(example.description),
              const SizedBox(height: 16),
              DemoNotice(
                retried
                    ? 'Reintento simulado: vuelve a quedar pendiente de confirmación. No se hizo ninguna conexión.'
                    : example.detail,
                warning: selected == DemoPurchaseState.error,
              ),
              const SizedBox(height: 20),
              DemoAction(
                example.action,
                key: const ValueKey('state-action'),
                onPressed: () {
                  if (example.destination == 'retry') {
                    setState(() {
                      selected = DemoPurchaseState.pending;
                      retried = true;
                    });
                  } else if (example.destination == '/') {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  } else {
                    Navigator.of(context).pushNamed(
                      example.destination,
                      arguments: example.destination == '/compra'
                          ? DemoPurchaseArguments(demoPurchases.first)
                          : null,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const DemoNotice(
          'Las compras pendientes no se eliminan por antigüedad. Las capturas temporales se eliminan al confirmar o cancelar.',
        ),
      ],
    );
  }
}
