import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/compra.dart';
import '../../../domain/models/valores_compra.dart';
import '../../../domain/services/revision_compra.dart';
import '../../../domain/repositories/repositorios.dart';

enum EstadoGuardado { listo, guardando, error, guardado }

/// Coordina revisión y guardado por contrato. No navega ni conoce SQLite o ejemplos.
class RevisionTicketViewModel extends ChangeNotifier {
  RevisionTicketViewModel(
    Compra borrador, {
    this.repositorio,
    String Function()? nuevoId,
    Map<String, String> unidades = const {},
  }) : _borrador = _exigirBorrador(borrador),
       _nuevoId = nuevoId ?? const Uuid().v4,
       unidades = Map.unmodifiable(unidades);

  final RepositorioCompras? repositorio;
  final String Function() _nuevoId;
  final Map<String, String> unidades;
  EscrituraLocal<Compra>? _escritura;
  bool _cerrado = false;
  EstadoGuardado _estado = EstadoGuardado.listo;
  EstadoGuardado get estadoGuardado => _estado;
  ReciboGuardadoLocal? _recibo;
  ReciboGuardadoLocal? get recibo => _recibo;
  Compra? get compraGuardada =>
      _estado == EstadoGuardado.guardado ? _escritura?.entidad : null;
  Object? _error;
  Object? get errorGuardado => _error;
  bool get permiteGuardar => repositorio != null;
  bool get puedeEditar =>
      !_cerrado && _escritura == null && _estado != EstadoGuardado.guardando;
  bool get puedeGuardar =>
      permiteGuardar &&
      puedeContinuar &&
      !_cerrado &&
      _estado != EstadoGuardado.guardando &&
      _estado != EstadoGuardado.guardado;

  void _exigirEditable() {
    if (!puedeEditar) {
      throw StateError('La solicitud de guardado ya está fijada');
    }
  }

  void _avisar() {
    if (!_cerrado) notifyListeners();
  }

  Future<void> guardar() async {
    if (!puedeGuardar) return;
    _estado = EstadoGuardado.guardando;
    _error = null;
    _avisar();
    try {
      _escritura ??= EscrituraLocal(
        entidad: prepararConfirmacion(),
        operacionId: _nuevoId(),
        versionBase: BigInt.zero,
      );
      final recibo = await repositorio!.guardarYEncolar(_escritura!);
      if (recibo.entidadId != _escritura!.entidad.id ||
          recibo.operacionId != _escritura!.operacionId) {
        throw StateError('El recibo no corresponde a la solicitud');
      }
      _recibo = recibo;
      _estado = EstadoGuardado.guardado;
    } catch (error) {
      _error = error;
      _estado = EstadoGuardado.error;
    }
    _avisar();
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }

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
    _exigirEditable();
    _borrador = _exigirBorrador(compra);
    notifyListeners();
  }

  void marcarCampoRevisado(String campo) {
    _exigirEditable();
    if (!camposPendientes.contains(campo)) {
      return;
    }
    _borrador = _copiar(
      campos: camposPendientes.where((e) => e != campo).toList(),
    );
    notifyListeners();
  }

  void actualizarTotalTicket(ImportePyg? total) {
    _exigirEditable();
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
