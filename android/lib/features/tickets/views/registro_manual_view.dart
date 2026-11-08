import 'package:flutter/material.dart';

import '../../../app/sesion_local.dart';
import '../../../domain/models/producto.dart';
import '../../../presentation/widgets/demo_widgets.dart';
import '../viewmodels/registro_manual.dart';
import '../viewmodels/lectura_ticket.dart';

class RegistroManualView extends StatefulWidget {
  const RegistroManualView(this.sesion, {this.lectura, super.key});
  final LecturaTicket? lectura;
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
  bool revisado = false;
  @override
  void initState() {
    super.initState();
    _agregar();
    final propuestas = widget.lectura?.productosSugeridos ?? [];
    for (var i = 0; i < propuestas.length; i++) {
      if (i > 0) _agregar();
      final propuesta = propuestas[i];
      final linea = lineas[i];
      linea.descripcion.text = propuesta.descripcion;
      linea.cantidad.text = propuesta.cantidad;
      linea.precio.text = propuesta.precio;
      linea.unidad = widget.sesion.unidades.firstWhere(
        (u) => u.simbolo.toLowerCase() == propuesta.unidad,
        orElse: () => widget.sesion.unidades.first,
      );
    }
    total.text = widget.lectura?.totalSugerido ?? '';
    total.addListener(_cambio);
    descuento.addListener(_cambio);
  }

  void _cambio() {
    if (widget.lectura != null && revisado && mounted) {
      setState(() => revisado = false);
    }
  }

  void _agregar() {
    revisado = false;
    final linea = _Linea(siguiente++, widget.sesion.unidades.first);
    for (final controller in [
      linea.descripcion,
      linea.cantidad,
      linea.precio,
    ]) {
      controller.addListener(_cambio);
    }
    lineas.add(linea);
  }

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
    if (widget.lectura != null && !revisado) return;
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
    eyebrow: widget.lectura == null ? 'Carga manual' : 'Revisá la lectura',
    children: [
      if (widget.lectura != null) ...[
        const DemoNotice(
          'La lectura puede estar incompleta. Revisá la fecha, los productos y cuánto pagaste.',
        ),
        ExpansionTile(
          title: const Text('Ver texto del ticket'),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(widget.lectura!.texto),
            ),
          ],
        ),
        CheckboxListTile(
          value: revisado,
          onChanged: (v) => setState(() => revisado = v ?? false),
          title: const Text('Revisé fecha, productos e importes'),
        ),
      ],
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
            _cambio();
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
            _cambio();
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
                  if (u != null) {
                    _cambio();
                    setState(() => l.unidad = u);
                  }
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
                    _cambio();
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
        onPressed: widget.lectura != null && !revisado ? null : _continuar,
      ),
    ],
  );
}
