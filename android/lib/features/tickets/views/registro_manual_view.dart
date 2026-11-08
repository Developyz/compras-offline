import 'package:flutter/material.dart';

import '../../../app/sesion_local.dart';
import '../../../domain/models/producto.dart';
import '../../../presentation/widgets/demo_widgets.dart';
import '../viewmodels/registro_manual.dart';

class RegistroManualView extends StatefulWidget {
  const RegistroManualView(this.sesion, {super.key});
  final SesionLocal sesion;
  @override
  State<RegistroManualView> createState() => _RegistroManualViewState();
}

class _Linea {
  _Linea(this.numero, this.unidad);
  final int numero;
  UnidadMedida unidad;
  final descripcion = TextEditingController();
  final cantidad = TextEditingController(text: '1');
  final precio = TextEditingController();
  void dispose() {
    descripcion.dispose();
    cantidad.dispose();
    precio.dispose();
  }
}

class _RegistroManualViewState extends State<RegistroManualView> {
  final total = TextEditingController();
  final descuento = TextEditingController();
  final lineas = <_Linea>[];
  DateTime fecha = DateTime.now();
  String? error;
  int siguiente = 0;
  @override
  void initState() {
    super.initState();
    _agregar();
  }

  void _agregar() =>
      lineas.add(_Linea(siguiente++, widget.sesion.unidades.first));
  @override
  void dispose() {
    total.dispose();
    descuento.dispose();
    for (final linea in lineas) {
      linea.dispose();
    }
    super.dispose();
  }

  void _continuar() {
    try {
      final compra = crearBorradorManual(
        lineas: [
          for (final l in lineas)
            LineaManual(
              descripcion: l.descripcion.text,
              cantidad: l.cantidad.text,
              precio: l.precio.text,
              unidad: l.unidad,
            ),
        ],
        total: total.text,
        descuento: descuento.text,
        fecha: DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          fecha.hour,
          fecha.minute,
        ),
        nuevoId: widget.sesion.nuevoId,
      );
      setState(() => error = null);
      Navigator.of(context).pushNamed('/revision', arguments: compra);
    } on Exception {
      setState(() => error = 'Revisá productos, cantidades e importes.');
    } on ArgumentError {
      setState(() => error = 'Revisá productos, cantidades e importes.');
    }
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    mostrarAvisoDemo: false,
    title: 'Registrar compra',
    eyebrow: 'Carga manual',
    children: [
      TextButton.icon(
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(
          '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
        ),
        onPressed: () async {
          final valor = await showDatePicker(
            context: context,
            initialDate: fecha,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (valor != null && mounted) {
            setState(
              () => fecha = DateTime(
                valor.year,
                valor.month,
                valor.day,
                fecha.hour,
                fecha.minute,
              ),
            );
          }
        },
      ),
      TextButton.icon(
        icon: const Icon(Icons.access_time),
        label: Text(
          '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
        ),
        onPressed: () async {
          final valor = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(fecha),
          );
          if (valor != null && mounted) {
            setState(
              () => fecha = DateTime(
                fecha.year,
                fecha.month,
                fecha.day,
                valor.hour,
                valor.minute,
              ),
            );
          }
        },
      ),
      for (final l in lineas)
        DemoCard(
          key: ValueKey('linea-${l.numero}'),
          child: Column(
            children: [
              TextField(
                key: ValueKey('descripcion-${l.numero}'),
                controller: l.descripcion,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Producto',
                  counterText: '',
                ),
              ),
              TextField(
                key: ValueKey('cantidad-${l.numero}'),
                controller: l.cantidad,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  hintText: '1,5',
                ),
              ),
              DropdownButtonFormField<UnidadMedida>(
                initialValue: l.unidad,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Unidad'),
                items: [
                  for (final u in widget.sesion.unidades)
                    DropdownMenuItem(value: u, child: Text(u.nombre)),
                ],
                onChanged: (u) {
                  if (u != null) setState(() => l.unidad = u);
                },
              ),
              TextField(
                key: ValueKey('precio-${l.numero}'),
                controller: l.precio,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.unidad.simbolo == 'u'
                      ? 'Precio de uno · ₲'
                      : 'Precio por ${l.unidad.simbolo} · ₲',
                ),
              ),
              if (lineas.length > 1)
                TextButton(
                  onPressed: () => setState(() {
                    lineas.remove(l);
                    l.dispose();
                  }),
                  child: const Text('Quitar producto'),
                ),
            ],
          ),
        ),
      TextButton.icon(
        key: const ValueKey('agregar-producto'),
        onPressed: lineas.length >= 1000 ? null : () => setState(_agregar),
        icon: const Icon(Icons.add),
        label: const Text('Agregar producto'),
      ),
      TextField(
        key: const ValueKey('descuento-manual'),
        controller: descuento,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Descuento · ₲ (opcional)',
          helperText: 'De toda la compra, si hubo.',
          helperMaxLines: 2,
          hintText: '0',
        ),
      ),
      TextField(
        key: const ValueKey('total-manual'),
        controller: total,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: '¿Cuánto pagaste? · ₲'),
      ),
      const SizedBox(height: 20),
      if (error != null) ...[
        DemoNotice(error!, warning: true),
        const SizedBox(height: 12),
      ],
      DemoAction(
        'Revisar compra',
        key: const ValueKey('revisar-manual'),
        onPressed: _continuar,
      ),
    ],
  );
}
