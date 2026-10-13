import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

class _Endpoint {
  final String ruta;
  final String titulo;
  final String scope;
  final IconData icono;

  const _Endpoint(this.ruta, this.titulo, this.scope, this.icono);
}

/// Llama a la API protegida con el JWT en la cabecera Authorization.
class ApiScreen extends StatefulWidget {
  final ApiClient api;

  const ApiScreen({super.key, required this.api});

  @override
  State<ApiScreen> createState() => _ApiScreenState();
}

class _ApiScreenState extends State<ApiScreen> {
  static const _endpoints = [
    _Endpoint('/api/perfil', 'Mi perfil', 'perfil', Icons.person),
    _Endpoint('/api/notas', 'Mis notas', 'notas', Icons.school),
    _Endpoint('/api/admin', 'Panel docente', 'admin', Icons.admin_panel_settings),
  ];

  final Map<String, RespuestaApi> _resultados = {};
  final Set<String> _cargando = {};

  Future<void> _llamar(String ruta) async {
    setState(() => _cargando.add(ruta));
    final r = await widget.api.get(ruta);
    if (mounted) {
      setState(() {
        _cargando.remove(ruta);
        _resultados[ruta] = r;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.api.auth.accessToken ?? '';
    final tarjetas = [for (final e in _endpoints) _tarjeta(e)];

    return LayoutBuilder(builder: (context, constraints) {
      final columnas = constraints.maxWidth >= 1100
          ? 3
          : constraints.maxWidth >= 700
              ? 2
              : 1;
      final anchoTarjeta =
          (constraints.maxWidth - 32 - (columnas - 1) * 12) / columnas;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Tarjeta(
            color: Colores.api,
            icono: Icons.http,
            titulo: 'Así viaja el JWT en cada petición',
            child: VistaJson(
              'Authorization: Bearer ${token.length > 40 ? '${token.substring(0, 40)}…' : token}',
              color: Colores.api,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final t in tarjetas) SizedBox(width: anchoTarjeta, child: t),
            ],
          ),
        ],
      );
    });
  }

  Widget _tarjeta(_Endpoint e) {
    final color = Colores.scope(e.scope);
    final resultado = _resultados[e.ruta];
    return Tarjeta(
      color: color,
      icono: e.icono,
      titulo: e.titulo,
      subtitulo: 'GET ${e.ruta} · requiere scope "${e.scope}"',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: _cargando.contains(e.ruta) ? null : () => _llamar(e.ruta),
            icon: const Icon(Icons.send),
            label: const Text('Llamar a la API'),
          ),
          if (resultado != null) ...[
            const SizedBox(height: 12),
            ResultadoApi(resultado),
          ],
        ],
      ),
    );
  }
}
