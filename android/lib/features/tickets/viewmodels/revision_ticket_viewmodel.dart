import 'package:flutter/foundation.dart';

import '../../../domain/models/compra.dart';
import '../../../domain/models/valores_compra.dart';
import '../../../domain/services/revision_compra.dart';

/// Coordina revisión en memoria. No navega, no guarda ni conoce los ejemplos.
class RevisionTicketViewModel extends ChangeNotifier {
  RevisionTicketViewModel(Compra borrador)
    : _borrador = _exigirBorrador(borrador);

  Compra _borrador;
  Compra get borrador => _borrador;
  bool get puedeContinuar => _borrador.revision.puedeContinuar;
  List<String> get camposPendientes => List.unmodifiable(
    _borrador.revision.incidencias
        .where((e) => e.motivo == MotivoRevision.campoPendiente)
        .map((e) => e.campo),
  );
  bool get totalCoincide =>
      _borrador.totalTicket?.valor == _borrador.resumen.totalCalculado.valor;

  static Compra _exigirBorrador(Compra compra) {
    if (compra.estado != EstadoCompra.borrador) {
      throw ArgumentError('Se requiere una compra en borrador');
    }
    return compra;
  }

  void cargarBorrador(Compra compra) {
    _borrador = _exigirBorrador(compra);
    notifyListeners();
  }

  void marcarCampoRevisado(String campo) {
    if (!camposPendientes.contains(campo)) {
      return;
    }
    _borrador = _copiar(
      campos: camposPendientes.where((e) => e != campo).toList(),
    );
    notifyListeners();
  }

  void actualizarTotalTicket(ImportePyg? total) {
    _borrador = _copiar(total: total, cambiarTotal: true);
    notifyListeners();
  }

  /// Solo construye una compra validada para vista previa. No es persistencia.
  Compra prepararConfirmacion() {
    if (!puedeContinuar) {
      throw StateError('Falta resolver la revisión');
    }
    return _copiar(estado: EstadoCompra.confirmada);
  }

  Compra _copiar({
    List<String>? campos,
    ImportePyg? total,
    bool cambiarTotal = false,
    EstadoCompra estado = EstadoCompra.borrador,
  }) => Compra(
    id: _borrador.id,
    fechaCompra: _borrador.fechaCompra,
    fechaLocal: _borrador.fechaLocal,
    estado: estado,
    detalles: _borrador.detalles,
    descuentos: _borrador.descuentos,
    totalTicket: cambiarTotal ? total : _borrador.totalTicket,
    comercioId: _borrador.comercioId,
    sucursal: _borrador.sucursal,
    canastaId: _borrador.canastaId,
    ajuste: _borrador.resumen.ajuste,
    observaciones: _borrador.observaciones,
    camposPorRevisar: campos ?? camposPendientes,
  );
}
