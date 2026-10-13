import 'dart:io';

import 'package:servidor_oauth/app.dart';
import 'package:servidor_oauth/config.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() async {
  final servidor =
      await io.serve(crearApp(), InternetAddress.anyIPv4, Config.puerto);
  print('Servidor OAuth escuchando en el puerto ${servidor.port}');
}
