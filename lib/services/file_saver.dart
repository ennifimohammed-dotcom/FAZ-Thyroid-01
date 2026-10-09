import 'package:flutter/services.dart';

/// Enregistrement dans « Téléchargements » et partage, via un petit pont
/// natif (MainActivity.kt) : aucun plugin tiers.
class FileSaver {
  static const MethodChannel _channel = MethodChannel('faztyroid/files');

  /// Retourne l'URI du fichier cree.
  static Future<String> saveToDownloads(String name, Uint8List bytes) async {
    final uri = await _channel
        .invokeMethod<String>('saveToDownloads', {'name': name, 'bytes': bytes});
    if (uri == null) {
      throw PlatformException(code: 'NO_RESULT', message: 'Aucun fichier créé');
    }
    return uri;
  }

  static Future<void> share(String uri) async {
    await _channel.invokeMethod<void>('shareFile', {'uri': uri});
  }
}
