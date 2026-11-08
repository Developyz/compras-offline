/// Validaciones compartidas de entidades; no generan IDs ni consultan catálogos.
abstract final class DatosEntidad {
  static String id(String valor) {
    if (RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).stringMatch(valor) !=
        valor) {
      throw ArgumentError.value(valor, 'id', 'Se requiere un UUID');
    }
    return valor.toLowerCase();
  }

  static String? idOpcional(String? valor) => valor == null ? null : id(valor);

  static String texto(String valor, int maximo) {
    if (valor.trim().isEmpty || valor.runes.length > maximo) {
      throw ArgumentError('Texto obligatorio de hasta $maximo caracteres');
    }
    return valor;
  }

  static String? textoOpcional(String? valor, int maximo) {
    if (valor != null && valor.runes.length > maximo) {
      throw ArgumentError('Texto de hasta $maximo caracteres');
    }
    return valor;
  }
}

/// Fecha civil del comercio: independiente de la zona horaria del dispositivo.
final class FechaLocalCompra {
  FechaLocalCompra(String valor) : valor = _validar(valor);
  final String valor;

  static String _validar(String valor) {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').stringMatch(valor) != valor) {
      throw FormatException('Fecha requerida: AAAA-MM-DD');
    }
    final partes = valor.split('-').map(int.parse).toList();
    final fecha = DateTime.utc(partes[0], partes[1], partes[2]);
    if (partes[0] < 1 ||
        fecha.year != partes[0] ||
        fecha.month != partes[1] ||
        fecha.day != partes[2]) {
      throw FormatException('Fecha inexistente');
    }
    return valor;
  }
}
