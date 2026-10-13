import 'dart:convert';

/// Lee un JWT (header.payload.firma) para MOSTRARLO.
/// La app no valida la firma: no conoce el secreto y no debe conocerlo.
/// Quien valida es la API.
class JwtInfo {
  final String token;
  final String headerB64;
  final String payloadB64;
  final String firmaB64;
  final Map<String, dynamic> header;
  final Map<String, dynamic> payload;

  JwtInfo._(this.token, this.headerB64, this.payloadB64, this.firmaB64,
      this.header, this.payload);

  factory JwtInfo.decodificar(String token) {
    final partes = token.split('.');
    if (partes.length != 3) {
      throw const FormatException('Un JWT debe tener 3 partes');
    }
    return JwtInfo._(
      token,
      partes[0],
      partes[1],
      partes[2],
      _leerParte(partes[0]),
      _leerParte(partes[1]),
    );
  }

  static Map<String, dynamic> _leerParte(String parte) {
    final json = utf8.decode(base64Url.decode(base64Url.normalize(parte)));
    return jsonDecode(json) as Map<String, dynamic>;
  }

  static DateTime? _fecha(Object? segundos) => segundos is int
      ? DateTime.fromMillisecondsSinceEpoch(segundos * 1000)
      : null;

  DateTime? get emitido => _fecha(payload['iat']);
  DateTime? get expira => _fecha(payload['exp']);

  Duration get restante =>
      expira == null ? Duration.zero : expira!.difference(DateTime.now());

  bool get expirado => restante <= Duration.zero;

  double get vidaRestante {
    if (emitido == null || expira == null) return 0;
    final total = expira!.difference(emitido!).inMilliseconds;
    return (restante.inMilliseconds / total).clamp(0.0, 1.0);
  }

  List<String> get scopes =>
      (payload['scope'] as String? ?? '').split(' ').where((s) => s.isNotEmpty).toList();

  String get nombre => payload['name'] as String? ?? '';
  String get rol => payload['rol'] as String? ?? '';

  String alterar(Map<String, dynamic> cambios) {
    final nuevo = {...payload, ...cambios};
    final b64 = base64Url.encode(utf8.encode(jsonEncode(nuevo))).replaceAll('=', '');
    return '$headerB64.$b64.$firmaB64';
  }
}
