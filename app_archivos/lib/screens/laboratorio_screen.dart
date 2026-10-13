import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

class _Experimento {
  final String titulo;
  final String descripcion;
  final String esperado;
  final IconData icono;
  final Color color;
  final Future<RespuestaApi> Function() ejecutar;

  const _Experimento(this.titulo, this.descripcion, this.esperado, this.icono,
      this.color, this.ejecutar);
}

/// Experimentos para la clase: ver por qué la API rechaza ciertos tokens.
class LaboratorioScreen extends StatefulWidget {
  final ApiClient api;

  const LaboratorioScreen({super.key, required this.api});

  @override
  State<LaboratorioScreen> createState() => _LaboratorioScreenState();
}

class _LaboratorioScreenState extends State<LaboratorioScreen> {
  final Map<String, RespuestaApi> _resultados = {};
  String? _tokenGuardado;

  List<_Experimento> get _experimentos {
    final api = widget.api;
    final jwt = api.auth.jwt!;
    return [
      _Experimento(
        'Sin token',
        'Llama a /api/perfil sin la cabecera Authorization.',
        '401 · invalid_request',
        Icons.no_encryption,
        Colores.error,
        () => api.get('/api/perfil', tokenManual: ''),
      ),
      _Experimento(
        'Token alterado',
        'Cambia el payload a rol "docente" con scope "admin", pero conserva la '
            'firma original. Luego llama a /api/admin.',
        '401 · la firma no coincide',
        Icons.edit_note,
        Colores.payload,
        () => api.get('/api/admin',
            tokenManual: jwt.alterar({
              'rol': 'docente',
              'scope': 'perfil notas admin',
            })),
      ),
      _Experimento(
        'Scope insuficiente',
        'Llama a /api/admin con tu token real. Si no tienes el scope "admin", '
            'el token es válido pero no alcanza.',
        jwt.scopes.contains('admin') ? '200 · tienes el scope' : '403 · insufficient_scope',
        Icons.block,
        Colores.aviso,
        () => api.get('/api/admin', tokenManual: api.auth.accessToken),
      ),
      _Experimento(
        'Token expirado',
        _tokenGuardado == null
            ? 'Primero guarda una copia del token actual. Espera a que expire '
                '(mira la barra en "Token") y vuelve a usarla.'
            : 'Copia guardada. Úsala cuando haya pasado su "exp".',
        '401 · El token expiró',
        Icons.timer_off,
        Colores.firma,
        () async {
          if (_tokenGuardado == null) {
            setState(() => _tokenGuardado = api.auth.accessToken);
            return const RespuestaApi('', 0, {'mensaje': 'Token guardado. Espera a que expire y pulsa de nuevo.'});
          }
          return api.get('/api/perfil', tokenManual: _tokenGuardado);
        },
      ),
      _Experimento(
        'Renovación automática',
        'Llama a /api/perfil de forma normal. Si el JWT expiró, la app usa el '
            'refresh token, recibe uno nuevo y repite la petición.',
        '200 · con o sin "JWT renovado"',
        Icons.autorenew,
        Colores.oauth,
        () => api.get('/api/perfil'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final experimentos = _experimentos;
    return LayoutBuilder(builder: (context, constraints) {
      final columnas = constraints.maxWidth >= 1100
          ? 3
          : constraints.maxWidth >= 700
              ? 2
              : 1;
      final anchoTarjeta =
          (constraints.maxWidth - 32 - (columnas - 1) * 12) / columnas;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final e in experimentos)
              SizedBox(width: anchoTarjeta, child: _tarjeta(e)),
          ],
        ),
      );
    });
  }

  Widget _tarjeta(_Experimento e) {
    final resultado = _resultados[e.titulo];
    return Tarjeta(
      color: e.color,
      icono: e.icono,
      titulo: e.titulo,
      subtitulo: 'Esperado: ${e.esperado}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(e.descripcion),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: e.color,
              side: BorderSide(color: e.color, width: 1.5),
            ),
            onPressed: () async {
              final r = await e.ejecutar();
              if (mounted) setState(() => _resultados[e.titulo] = r);
            },
            icon: const Icon(Icons.science),
            label: const Text('Probar'),
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
