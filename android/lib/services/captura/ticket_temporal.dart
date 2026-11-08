import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// Solo directorios propios de captura, nunca galería ni archivos seleccionados.
abstract final class TicketTemporal {
  static const prefijo = 'alisto_ticket_';
  static Future<void> limpiarHuerfanas(Directory temporal) async {
    if (!await temporal.exists()) return;
    await for (final entrada in temporal.list(followLinks: false)) {
      if (entrada is Directory &&
          entrada.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last
              .startsWith(prefijo)) {
        await entrada.delete(recursive: true);
      }
    }
  }

  static Future<String> reconocerYBorrar(
    File captura, {
    Future<String> Function(String)? reconocer,
    Directory? temporal,
  }) async {
    Directory? propia;
    try {
      propia = await (temporal ?? await getTemporaryDirectory()).createTemp(
        prefijo,
      );
      final imagen = await captura.copy('${propia.path}/ticket.jpg');
      await captura.delete();
      if (reconocer != null) return await reconocer(imagen.path);
      final lector = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        return (await lector.processImage(InputImage.fromFilePath(imagen.path)))
            .text;
      } finally {
        await lector.close();
      }
    } finally {
      try {
        if (await captura.exists()) await captura.delete();
      } finally {
        if (propia != null && await propia.exists()) {
          await propia.delete(recursive: true);
        }
      }
    }
  }
}
