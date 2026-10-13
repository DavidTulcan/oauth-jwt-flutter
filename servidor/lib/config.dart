import 'dart:io';

/// Configuración leída de variables de entorno (docker-compose.yml).
class Config {
  static final String emisor =
      Platform.environment['ISSUER'] ?? 'http://localhost:9000';

  static const String audiencia = 'api-llave-segura';

  static final String secretoJwt =
      Platform.environment['JWT_SECRET'] ?? 'secreto-solo-para-desarrollo';

  static final Duration vidaAccessToken = Duration(
    seconds: int.parse(Platform.environment['ACCESS_TTL_SECONDS'] ?? '60'),
  );

  static const Duration vidaRefreshToken = Duration(days: 1);
  static const Duration vidaCodigo = Duration(minutes: 1);

  static final int puerto =
      int.parse(Platform.environment['PORT'] ?? '8080');
}
