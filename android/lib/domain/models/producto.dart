import 'identidad_y_fecha.dart';
import 'valores_compra.dart';

enum DimensionMedida { conteo, masa, volumen }

enum TipoVenta { unidad, peso, volumen }

/// Factores enteros hacia unidad, gramo o mililitro según la dimensión.
final class EscalaHistorica {
  EscalaHistorica({required this.dimension, required BigInt factorBase})
    : factorBase = Entero64.verificar(factorBase) {
    if (factorBase <= BigInt.zero) {
      throw ArgumentError('Factor positivo requerido');
    }
  }
  final DimensionMedida dimension;
  final BigInt factorBase;
}

final class UnidadMedida {
  UnidadMedida({
    required String id,
    required String nombre,
    required String simbolo,
    required this.escala,
  }) : id = DatosEntidad.id(id),
       nombre = DatosEntidad.texto(nombre, 200),
       simbolo = DatosEntidad.texto(simbolo, 12);
  final String id;
  final String nombre;
  final String simbolo;
  final EscalaHistorica escala;
}

final class ContenidoProducto {
  ContenidoProducto({required this.cantidad, required String unidadId})
    : unidadId = DatosEntidad.id(unidadId);
  final CantidadCompra cantidad;
  final String unidadId;
}

final class Producto {
  Producto({
    required String id,
    required String nombre,
    required this.tipoVenta,
    String? marcaId,
    String? categoriaId,
    String? presentacion,
    this.contenido,
  }) : id = DatosEntidad.id(id),
       nombre = DatosEntidad.texto(nombre, 200),
       marcaId = DatosEntidad.idOpcional(marcaId),
       categoriaId = DatosEntidad.idOpcional(categoriaId),
       presentacion = DatosEntidad.textoOpcional(presentacion, 200);
  final String id;
  final String nombre;
  final TipoVenta tipoVenta;
  final String? marcaId;
  final String? categoriaId;
  final String? presentacion;
  final ContenidoProducto? contenido;
}

final class ContenidoHistorico {
  ContenidoHistorico({
    required this.cantidad,
    required String simbolo,
    required this.escala,
  }) : simbolo = DatosEntidad.texto(simbolo, 12);
  final CantidadCompra cantidad;
  final String simbolo;
  final EscalaHistorica escala;
}

/// Copia inmutable de lo conocido al registrar; null no se rellena desde catálogo.
final class ContextoHistorico {
  ContextoHistorico({
    String? nombreProducto,
    String? presentacion,
    this.contenido,
    this.escalaCantidad,
  }) : nombreProducto = nombreProducto == null
           ? null
           : DatosEntidad.texto(nombreProducto, 200),
       presentacion = DatosEntidad.textoOpcional(presentacion, 200);

  factory ContextoHistorico.desdeProducto({
    required Producto producto,
    required UnidadMedida unidadCantidad,
    UnidadMedida? unidadContenido,
  }) {
    final contenido = producto.contenido;
    if (contenido != null && unidadContenido?.id != contenido.unidadId) {
      throw ArgumentError('Falta la unidad de contenido correspondiente');
    }
    return ContextoHistorico(
      nombreProducto: producto.nombre,
      presentacion: producto.presentacion,
      escalaCantidad: unidadCantidad.escala,
      contenido: contenido == null
          ? null
          : ContenidoHistorico(
              cantidad: contenido.cantidad,
              simbolo: unidadContenido!.simbolo,
              escala: unidadContenido.escala,
            ),
    );
  }

  final String? nombreProducto;
  final String? presentacion;
  final ContenidoHistorico? contenido;
  final EscalaHistorica? escalaCantidad;
}
