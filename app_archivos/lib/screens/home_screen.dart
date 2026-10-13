import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../auth/auth_service.dart';
import '../tema.dart';
import 'api_screen.dart';
import 'bitacora_screen.dart';
import 'laboratorio_screen.dart';
import 'token_screen.dart';

class _Seccion {
  final String nombre;
  final IconData icono;
  final Color color;

  const _Seccion(this.nombre, this.icono, this.color);
}

/// Pantalla principal. Responsive: barra inferior en celular,
/// menú lateral (NavigationRail) en tableta y escritorio.
class HomeScreen extends StatefulWidget {
  final AuthService auth;

  const HomeScreen({super.key, required this.auth});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiClient _api = ApiClient(widget.auth);
  int _indice = 0;

  static const _secciones = [
    _Seccion('Token', Icons.vpn_key, Colores.payload),
    _Seccion('API', Icons.cloud, Colores.api),
    _Seccion('Laboratorio', Icons.science, Colores.aviso),
    _Seccion('Bitácora', Icons.timeline, Colores.oauth),
  ];

  Widget _contenido() => switch (_indice) {
        0 => TokenScreen(auth: widget.auth),
        1 => ApiScreen(api: _api),
        2 => LaboratorioScreen(api: _api),
        _ => BitacoraScreen(auth: widget.auth),
      };

  @override
  Widget build(BuildContext context) {
    final jwt = widget.auth.jwt!;
    final ancho = MediaQuery.sizeOf(context).width >= 800;
    final seccion = _secciones[_indice];

    return Scaffold(
      backgroundColor: Colores.fondo,
      appBar: AppBar(
        foregroundColor: Colors.white,
        flexibleSpace:
            Container(decoration: const BoxDecoration(gradient: Colores.degradado)),
        title: Row(
          children: [
            const Icon(Icons.key, color: Colores.ambar),
            const SizedBox(width: 8),
            const Text('Llave Segura',
                style: TextStyle(fontWeight: FontWeight.w900)),
            if (ancho) ...[
              const SizedBox(width: 12),
              Text('· ${seccion.nombre}',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ],
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 500)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(Icons.person, size: 18),
                label: Text('${jwt.nombre} · ${jwt.rol}'),
              ),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: widget.auth.cerrarSesion,
          ),
        ],
      ),
      body: ancho
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _indice,
                  onDestinationSelected: (i) => setState(() => _indice = i),
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: seccion.color.withValues(alpha: 0.2),
                  destinations: [
                    for (final s in _secciones)
                      NavigationRailDestination(
                        icon: Icon(s.icono, color: s.color),
                        label: Text(s.nombre),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _contenido()),
              ],
            )
          : _contenido(),
      bottomNavigationBar: ancho
          ? null
          : NavigationBar(
              selectedIndex: _indice,
              onDestinationSelected: (i) => setState(() => _indice = i),
              indicatorColor: seccion.color.withValues(alpha: 0.2),
              destinations: [
                for (final s in _secciones)
                  NavigationDestination(
                    icon: Icon(s.icono, color: s.color),
                    label: s.nombre,
                  ),
              ],
            ),
    );
  }
}
