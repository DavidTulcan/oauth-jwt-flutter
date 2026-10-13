import 'package:flutter/material.dart';

/// Colores con significado: cada concepto tiene el suyo en toda la app.
class Colores {
  static const oauth = Color(0xFF5E35B1); // protocolo OAuth
  static const api = Color(0xFF00897B); // servidor de recursos
  static const ambar = Color(0xFFFFB300);

  // Las tres partes del JWT (mismos colores que jwt.io)
  static const header = Color(0xFFE53935);
  static const payload = Color(0xFF8E24AA);
  static const firma = Color(0xFF00ACC1);

  static const exito = Color(0xFF43A047);
  static const aviso = Color(0xFFFB8C00);
  static const error = Color(0xFFE53935);

  static const fondo = Color(0xFFF5F3FB);

  static const degradado = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4527A0), Color(0xFF00897B), Color(0xFFF9A825)],
    stops: [0, 0.6, 1],
  );

  static Color estadoHttp(int estado) => switch (estado) {
        >= 200 && < 300 => exito,
        401 => error,
        403 => aviso,
        _ => Colors.blueGrey,
      };

  /// Color de cada scope.
  static Color scope(String scope) => switch (scope) {
        'perfil' => api,
        'notas' => aviso,
        'admin' => const Color(0xFFD81B60),
        _ => Colors.blueGrey,
      };
}
