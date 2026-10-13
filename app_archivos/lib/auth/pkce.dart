import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

final _random = Random.secure();

/// Texto aleatorio seguro en Base64URL sin "=".
String textoAleatorio(int bytes) => base64Url
    .encode(List<int>.generate(bytes, (_) => _random.nextInt(256)))
    .replaceAll('=', '');

/// PKCE (RFC 7636): la app inventa un secreto de un solo uso (verifier) y
/// solo envía su huella SHA-256 (challenge) al pedir el código. Al cambiar el
/// código por tokens envía el verifier: quien robe el código no lo tiene.
class Pkce {
  final String verifier;
  final String challenge;

  Pkce._(this.verifier, this.challenge);

  factory Pkce.generar() {
    final verifier = textoAleatorio(32);
    return Pkce._(verifier, desafio(verifier));
  }

  static String desafio(String verifier) {
    final hash = sha256.convert(ascii.encode(verifier)).bytes;
    return base64Url.encode(hash).replaceAll('=', '');
  }
}
