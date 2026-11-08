/// Límites del contrato. BigInt evita desbordamientos durante operaciones.
abstract final class Entero64 {
  static final minimo = -(BigInt.one << 63);
  static final maximo = (BigInt.one << 63) - BigInt.one;

  static BigInt verificar(BigInt valor) {
    if (valor < minimo || valor > maximo) {
      throw RangeError('Valor fuera del rango int64');
    }
    return valor;
  }
}

/// Guaraníes enteros no negativos. No acepta decimales ni separadores locales.
final class ImportePyg {
  ImportePyg(BigInt valor) : valor = Entero64.verificar(valor) {
    if (valor.isNegative) {
      throw ArgumentError('El importe no puede ser negativo');
    }
  }

  factory ImportePyg.desdeTexto(String texto) {
    if (RegExp(r'^\d+$').stringMatch(texto) != texto) {
      throw FormatException('Se requieren guaraníes enteros sin separadores');
    }
    return ImportePyg(BigInt.parse(texto));
  }

  final BigInt valor;
}

/// Cantidad positiva expresada en milésimas de su unidad de venta.
final class CantidadCompra {
  CantidadCompra(BigInt milesimas) : milesimas = Entero64.verificar(milesimas) {
    if (milesimas <= BigInt.zero) {
      throw ArgumentError('La cantidad debe ser positiva');
    }
  }

  /// Texto canónico decimal, hasta tres posiciones. La UI localizará la entrada.
  factory CantidadCompra.desdeTexto(String texto) {
    if (RegExp(r'^\d+(\.\d{1,3})?$').stringMatch(texto) != texto) {
      throw FormatException('Cantidad decimal con hasta tres posiciones');
    }
    final partes = texto.split('.');
    final fraccion = partes.length == 2 ? partes[1].padRight(3, '0') : '000';
    return CantidadCompra(
      BigInt.parse(partes.first) * BigInt.from(1000) + BigInt.parse(fraccion),
    );
  }

  final BigInt milesimas;
}
