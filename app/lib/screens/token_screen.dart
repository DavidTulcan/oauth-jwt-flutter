import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/jwt_info.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/cuenta_regresiva.dart';

/// Inspector del JWT: el token codificado por colores y sus tres partes.
class TokenScreen extends StatelessWidget {
  final AuthService auth;

  const TokenScreen({super.key, required this.auth});

  static const _explicacionClaims = {
    'iss': 'Emisor: quién creó el token',
    'sub': 'Sujeto: el usuario dueño del token',
    'aud': 'Audiencia: la API que debe aceptarlo',
    'iat': 'Emitido en (segundos Unix)',
    'exp': 'Expira en (segundos Unix)',
    'jti': 'Identificador único del token',
    'scope': 'Permisos concedidos por OAuth',
    'name': 'Dato propio de la app',
    'rol': 'Dato propio de la app',
  };

  @override
  Widget build(BuildContext context) {
    final jwt = auth.jwt!;
    return LayoutBuilder(builder: (context, constraints) {
      final ancho = constraints.maxWidth >= 1000;
      final partes = [
        _tarjetaHeader(jwt),
        _tarjetaPayload(jwt),
        _tarjetaFirma(),
      ];
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tarjetaToken(context, jwt),
          const SizedBox(height: 12),
          if (ancho)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Column(children: [partes[0], partes[2]])),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: partes[1]),
              ],
            )
          else
            ...partes,
        ],
      );
    });
  }

  Widget _tarjetaToken(BuildContext context, JwtInfo jwt) {
    const estilo = TextStyle(fontFamily: 'monospace', fontSize: 13);
    return Tarjeta(
      color: Colores.oauth,
      icono: Icons.vpn_key,
      titulo: 'Tu access token (JWT)',
      subtitulo: 'Entregado por OAuth · header.payload.firma en Base64URL',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText.rich(
            TextSpan(style: estilo, children: [
              TextSpan(
                  text: jwt.headerB64,
                  style: const TextStyle(color: Colores.header)),
              const TextSpan(text: '.'),
              TextSpan(
                  text: jwt.payloadB64,
                  style: const TextStyle(color: Colores.payload)),
              const TextSpan(text: '.'),
              TextSpan(
                  text: jwt.firmaB64,
                  style: const TextStyle(color: Colores.firma)),
            ]),
          ),
          const SizedBox(height: 16),
          CuentaRegresiva(jwt: jwt),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final s in jwt.scopes) Pastilla(s, Colores.scope(s)),
              OutlinedButton.icon(
                onPressed: auth.renovar,
                icon: const Icon(Icons.refresh),
                label: const Text('Renovar con refresh token'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tarjetaHeader(JwtInfo jwt) => Tarjeta(
        color: Colores.header,
        icono: Icons.title,
        titulo: 'Header',
        subtitulo: 'Algoritmo de firma y tipo de token',
        child: VistaJson(jwt.header, color: Colores.header),
      );

  Widget _tarjetaPayload(JwtInfo jwt) => Tarjeta(
        color: Colores.payload,
        icono: Icons.data_object,
        titulo: 'Payload (claims)',
        subtitulo: 'Cualquiera puede leerlo: está codificado, NO cifrado',
        child: Column(
          children: [
            for (final e in jwt.payload.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(e.key,
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              color: Colores.payload)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(_valor(e.key, e.value),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(_explicacionClaims[e.key] ?? '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _tarjetaFirma() => const Tarjeta(
        color: Colores.firma,
        icono: Icons.verified_user,
        titulo: 'Firma',
        subtitulo: 'HMAC-SHA256(header + "." + payload, secreto)',
        child: Text(
          'Solo el servidor conoce el secreto. Si alguien cambia una sola letra '
          'del header o del payload, la firma deja de coincidir y la API '
          'responde 401. La app no puede validar la firma: solo la muestra.',
        ),
      );

  String _valor(String clave, Object? valor) {
    if ((clave == 'iat' || clave == 'exp') && valor is int) {
      final fecha = DateTime.fromMillisecondsSinceEpoch(valor * 1000);
      final h = fecha.hour.toString().padLeft(2, '0');
      final m = fecha.minute.toString().padLeft(2, '0');
      final s = fecha.second.toString().padLeft(2, '0');
      return '$valor  ($h:$m:$s)';
    }
    return '$valor';
  }
}
