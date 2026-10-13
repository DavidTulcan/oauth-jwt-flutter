import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';
import '../config.dart';

class RespuestaApi {
  final String ruta;
  final int estado;
  final Object? cuerpo;
  final bool renovado;

  const RespuestaApi(this.ruta, this.estado, this.cuerpo, {this.renovado = false});

  bool get exito => estado >= 200 && estado < 300;
}

/// Llama a la API protegida enviando el JWT en la cabecera Authorization.
class ApiClient {
  final AuthService auth;

  ApiClient(this.auth);

  Future<RespuestaApi> get(String ruta, {String? tokenManual}) async {
    final token = tokenManual ?? auth.accessToken;
    final http.Response respuesta;
    var renovado = false;
    try {
      var r = await _enviar(ruta, token);

      if (tokenManual == null &&
          r.statusCode == 401 &&
          utf8.decode(r.bodyBytes).contains('expiró') &&
          await auth.renovar()) {
        r = await _enviar(ruta, auth.accessToken);
        renovado = true;
      }
      respuesta = r;
    } catch (e) {
      auth.registrar(TipoEvento.error, 'GET $ruta → sin conexión', '$e');
      return RespuestaApi(ruta, 0, {'error': 'No se pudo conectar', 'detalle': '$e'});
    }

    final cuerpo = respuesta.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(respuesta.bodyBytes));
    auth.registrar(
      respuesta.statusCode < 300 ? TipoEvento.api : TipoEvento.error,
      'GET $ruta → ${respuesta.statusCode}',
      cuerpo is Map && cuerpo['error_description'] != null
          ? '${cuerpo['error_description']}'
          : '',
    );
    return RespuestaApi(ruta, respuesta.statusCode, cuerpo, renovado: renovado);
  }

  Future<http.Response> _enviar(String ruta, String? token) => http.get(
        Uri.parse('${Config.servidor}$ruta'),
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );
}
