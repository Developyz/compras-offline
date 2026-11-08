import 'package:flutter/material.dart';

/// Vista de preparación sin datos reales, acciones simuladas ni ViewModel.
class BienvenidaView extends StatelessWidget {
  const BienvenidaView({super.key});

  static const _verde = Color(0xFF154B3E);

  @override
  Widget build(BuildContext context) {
    // TODO: incorporar resumen local y navegación desde el ViewModel de Inicio.
    // TODO: mostrar períodos parciales sin presentarlos como un mes completo.
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: _verde,
                        size: 32,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'canasta.',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _verde,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Tu compra,\nmás clara.',
                    style: TextStyle(
                      fontSize: 38,
                      height: 1.12,
                      fontWeight: FontWeight.w700,
                      color: _verde,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Un espacio para organizar tus productos, '
                    'revisar tus tickets y preparar tu canasta familiar.',
                    style: TextStyle(fontSize: 17, color: Color(0xFF65786F)),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _verde,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Color(0xFFD6ED98),
                          size: 34,
                        ),
                        SizedBox(height: 18),
                        Text(
                          'Cada compra cuenta.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tus gastos en guaraníes, de un vistazo.',
                          style: TextStyle(color: Color(0xFFD4E1D4)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Vista de preparación · Sin datos reales',
                    style: TextStyle(fontSize: 13, color: Color(0xFF65786F)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
