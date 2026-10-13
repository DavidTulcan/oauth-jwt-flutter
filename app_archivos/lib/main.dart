import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'tema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  await auth.cargar();
  runApp(LlaveSeguraApp(auth: auth));
}

class LlaveSeguraApp extends StatelessWidget {
  final AuthService auth;

  const LlaveSeguraApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Llave Segura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colores.oauth, useMaterial3: true),
      home: ListenableBuilder(
        listenable: auth,
        builder: (context, _) => auth.conectado
            ? HomeScreen(auth: auth)
            : LoginScreen(auth: auth),
      ),
    );
  }
}
