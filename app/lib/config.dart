import 'package:flutter/foundation.dart';

/// Datos del cliente OAuth. Deben coincidir con lo registrado en el servidor.
class Config {
  static const String servidor = String.fromEnvironment(
    'AUTH_SERVER',
    defaultValue: 'http://localhost:9000',
  );

  static const String clientId = 'llave-segura-app';

  static const String esquemaAndroid = 'llavesegura';

  static String get redirectUri =>
      kIsWeb ? '${Uri.base.origin}/auth.html' : '$esquemaAndroid://callback';
}
