import 'dart:convert';

import 'datos.dart';

const _esc = HtmlEscape();

/// Página HTML que ve el usuario en el paso /authorize.
/// La app NUNCA ve esta contraseña: el usuario la escribe en el servidor.
String paginaLogin({
  required Cliente cliente,
  required Map<String, String> parametros,
  required List<String> scopes,
  String? error,
}) {
  final ocultos = parametros.entries
      .map((e) =>
          '<input type="hidden" name="${_esc.convert(e.key)}" value="${_esc.convert(e.value)}">')
      .join('\n');
  final permisos = scopes
      .map((s) =>
          '<li><span class="scope">$s</span>${_esc.convert(scopesDisponibles[s] ?? s)}</li>')
      .join('\n');

  return '''
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Iniciar sesión · Servidor de autorización</title>
<style>
  * { box-sizing: border-box; }
  body {
    margin: 0; min-height: 100vh; display: flex; align-items: center;
    justify-content: center; padding: 16px;
    font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    background: linear-gradient(135deg, #4527a0, #00897b 55%, #f9a825);
  }
  .tarjeta {
    width: 100%; max-width: 420px; background: #fff; border-radius: 20px;
    box-shadow: 0 20px 50px rgba(0,0,0,.25); overflow: hidden;
  }
  header { background: #311b92; color: #fff; padding: 20px 24px; }
  header small { color: #b39ddb; letter-spacing: .08em; text-transform: uppercase; }
  header h1 { margin: 4px 0 0; font-size: 22px; }
  main { padding: 20px 24px 24px; }
  .app { background: #ede7f6; border-radius: 12px; padding: 12px 14px; margin-bottom: 16px; }
  .app b { color: #4527a0; }
  ul { list-style: none; padding: 0; margin: 8px 0 0; }
  li { margin: 6px 0; font-size: 14px; color: #333; }
  .scope {
    display: inline-block; min-width: 64px; margin-right: 8px; padding: 2px 8px;
    border-radius: 999px; background: #00897b; color: #fff; font-size: 12px;
    font-weight: 700; text-align: center;
  }
  label { display: block; font-size: 13px; font-weight: 600; color: #555; margin: 12px 0 4px; }
  input[type=text], input[type=password] {
    width: 100%; padding: 12px; border: 2px solid #d1c4e9; border-radius: 10px; font-size: 16px;
  }
  input:focus { outline: none; border-color: #7e57c2; }
  .error { background: #ffebee; color: #c62828; padding: 10px 12px; border-radius: 10px; font-size: 14px; }
  .botones { display: flex; gap: 10px; margin-top: 20px; }
  button { flex: 1; padding: 12px; border: 0; border-radius: 10px; font-size: 16px; font-weight: 700; cursor: pointer; }
  .permitir { background: #00897b; color: #fff; }
  .cancelar { background: #eeeeee; color: #555; }
  .ayuda { margin-top: 16px; font-size: 12px; color: #777; text-align: center; }
  code { background: #f3e5f5; padding: 1px 5px; border-radius: 4px; }
</style>
</head>
<body>
<form class="tarjeta" method="post" action="/authorize">
  <header>
    <small>Servidor de autorización OAuth 2.0</small>
    <h1>Inicia sesión</h1>
  </header>
  <main>
    <div class="app">
      La app <b>${_esc.convert(cliente.nombre)}</b> quiere permiso para:
      <ul>$permisos</ul>
    </div>
    ${error == null ? '' : '<div class="error">${_esc.convert(error)}</div>'}
    $ocultos
    <label for="usuario">Usuario</label>
    <input id="usuario" name="usuario" type="text" autocomplete="username" required autofocus>
    <label for="clave">Contraseña</label>
    <input id="clave" name="clave" type="password" autocomplete="current-password" required>
    <div class="botones">
      <button class="cancelar" type="submit" name="accion" value="cancelar" formnovalidate>Cancelar</button>
      <button class="permitir" type="submit" name="accion" value="permitir">Permitir</button>
    </div>
    <p class="ayuda">Usuarios de prueba: <code>ana / ana123</code> · <code>profe / profe123</code></p>
  </main>
</form>
</body>
</html>
''';
}
