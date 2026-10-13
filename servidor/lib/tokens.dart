import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import 'config.dart';
import 'datos.dart';

final _random = Random.secure();

String textoAleatorio([int bytes = 32]) => base64Url
    .encode(List<int>.generate(bytes, (_) => _random.nextInt(256)))
    .replaceAll('=', '');

bool verificarPkce(String codeVerifier, String codeChallenge) {
  final hash = sha256.convert(ascii.encode(codeVerifier)).bytes;
  final calculado = base64Url.encode(hash).replaceAll('=', '');
  return calculado == codeChallenge;
}

// ---------------------------------------------------------------------------
// JWT: el FORMATO del access token
// ---------------------------------------------------------------------------

/// Crea un access token JWT firmado con HS256.
String emitirAccessToken(Usuario usuario, String scope) {
  final jwt = JWT(
    {
      'scope': scope,
      'name': usuario.nombre,
      'rol': usuario.rol,
    },
    issuer: Config.emisor, // iss: quién lo emite
    subject: usuario.id, // sub: de quién es
    audience: Audience.one(Config.audiencia), // aud: para qué API
    jwtId: textoAleatorio(8), // jti: identificador único
  );
  return jwt.sign(
    SecretKey(Config.secretoJwt),
    algorithm: JWTAlgorithm.HS256,
    expiresIn: Config.vidaAccessToken,
  );
}

JWT validarAccessToken(String token) => JWT.verify(
      token,
      SecretKey(Config.secretoJwt),
      issuer: Config.emisor,
      audience: Audience.one(Config.audiencia),
    );

// ---------------------------------------------------------------------------
// Datos temporales que guarda el servidor
// ---------------------------------------------------------------------------

class CodigoAutorizacion {
  final String clienteId;
  final String redirectUri;
  final Usuario usuario;
  final String scope;
  final String codeChallenge;
  final DateTime expira;

  CodigoAutorizacion({
    required this.clienteId,
    required this.redirectUri,
    required this.usuario,
    required this.scope,
    required this.codeChallenge,
  }) : expira = DateTime.now().add(Config.vidaCodigo);
}

class RefreshToken {
  final String clienteId;
  final Usuario usuario;
  final String scope;
  final DateTime expira;

  RefreshToken(this.clienteId, this.usuario, this.scope)
      : expira = DateTime.now().add(Config.vidaRefreshToken);
}

final codigos = <String, CodigoAutorizacion>{};
final refreshTokens = <String, RefreshToken>{};
