import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../tema.dart';

class Tarjeta extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Widget child;

  const Tarjeta({
    super.key,
    required this.color,
    required this.icono,
    required this.titulo,
    this.subtitulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.3),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 6)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icono, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: color)),
                      if (subtitulo != null)
                        Text(subtitulo!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Etiqueta redonda de color.
class Pastilla extends StatelessWidget {
  final String texto;
  final Color color;

  const Pastilla(this.texto, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(texto,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// Muestra un objeto como JSON con sangría, en un recuadro de color.
class VistaJson extends StatelessWidget {
  final Object? datos;
  final Color color;

  const VistaJson(this.datos, {super.key, this.color = Colors.blueGrey});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: SelectableText(
        const JsonEncoder.withIndent('  ').convert(datos),
        style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: color),
      ),
    );
  }
}

/// Resultado de una llamada a la API: código HTTP de color + cuerpo.
class ResultadoApi extends StatelessWidget {
  final RespuestaApi respuesta;

  const ResultadoApi(this.respuesta, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = Colores.estadoHttp(respuesta.estado);
    final textoEstado = switch (respuesta.estado) {
      200 => '200 OK',
      401 => '401 No autorizado',
      403 => '403 Prohibido',
      0 => 'Sin conexión',
      final e => '$e',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Pastilla(textoEstado, color),
            if (respuesta.renovado)
              const Pastilla('JWT renovado automáticamente', Colores.oauth),
          ],
        ),
        const SizedBox(height: 8),
        VistaJson(respuesta.cuerpo, color: color),
      ],
    );
  }
}
