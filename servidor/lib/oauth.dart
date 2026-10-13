import 'dart:convert';

import 'package:shelf/shelf.dart';

import 'config.dart';
import 'datos.dart';
import 'pagina_login.dart';
import 'tokens.dart';

// ---------------------------------------------------------------------------
// OAuth 2.0: el PROTOCOLO para obtener el token
// ---------------------------------------------------------------------------

Response _json(int estado, Object cuerpo) => Response(
      estado,
      body: jsonEncode(cuerpo),
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
      },
    );

Response _errorOAuth(String error, String descripcion, [int estado = 400]) =>
    _json(estado, {'error': error, 'error_description': descripcion});

Response _html(String html, [int estado = 200]) => Response(
      estado,
      body: html,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );

Response _volverALaApp(String redirectUri, Map<String, String> parametros) {
  final destino = Uri.parse(redirectUri).replace(queryParameters: parametros);
  print('  -> redirige a la app: $destino');
  return Response.found(destino.toString());
}

Future<Map<String, String>> _leerFormulario(Request request) async =>
    Uri.splitQueryString(await request.readAsString());

List<String> _scopesValidos(String? pedido) {
  final lista = (pedido ?? '')
      .split(' ')
      .where(scopesDisponibles.containsKey)
      .toSet()
      .toList();
  return lista.isEmpty ? ['perfil'] : lista;
}

String? _validarCliente(String? clienteId, String? redirectUri) {
  final cliente = clientes[clienteId];
  if (cliente == null) return 'client_id desconocido: $clienteId';
  if (!cliente.redirectUris.contains(redirectUri)) {
    return 'redirect_uri no registrado: $redirectUri';
  }
  return null;
}

/// PASO A · GET /authorize
/// La app abre esta URL en el navegador. Mostramos el login.
Response autorizarGet(Request request) {
  final p = request.url.queryParameters;
  final error = _validarCliente(p['client_id'], p['redirect_uri']);
  if (error != null) return _html('<h1>Solicitud inválida</h1><p>$error</p>', 400);

  if (p['response_type'] != 'code') {
    return _volverALaApp(p['redirect_uri']!, {
      'error': 'unsupported_response_type',
      'state': p['state'] ?? '',
    });
  }
  if (p['code_challenge'] == null || p['code_challenge_method'] != 'S256') {
    return _volverALaApp(p['redirect_uri']!, {
      'error': 'invalid_request',
      'error_description': 'PKCE con S256 es obligatorio',
      'state': p['state'] ?? '',
    });
  }

  return _html(paginaLogin(
    cliente: clientes[p['client_id']]!,
    parametros: {
      for (final k in ['client_id', 'redirect_uri', 'scope', 'state', 'code_challenge'])
        k: p[k] ?? '',
    },
    scopes: _scopesValidos(p['scope']),
  ));
}

/// PASO B · POST /authorize
/// El usuario envió el formulario. Si la contraseña es correcta, creamos un
/// código de un solo uso y volvemos a la app con él.
Future<Response> autorizarPost(Request request) async {
  final f = await _leerFormulario(request);
  // Volvemos a validar: el formulario también puede venir manipulado.
  final error = _validarCliente(f['client_id'], f['redirect_uri']);
  if (error != null) return _html('<h1>Solicitud inválida</h1><p>$error</p>', 400);

  final redirectUri = f['redirect_uri']!;
  final state = f['state'] ?? '';

  if (f['accion'] == 'cancelar') {
    return _volverALaApp(redirectUri, {'error': 'access_denied', 'state': state});
  }

  final usuario = usuarios[f['usuario']?.trim().toLowerCase()];
  if (usuario == null || !usuario.claveCorrecta(f['clave'] ?? '')) {
    print('  login fallido para "${f['usuario']}"');
    return _html(
      paginaLogin(
        cliente: clientes[f['client_id']]!,
        parametros: {
          for (final k in ['client_id', 'redirect_uri', 'scope', 'state', 'code_challenge'])
            k: f[k] ?? '',
        },
        scopes: _scopesValidos(f['scope']),
        error: 'Usuario o contraseña incorrectos',
      ),
      401,
    );
  }

  final concedidos = _scopesValidos(f['scope'])
      .where((s) => s != 'admin' || usuario.rol == 'docente')
      .join(' ');

  final codigo = textoAleatorio();
  codigos[codigo] = CodigoAutorizacion(
    clienteId: f['client_id']!,
    redirectUri: redirectUri,
    usuario: usuario,
    scope: concedidos,
    codeChallenge: f['code_challenge']!,
  );
  print('  login correcto: ${usuario.usuario}, scopes concedidos: $concedidos');

  return _volverALaApp(redirectUri, {'code': codigo, 'state': state});
}

/// PASO C · POST /token
/// La app cambia el código (+ code_verifier) por los tokens.
/// También renueva el access token con un refresh token.
Future<Response> token(Request request) async {
  final f = await _leerFormulario(request);

  switch (f['grant_type']) {
    case 'authorization_code':
      final codigo = codigos.remove(f['code']);
      if (codigo == null || DateTime.now().isAfter(codigo.expira)) {
        return _errorOAuth('invalid_grant', 'Código inválido, usado o expirado');
      }
      if (codigo.clienteId != f['client_id'] ||
          codigo.redirectUri != f['redirect_uri']) {
        return _errorOAuth('invalid_grant', 'El código no pertenece a este cliente');
      }
      if (!verificarPkce(f['code_verifier'] ?? '', codigo.codeChallenge)) {
        return _errorOAuth('invalid_grant', 'code_verifier no coincide (PKCE)');
      }
      return _entregarTokens(codigo.clienteId, codigo.usuario, codigo.scope);

    case 'refresh_token':
      final viejo = refreshTokens.remove(f['refresh_token']);
      if (viejo == null ||
          viejo.clienteId != f['client_id'] ||
          DateTime.now().isAfter(viejo.expira)) {
        return _errorOAuth('invalid_grant', 'Refresh token inválido o expirado');
      }
      print('  refresh token usado por ${viejo.usuario.usuario}');
      return _entregarTokens(viejo.clienteId, viejo.usuario, viejo.scope);

    default:
      return _errorOAuth('unsupported_grant_type', 'grant_type no soportado');
  }
}

Response _entregarTokens(String clienteId, Usuario usuario, String scope) {
  final refresh = textoAleatorio();
  refreshTokens[refresh] = RefreshToken(clienteId, usuario, scope);

  return _json(200, {
    'access_token': emitirAccessToken(usuario, scope),
    'token_type': 'Bearer',
    'expires_in': Config.vidaAccessToken.inSeconds,
    'refresh_token': refresh,
    'scope': scope,
  });
}

Future<Response> revocar(Request request) async {
  final f = await _leerFormulario(request);
  refreshTokens.remove(f['token']);
  return Response.ok('');
}
