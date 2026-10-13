import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import 'datos.dart';
import 'tokens.dart';

// ---------------------------------------------------------------------------
// Servidor de recursos: la API que exige un JWT válido
// ---------------------------------------------------------------------------

Response _json(int estado, Object cuerpo, [Map<String, String> extra = const {}]) =>
    Response(
      estado,
      body: jsonEncode(cuerpo),
      headers: {'content-type': 'application/json; charset=utf-8', ...extra},
    );

Response _noAutorizado(String error, String descripcion) => _json(
      401,
      {'error': error, 'error_description': descripcion},
      {'www-authenticate': 'Bearer error="$error"'},
    );

Handler protegido(String scope, Response Function(JWT jwt) endpoint) {
  return (Request request) {
    final cabecera = request.headers['authorization'] ?? '';
    if (!cabecera.startsWith('Bearer ')) {
      return _noAutorizado('invalid_request', 'Falta la cabecera Authorization: Bearer');
    }

    final JWT jwt;
    try {
      jwt = validarAccessToken(cabecera.substring(7));
    } on JWTExpiredException {
      print('  JWT rechazado: expiró');
      return _noAutorizado('invalid_token', 'El token expiró');
    } on JWTException catch (e) {
      print('  JWT rechazado: ${e.message}');
      return _noAutorizado('invalid_token', 'Token inválido: ${e.message}');
    }

    final payload = jwt.payload as Map<String, dynamic>;
    final scopes = (payload['scope'] as String? ?? '').split(' ');
    if (!scopes.contains(scope)) {
      print('  JWT válido de ${jwt.subject}, pero sin scope "$scope"');
      return _json(403, {
        'error': 'insufficient_scope',
        'error_description': 'Se necesita el scope "$scope"',
      });
    }

    print('  JWT válido: sub=${jwt.subject} scope="${payload['scope']}"');
    return endpoint(jwt);
  };
}

Response perfil(JWT jwt) {
  final p = jwt.payload as Map<String, dynamic>;
  final exp = DateTime.fromMillisecondsSinceEpoch((p['exp'] as int) * 1000);
  return _json(200, {
    'id': jwt.subject,
    'nombre': p['name'],
    'rol': p['rol'],
    'scope': p['scope'],
    'token_expira_en_segundos': exp.difference(DateTime.now()).inSeconds,
  });
}

Response notas(JWT jwt) {
  final lista = notasPorUsuario[jwt.subject] ?? [];
  final promedio = lista.isEmpty
      ? null
      : lista.map((n) => n['nota'] as double).reduce((a, b) => a + b) /
          lista.length;
  return _json(200, {
    'estudiante': (jwt.payload as Map)['name'],
    'notas': lista,
    'promedio': promedio == null ? null : double.parse(promedio.toStringAsFixed(2)),
  });
}

Response panelDocente(JWT jwt) {
  if ((jwt.payload as Map)['rol'] != 'docente') {
    return _json(403, {'error': 'forbidden', 'error_description': 'Solo docentes'});
  }
  final estudiantes =
      usuarios.values.where((u) => u.rol == 'estudiante').toList();
  return _json(200, {
    'curso': 'Aplicaciones Móviles',
    'estudiantes': [
      for (final u in estudiantes)
        {'nombre': u.nombre, 'materias': notasPorUsuario[u.id]?.length ?? 0},
    ],
    'sesiones_activas': refreshTokens.length,
  });
}
