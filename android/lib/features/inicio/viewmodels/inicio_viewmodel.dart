import 'package:flutter/foundation.dart';

import '../../../domain/models/resumen_inicio.dart';
import '../../../domain/models/identidad_y_fecha.dart';
import '../../../domain/repositories/repositorios.dart';

class InicioViewModel extends ChangeNotifier {
  InicioViewModel(this.repositorio, {DateTime Function()? reloj})
    : reloj = reloj ?? DateTime.now;
  final RepositorioCompras repositorio;
  final DateTime Function() reloj;
  ResumenInicio? resumen;
  bool cargando = false;
  bool fallo = false;
  int _revision = 0;
  bool _cerrado = false;
  Future<void> cargar() async {
    if (_cerrado) return;
    final revision = ++_revision;
    cargando = true;
    fallo = false;
    notifyListeners();
    final hoy = reloj();
    try {
      final nuevo = await repositorio.resumenInicio(
        FechaLocalCompra(
          '${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}',
        ),
      );
      if (_cerrado || revision != _revision) return;
      resumen = nuevo;
    } catch (_) {
      if (_cerrado || revision != _revision) return;
      fallo = true;
      resumen = null;
    }
    cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
