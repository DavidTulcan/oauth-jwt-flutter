import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'jwt_info.dart';
import 'pkce.dart';

/// Tipo de cada evento de la bitácora (define su color en pantalla).
enum TipoEvento { oauth, jwt, api, error }

class Evento {
  final DateTime hora = DateTime.now();
  final TipoEvento tipo;
  final String titulo;
  final String detalle;

  Evento(this.tipo, this.titulo, [this.detalle = '']);
}

class AuthService extends ChangeNotifier {
  static const _claveAccess = 'access_token';
  static const _claveRefresh = 'refresh_token';

  String? _accessToken;
  String? _refreshToken;
  final List<Evento> bitacora = [];

  String? get accessToken => _accessToken;
  bool get conectado => _accessToken != null;
  JwtInfo? get jwt =>
      _accessToken == null ? null : JwtInfo.decodificar(_accessToken!);

  void registrar(TipoEvento tipo, String titulo, [String detalle = '']) {
    bitacora.insert(0, Evento(tipo, titulo, detalle));
    notifyListeners();
  }

  Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_claveAccess);
    _refreshToken = prefs.getString(_claveRefresh);
    if (conectado) registrar(TipoEvento.jwt, 'Sesión recuperada del almacenamiento');
  }

  /// Flujo completo: navegador -> login -> código -> tokens.
  Future<void> iniciarSesion(List<String> scopes) async {
    final pkce = Pkce.generar();
    final state = textoAleatorio(16);

    final url = Uri.parse('${Config.servidor}/authorize').replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': Config.clientId,
        'redirect_uri': Config.redirectUri,
        'scope': scopes.join(' '),
        'state': state,
        'code_challenge': pkce.challenge,
        'code_challenge_method': 'S256',
      },
    );
    registrar(TipoEvento.oauth, '1. Abrir /authorize en el navegador',
        'scope="${scopes.join(' ')}"\ncode_challenge=${pkce.challenge}');

    final String retorno;
    try {
      retorno = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: Config.esquemaAndroid,
      );
    } catch (e) {
      registrar(TipoEvento.error, 'Login cancelado', '$e');
      rethrow;
    }

    final parametros = Uri.parse(retorno).queryParameters;
    if (parametros['error'] != null) {
      registrar(TipoEvento.error, 'El servidor respondió un error', parametros['error']!);
      throw Exception('El servidor respondió: ${parametros['error']}');
    }
    if (parametros['state'] != state) {
      registrar(TipoEvento.error, 'state no coincide', 'Posible ataque CSRF');
      throw Exception('El parámetro state no coincide');
    }
    final codigo = parametros['code']!;
    registrar(TipoEvento.oauth, '2. Código de autorización recibido',
        'code=${codigo.substring(0, 12)}…  (un solo uso, 1 minuto)');

    final respuesta = await http.post(
      Uri.parse('${Config.servidor}/token'),
      body: {
        'grant_type': 'authorization_code',
        'code': codigo,
        'redirect_uri': Config.redirectUri,
        'client_id': Config.clientId,
        'code_verifier': pkce.verifier,
      },
    );
    if (respuesta.statusCode != 200) {
      registrar(TipoEvento.error, 'POST /token falló', respuesta.body);
      throw Exception('No se pudo obtener el token: ${respuesta.body}');
    }
    registrar(TipoEvento.oauth, '3. POST /token con code_verifier',
        'El servidor comprobó PKCE y entregó los tokens');
    await _guardar(jsonDecode(respuesta.body) as Map<String, dynamic>);
  }

  Future<bool> renovar() async {
    if (_refreshToken == null) return false;
    final respuesta = await http.post(
      Uri.parse('${Config.servidor}/token'),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken!,
        'client_id': Config.clientId,
      },
    );
    if (respuesta.statusCode != 200) {
      registrar(TipoEvento.error, 'El refresh token ya no es válido',
          'Hay que iniciar sesión de nuevo');
      await _borrar();
      return false;
    }
    registrar(TipoEvento.oauth, 'Token renovado con refresh_token',
        'El refresh token viejo quedó invalidado (rotación)');
    await _guardar(jsonDecode(respuesta.body) as Map<String, dynamic>);
    return true;
  }

  Future<void> cerrarSesion() async {
    if (_refreshToken != null) {
      try {
        await http.post(Uri.parse('${Config.servidor}/revoke'),
            body: {'token': _refreshToken!});
      } catch (_) {
        // Sin conexión: igual se borran los tokens locales.
      }
    }
    await _borrar();
    registrar(TipoEvento.oauth, 'Sesión cerrada', 'Refresh token revocado');
  }

  Future<void> _guardar(Map<String, dynamic> datos) async {
    _accessToken = datos['access_token'] as String;
    _refreshToken = datos['refresh_token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveAccess, _accessToken!);
    await prefs.setString(_claveRefresh, _refreshToken!);
    registrar(TipoEvento.jwt, 'Nuevo JWT recibido',
        'Válido por ${datos['expires_in']} s · scope="${datos['scope']}"');
  }

  Future<void> _borrar() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveAccess);
    await prefs.remove(_claveRefresh);
    notifyListeners();
  }
}
