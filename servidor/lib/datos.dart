import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Un usuario del sistema. La contraseña se guarda como hash, nunca en texto.
class Usuario {
  final String id;
  final String usuario;
  final String nombre;
  final String rol;
  final String _sal;
  final String _hash;

  Usuario(this.id, this.usuario, this.nombre, this.rol, String clave)
      : _sal = id,
        _hash = _calcularHash(id, clave);

  bool claveCorrecta(String clave) => _calcularHash(_sal, clave) == _hash;

  static String _calcularHash(String sal, String clave) =>
      sha256.convert(utf8.encode('$sal:$clave')).toString();
}

class Cliente {
  final String id;
  final String nombre;
  final List<String> redirectUris;

  const Cliente(this.id, this.nombre, this.redirectUris);
}

final usuarios = <String, Usuario>{
  'ana': Usuario('u-001', 'ana', 'David Tulcan', 'estudiante', 'ana123'),
  'luis': Usuario('u-002', 'luis', 'Luis Estudiante', 'estudiante', 'luis123'),
  'profe': Usuario('u-100', 'profe', 'Docente Demo', 'docente', 'profe123'),
};

const clientes = <String, Cliente>{
  'llave-segura-app': Cliente('llave-segura-app', 'Llave Segura', [
    'http://localhost:8082/auth.html', // app desplegada con nginx
    'http://localhost:8080/auth.html', // app en modo desarrollo
    'http://172.20.235.17:8082/auth.html', // iPhone en la misma red
    'llavesegura://callback', // app Android
  ]),
};

const scopesDisponibles = <String, String>{
  'perfil': 'Ver tu nombre y tu rol',
  'notas': 'Ver tus calificaciones',
  'admin': 'Ver el panel docente (solo docentes)',
};

/// Datos de ejemplo que protege la API.
const notasPorUsuario = <String, List<Map<String, Object>>>{
  'u-001': [
    {'materia': 'Apps Móviles', 'nota': 9.5},
    {'materia': 'Base de Datos', 'nota': 8.7},
    {'materia': 'Ingeniería de Software', 'nota': 9.1},
  ],
  'u-002': [
    {'materia': 'Apps Móviles', 'nota': 7.8},
    {'materia': 'Base de Datos', 'nota': 9.0},
  ],
  'u-100': [],
};
