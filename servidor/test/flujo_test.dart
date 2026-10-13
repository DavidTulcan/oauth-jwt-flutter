import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:servidor_oauth/app.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const base = 'http://localhost:9000';
const cliente = 'llave-segura-app';
const retorno = 'http://localhost:8082/auth.html';

final app = crearApp();

Future<Response> enviar(String metodo, String ruta,
        {Map<String, String>? form, String? bearer}) =>
    Future.value(app(Request(
      metodo,
      Uri.parse('$base$ruta'),
      body: form == null
          ? null
          : form.entries
              .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
              .join('&'),
      headers: {
        if (form != null) 'content-type': 'application/x-www-form-urlencoded',
        if (bearer != null) 'authorization': 'Bearer $bearer',
      },
    )));

String desafio(String verifier) =>
    base64Url.encode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

/// Hace login como [usuario] y devuelve la respuesta de /token.
Future<Map<String, dynamic>> login(String usuario, String clave,
    {String scope = 'perfil notas'}) async {
  const verifier = 'verificador-de-prueba-con-mas-de-43-caracteres-123456';
  final r = await enviar('POST', '/authorize', form: {
    'client_id': cliente,
    'redirect_uri': retorno,
    'scope': scope,
    'state': 'xyz',
    'code_challenge': desafio(verifier),
    'usuario': usuario,
    'clave': clave,
    'accion': 'permitir',
  });
  expect(r.statusCode, 302);
  final destino = Uri.parse(r.headers['location']!);
  expect(destino.queryParameters['state'], 'xyz');

  final t = await enviar('POST', '/token', form: {
    'grant_type': 'authorization_code',
    'code': destino.queryParameters['code']!,
    'redirect_uri': retorno,
    'client_id': cliente,
    'code_verifier': verifier,
  });
  expect(t.statusCode, 200);
  return jsonDecode(await t.readAsString()) as Map<String, dynamic>;
}

void main() {
  test('GET /authorize sin PKCE devuelve error a la app', () async {
    final r = await enviar('GET',
        '/authorize?response_type=code&client_id=$cliente&redirect_uri=$retorno');
    expect(Uri.parse(r.headers['location']!).queryParameters['error'],
        'invalid_request');
  });

  test('redirect_uri no registrado no redirige', () async {
    final r = await enviar('GET',
        '/authorize?response_type=code&client_id=$cliente&redirect_uri=http://malo.com');
    expect(r.statusCode, 400);
  });

  test('flujo completo: código + PKCE -> JWT -> API', () async {
    final tokens = await login('ana', 'ana123');
    expect(tokens['token_type'], 'Bearer');
    expect((tokens['access_token'] as String).split('.'), hasLength(3));

    final perfil = await enviar('GET', '/api/perfil', bearer: tokens['access_token']);
    expect(perfil.statusCode, 200);
    expect(jsonDecode(await perfil.readAsString())['nombre'], 'David Tulcan');
  });

  test('el código solo sirve una vez', () async {
    const verifier = 'otro-verificador-de-prueba-con-mas-de-43-caracteres-xx';
    final r = await enviar('POST', '/authorize', form: {
      'client_id': cliente, 'redirect_uri': retorno, 'scope': 'perfil',
      'state': 's', 'code_challenge': desafio(verifier),
      'usuario': 'ana', 'clave': 'ana123', 'accion': 'permitir',
    });
    final codigo = Uri.parse(r.headers['location']!).queryParameters['code']!;
    final form = {
      'grant_type': 'authorization_code', 'code': codigo,
      'redirect_uri': retorno, 'client_id': cliente, 'code_verifier': verifier,
    };
    expect((await enviar('POST', '/token', form: form)).statusCode, 200);
    expect((await enviar('POST', '/token', form: form)).statusCode, 400);
  });

  test('code_verifier incorrecto es rechazado (PKCE)', () async {
    final r = await enviar('POST', '/authorize', form: {
      'client_id': cliente, 'redirect_uri': retorno, 'scope': 'perfil',
      'state': 's', 'code_challenge': desafio('verificador-correcto-0123456789-0123456789'),
      'usuario': 'ana', 'clave': 'ana123', 'accion': 'permitir',
    });
    final codigo = Uri.parse(r.headers['location']!).queryParameters['code']!;
    final t = await enviar('POST', '/token', form: {
      'grant_type': 'authorization_code', 'code': codigo, 'redirect_uri': retorno,
      'client_id': cliente, 'code_verifier': 'verificador-robado-por-un-atacante-000000',
    });
    expect(t.statusCode, 400);
  });

  test('contraseña incorrecta no entrega código', () async {
    final r = await enviar('POST', '/authorize', form: {
      'client_id': cliente, 'redirect_uri': retorno, 'scope': 'perfil',
      'state': 's', 'code_challenge': desafio('x' * 43),
      'usuario': 'ana', 'clave': 'mala', 'accion': 'permitir',
    });
    expect(r.statusCode, 401);
  });

  test('JWT alterado: 401 por firma inválida', () async {
    final tokens = await login('ana', 'ana123');
    final partes = (tokens['access_token'] as String).split('.');
    final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))));
    payload['rol'] = 'docente';
    payload['scope'] = 'perfil notas admin';
    partes[1] = base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');

    final r = await enviar('GET', '/api/admin', bearer: partes.join('.'));
    expect(r.statusCode, 401);
    // Las cabeceras deben ser ASCII o el navegador descarta la respuesta.
    expect(r.headers['www-authenticate']!.codeUnits.every((c) => c < 128), isTrue);
  });

  test('scope insuficiente: 403', () async {
    final tokens = await login('ana', 'ana123', scope: 'perfil');
    final r = await enviar('GET', '/api/notas', bearer: tokens['access_token']);
    expect(r.statusCode, 403);
  });

  test('un estudiante no recibe el scope admin aunque lo pida', () async {
    final tokens = await login('ana', 'ana123', scope: 'perfil admin');
    expect(tokens['scope'], 'perfil');
  });

  test('docente con scope admin entra al panel', () async {
    final tokens = await login('profe', 'profe123', scope: 'perfil admin');
    final r = await enviar('GET', '/api/admin', bearer: tokens['access_token']);
    expect(r.statusCode, 200);
  });

  test('refresh token rota y entrega un nuevo JWT', () async {
    final tokens = await login('ana', 'ana123');
    final form = {
      'grant_type': 'refresh_token',
      'refresh_token': tokens['refresh_token'] as String,
      'client_id': cliente,
    };
    final r1 = await enviar('POST', '/token', form: form);
    expect(r1.statusCode, 200);
    final nuevos = jsonDecode(await r1.readAsString());
    expect(nuevos['refresh_token'], isNot(tokens['refresh_token']));
    // el refresh token viejo ya no sirve
    expect((await enviar('POST', '/token', form: form)).statusCode, 400);
  });
}
