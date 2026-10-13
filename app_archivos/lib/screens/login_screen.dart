import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../tema.dart';

class LoginScreen extends StatefulWidget {
  final AuthService auth;

  const LoginScreen({super.key, required this.auth});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Set<String> _scopes = {'perfil', 'notas'};
  bool _cargando = false;
  String? _error;

  static const _descripciones = {
    'perfil': 'Tu nombre y rol',
    'notas': 'Tus calificaciones',
    'admin': 'Panel docente',
  };

  Future<void> _entrar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await widget.auth.iniciarSesion(_scopes.toList());
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Colores.degradado),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth >= 900;
              final tarjeta = _tarjetaLogin();
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: ancho ? 1000 : 480),
                    child: ancho
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(child: _Explicacion()),
                              const SizedBox(width: 40),
                              Expanded(child: tarjeta),
                            ],
                          )
                        : Column(
                            children: [
                              const _Encabezado(),
                              const SizedBox(height: 20),
                              tarjeta,
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tarjetaLogin() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('¿Qué permisos (scopes) pedirá la app?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in _descripciones.keys)
                  FilterChip(
                    label: Text('$s · ${_descripciones[s]}'),
                    selected: _scopes.contains(s),
                    showCheckmark: false,
                    avatar: Icon(
                      _scopes.contains(s) ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: _scopes.contains(s) ? Colors.white : Colores.scope(s),
                    ),
                    selectedColor: Colores.scope(s),
                    backgroundColor: Colores.scope(s).withValues(alpha: 0.1),
                    side: BorderSide(color: Colores.scope(s), width: 1.5),
                    labelStyle: TextStyle(
                      color: _scopes.contains(s) ? Colors.white : Colores.scope(s),
                      fontWeight: FontWeight.w700,
                    ),
                    onSelected: (activo) => setState(() {
                      activo ? _scopes.add(s) : _scopes.remove(s);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'El servidor decide qué concede: "admin" solo se entrega a docentes.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colores.oauth,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              onPressed: _cargando || _scopes.isEmpty ? null : _entrar,
              icon: _cargando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.vpn_key),
              label: Text(_cargando ? 'Esperando al servidor…' : 'Iniciar sesión con OAuth'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Se abrirá la página del servidor de autorización. '
              'La app nunca ve tu contraseña.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colores.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: Colores.error)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colores.ambar,
          child: Icon(Icons.key, size: 44, color: Color(0xFF4527A0)),
        ),
        SizedBox(height: 12),
        Text('Llave Segura',
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
        Text('OAuth 2.0 + JWT',
            style: TextStyle(fontSize: 16, color: Colors.white70)),
      ],
    );
  }
}

/// Panel que solo aparece en pantallas anchas: explica el flujo.
class _Explicacion extends StatelessWidget {
  const _Explicacion();

  @override
  Widget build(BuildContext context) {
    Widget paso(String numero, String titulo, String texto, Color color) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Text(numero,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    Text(texto, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Encabezado(),
        const SizedBox(height: 32),
        paso('1', 'OAuth: pedir permiso',
            'Inicias sesión en el servidor y aceptas los scopes.', Colores.oauth),
        paso('2', 'OAuth: recibir el token',
            'La app cambia un código de un solo uso (+ PKCE) por tokens.',
            Colores.ambar),
        paso('3', 'JWT: usar el permiso',
            'El access token es un JWT firmado que la API valida sola.',
            Colores.header),
      ],
    );
  }
}
