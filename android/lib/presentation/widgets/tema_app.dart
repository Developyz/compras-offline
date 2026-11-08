import 'package:flutter/material.dart';

Color fondoApp(BuildContext c) => Theme.of(c).scaffoldBackgroundColor;
Color superficieApp(BuildContext c) => Theme.of(c).colorScheme.surface;
Color suaveApp(BuildContext c) =>
    Theme.of(c).colorScheme.surfaceContainerHighest;
Color textoVerde(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFFD6ED98)
    : const Color(0xFF154B3E);
Color textoSecundario(BuildContext c) =>
    Theme.of(c).colorScheme.onSurfaceVariant;
Color bordeApp(BuildContext c) => Theme.of(c).dividerColor;

class ControlTema extends InheritedWidget {
  const ControlTema({required this.alternar, required super.child, super.key});
  final VoidCallback alternar;
  static ControlTema? of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<ControlTema>();
  @override
  bool updateShouldNotify(ControlTema oldWidget) =>
      alternar != oldWidget.alternar;
}
