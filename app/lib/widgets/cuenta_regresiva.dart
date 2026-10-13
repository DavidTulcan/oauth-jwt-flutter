import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/jwt_info.dart';
import '../tema.dart';

/// Barra que muestra cuánto le queda de vida al JWT (claim "exp").
class CuentaRegresiva extends StatefulWidget {
  final JwtInfo jwt;

  const CuentaRegresiva({super.key, required this.jwt});

  @override
  State<CuentaRegresiva> createState() => _CuentaRegresivaState();
}

class _CuentaRegresivaState extends State<CuentaRegresiva> {
  late final Timer _reloj;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _reloj.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vida = widget.jwt.vidaRestante;
    final color = widget.jwt.expirado
        ? Colores.error
        : vida < 0.3
            ? Colores.aviso
            : Colores.exito;
    final texto = widget.jwt.expirado
        ? 'Expirado: la API responderá 401'
        : 'Expira en ${widget.jwt.restante.inSeconds} s';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.jwt.expirado ? Icons.timer_off : Icons.timer,
                color: color, size: 18),
            const SizedBox(width: 6),
            Text(texto,
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: vida,
            minHeight: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}
