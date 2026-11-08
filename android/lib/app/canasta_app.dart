import 'package:flutter/material.dart';

import '../features/inicio/views/bienvenida_view.dart';

/// Configuración visual inicial, independiente de persistencia y sincronización.
class CanastaApp extends StatelessWidget {
  const CanastaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canasta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF154B3E)),
        scaffoldBackgroundColor: const Color(0xFFFAFBF7),
      ),
      // TODO: trasladar las vistas del prototipo HTML a rutas Flutter.
      home: const BienvenidaView(),
    );
  }
}
