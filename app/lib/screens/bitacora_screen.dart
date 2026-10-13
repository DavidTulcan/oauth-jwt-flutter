import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../tema.dart';

/// Línea de tiempo con cada paso de OAuth, cada JWT y cada llamada a la API.
class BitacoraScreen extends StatelessWidget {
  final AuthService auth;

  const BitacoraScreen({super.key, required this.auth});

  static Color _color(TipoEvento t) => switch (t) {
        TipoEvento.oauth => Colores.oauth,
        TipoEvento.jwt => Colores.payload,
        TipoEvento.api => Colores.api,
        TipoEvento.error => Colores.error,
      };

  static IconData _icono(TipoEvento t) => switch (t) {
        TipoEvento.oauth => Icons.swap_horiz,
        TipoEvento.jwt => Icons.vpn_key,
        TipoEvento.api => Icons.cloud_done,
        TipoEvento.error => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    final eventos = auth.bitacora;
    if (eventos.isEmpty) {
      return const Center(child: Text('Aún no hay eventos.'));
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: eventos.length,
          itemBuilder: (context, i) {
            final e = eventos[i];
            final color = _color(e.tipo);
            final hora = '${e.hora.hour.toString().padLeft(2, '0')}:'
                '${e.hora.minute.toString().padLeft(2, '0')}:'
                '${e.hora.second.toString().padLeft(2, '0')}';
            return Card(
              elevation: 0,
              color: color.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: color.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: Icon(_icono(e.tipo), color: Colors.white, size: 20),
                ),
                title: Text(e.titulo,
                    style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                subtitle: e.detalle.isEmpty
                    ? null
                    : Text(e.detalle,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                trailing: Text(hora, style: const TextStyle(color: Colors.black54)),
              ),
            );
          },
        ),
      ),
    );
  }
}
