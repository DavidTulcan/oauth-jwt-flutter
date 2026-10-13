import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'api.dart';
import 'config.dart';
import 'oauth.dart';

Middleware cors() {
  const cabeceras = {
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'Authorization, Content-Type',
    'access-control-expose-headers': 'WWW-Authenticate',
  };
  return (Handler siguiente) => (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: cabeceras);
        }
        final respuesta = await siguiente(request);
        return respuesta.change(headers: cabeceras);
      };
}

Handler crearApp() {
  final rutas = Router()
    ..get('/authorize', autorizarGet)
    ..post('/authorize', autorizarPost)
    ..post('/token', token)
    ..post('/revoke', revocar)
    ..get('/api/perfil', protegido('perfil', perfil))
    ..get('/api/notas', protegido('notas', notas))
    ..get('/api/admin', protegido('admin', panelDocente))
    ..get('/', (Request _) => Response.ok(
          jsonEncode({
            'servicio': 'Servidor OAuth 2.0 + API JWT',
            'emisor': Config.emisor,
            'vida_access_token_segundos': Config.vidaAccessToken.inSeconds,
          }),
          headers: {'content-type': 'application/json'},
        ));

  return const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(cors())
      .addHandler(rutas.call);
}
