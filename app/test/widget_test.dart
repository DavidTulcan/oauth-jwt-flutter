import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llave_segura/auth/auth_service.dart';
import 'package:llave_segura/auth/jwt_info.dart';
import 'package:llave_segura/auth/pkce.dart';
import 'package:llave_segura/screens/login_screen.dart';

String _b64(Map<String, dynamic> m) =>
    base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');

void main() {
  test('PKCE: ejemplo oficial del RFC 7636', () {
    expect(
      Pkce.desafio('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
    final p = Pkce.generar();
    expect(p.verifier.length, 43);
    expect(p.challenge, Pkce.desafio(p.verifier));
  });

  test('JwtInfo lee header y payload, y alterar conserva la firma', () {
    final ahora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final token = '${_b64({'alg': 'HS256', 'typ': 'JWT'})}.'
        '${_b64({'sub': 'u-001', 'name': 'Ana', 'rol': 'estudiante', 'scope': 'perfil notas', 'iat': ahora, 'exp': ahora + 60})}'
        '.firmaFalsa';
    final jwt = JwtInfo.decodificar(token);

    expect(jwt.header['alg'], 'HS256');
    expect(jwt.nombre, 'Ana');
    expect(jwt.scopes, ['perfil', 'notas']);
    expect(jwt.expirado, isFalse);

    final alterado = JwtInfo.decodificar(jwt.alterar({'rol': 'docente'}));
    expect(alterado.rol, 'docente');
    expect(alterado.firmaB64, 'firmaFalsa');
  });

  for (final tamano in const [Size(360, 740), Size(1280, 800)]) {
    testWidgets('login sin desbordes en ${tamano.width.toInt()} px',
        (tester) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: LoginScreen(auth: AuthService())));
      expect(tester.takeException(), isNull);
      expect(find.text('Iniciar sesión con OAuth'), findsOneWidget);
    });
  }
}
