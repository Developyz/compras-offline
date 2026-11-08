import '../models/canasta.dart';
import '../models/resumen_inicio.dart';
import '../models/compra.dart';
import '../models/identidad_y_fecha.dart';
import '../models/producto.dart';
import '../models/valores_compra.dart';

/// Una operación conserva ID y contenido durante todos sus reintentos.
/// El ViewModel fija UUID en el primer intento. Versiones de edición pendientes.
final class EscrituraLocal<T> {
  EscrituraLocal({
    required this.entidad,
    required String operacionId,
    required BigInt versionBase,
  }) : operacionId = DatosEntidad.id(operacionId),
       versionBase = Entero64.verificar(versionBase) {
    if (versionBase.isNegative) {
      throw ArgumentError('La versión base no puede ser negativa');
    }
  }
  final T entidad;
  final String operacionId;
  final BigInt versionBase;
}

/// Solo se devuelve tras confirmar entidad + outbox en una transacción local.
/// No significa que la PC haya recibido la operación.
final class ReciboGuardadoLocal {
  ReciboGuardadoLocal({required String entidadId, required String operacionId})
    : entidadId = DatosEntidad.id(entidadId),
      operacionId = DatosEntidad.id(operacionId);
  final String entidadId;
  final String operacionId;
}

/// Contratos independientes del motor. null significa ausencia comprobada, nunca error.
/// Los errores de acceso deben propagarse. Validar referencias antes de escribir.
/// guardarYEncolar: transacción atómica, recibo persistido y reintento idempotente;
/// mismo ID con otro contenido debe rechazarse. No borrar pendientes/conflictos.
abstract interface class RepositorioCompras {
  Future<ResumenInicio> resumenInicio(FechaLocalCompra hoy);
  Future<List<Compra>> listarRecientes({int limite = 100});
  Future<Compra?> obtenerPorId(String id);
  Future<ReciboGuardadoLocal> guardarYEncolar(EscrituraLocal<Compra> escritura);
}

abstract interface class RepositorioProductos {
  Future<Producto?> obtenerPorId(String id);

  /// El adaptador validará límite 1..1000; paginación queda para su implementación.
  Future<List<Producto>> buscarPorNombre(
    String consulta, {
    required int limite,
  });
  Future<ReciboGuardadoLocal> guardarYEncolar(
    EscrituraLocal<Producto> escritura,
  );
}

abstract interface class RepositorioCanastas {
  Future<Canasta?> obtenerPorId(String id);
  Future<ReciboGuardadoLocal> guardarYEncolar(
    EscrituraLocal<Canasta> escritura,
  );
}
