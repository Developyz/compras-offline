import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../presentation/widgets/demo_widgets.dart';
import '../../../services/captura/ticket_temporal.dart';
import '../viewmodels/lectura_ticket.dart';

class CamaraTicketView extends StatefulWidget {
  const CamaraTicketView({super.key});
  @override
  State<CamaraTicketView> createState() => _CamaraTicketViewState();
}

class _CamaraTicketViewState extends State<CamaraTicketView>
    with WidgetsBindingObserver {
  CameraController? _camara;
  bool _ocupado = false;
  bool _abriendo = false;
  String? _error;
  int _generacion = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _abrir();
  }

  Future<void> _abrir() async {
    if (_abriendo || !mounted) return;
    _abriendo = true;
    final generacion = ++_generacion;
    try {
      final anterior = _camara;
      _camara = null;
      await anterior?.dispose();
      final disponibles = await availableCameras();
      if (!mounted || generacion != _generacion) return;
      if (disponibles.isEmpty) throw StateError('No hay cámara');
      final elegida = disponibles.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => disponibles.first,
      );
      final camara = CameraController(
        elegida,
        ResolutionPreset.high,
        enableAudio: false,
      );
      try {
        await camara.initialize();
      } catch (_) {
        await camara.dispose();
        rethrow;
      }
      if (!mounted ||
          generacion != _generacion ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
          WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.inactive) {
        await camara.dispose();
        return;
      }
      setState(() {
        _camara = camara;
        _error = null;
      });
    } catch (_) {
      if (mounted && generacion == _generacion) {
        setState(
          () => _error = 'No pudimos abrir la cámara. Revisá su permiso.',
        );
      }
    } finally {
      _abriendo = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (_ocupado || _abriendo) return;
    if (estado == AppLifecycleState.inactive ||
        estado == AppLifecycleState.paused) {
      _generacion++;
      final anterior = _camara;
      _camara = null;
      anterior?.dispose();
      if (mounted) setState(() {});
    } else if (estado == AppLifecycleState.resumed && _camara == null) {
      _abrir();
    }
  }

  Future<void> _leer() async {
    final camara = _camara;
    if (_ocupado || camara == null || !camara.value.isInitialized) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      final foto = await camara.takePicture();
      final texto = await TicketTemporal.reconocerYBorrar(File(foto.path));
      if (!mounted) return;
      if (texto.trim().isEmpty) {
        setState(
          () =>
              _error = 'No se pudo leer. Acercá el ticket e intentá otra vez.',
        );
        return;
      }
      _camara = null;
      await camara.dispose();
      if (!mounted) return;
      await Navigator.of(context)
          .pushNamed('/manual', arguments: LecturaTicket(texto));
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos leer el ticket. Podés reintentar o cargarlo a mano.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _ocupado = false);
        if (_camara == null &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) {
          _abrir();
        }
      }
    }
  }

  @override
  void dispose() {
    _generacion++;
    WidgetsBinding.instance.removeObserver(this);
    _camara?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    mostrarAvisoDemo: false,
    title: 'Fotografiá tu ticket',
    eyebrow: 'Lectura de compra',
    children: [
      if (_camara != null && _camara!.value.isInitialized)
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Center(child: CameraPreview(_camara!)),
          ),
        )
      else if (_error == null)
        const Center(child: CircularProgressIndicator()),
      if (_ocupado)
        const LinearProgressIndicator(semanticsLabel: 'Leyendo ticket'),
      if (_error != null) ...[
        DemoNotice(_error!, warning: true),
        TextButton(
          onPressed: _ocupado ? null : _abrir,
          child: const Text('Reintentar cámara'),
        ),
      ],
      const SizedBox(height: 16),
      DemoAction(
        _ocupado ? 'Leyendo…' : 'Tomar foto y leer',
        onPressed: _ocupado || _camara == null ? null : _leer,
        icon: Icons.camera_alt_outlined,
      ),
      const SizedBox(height: 10),
      const Text(
        'La foto se borra después de leerla. Revisá los datos antes de guardar.',
      ),
      TextButton(
        onPressed: _ocupado
            ? null
            : () => Navigator.of(context).pushNamed('/manual'),
        child: const Text('Registrar a mano'),
      ),
    ],
  );
}
