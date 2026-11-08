import 'dart:async';

import 'package:flutter/material.dart';

import 'canasta_app.dart';
import 'sesion_local.dart';

class InicioLocal extends StatefulWidget {
  const InicioLocal({this.abrir = SesionLocal.abrirPrivada, super.key});
  final Future<SesionLocal> Function() abrir;
  @override
  State<InicioLocal> createState() => _InicioLocalState();
}

class _InicioLocalState extends State<InicioLocal> {
  late Future<SesionLocal> _inicio;
  SesionLocal? _sesion;
  Future<SesionLocal> _abrir() async {
    final sesion = await widget.abrir();
    if (!mounted) {
      await sesion.cerrar();
    } else {
      _sesion = sesion;
    }
    return sesion;
  }

  @override
  void initState() {
    super.initState();
    _inicio = _abrir();
  }

  @override
  void dispose() {
    unawaited(_sesion?.cerrar() ?? Future<void>.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<SesionLocal>(
    future: _inicio,
    builder: (context, estado) {
      if (estado.hasData) return CanastaApp(sesionLocal: estado.data);
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: estado.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudo abrir el almacenamiento.'),
                        TextButton(
                          onPressed: () => setState(() {
                            _inicio = _abrir();
                          }),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}
