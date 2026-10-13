# Llave Segura: OAuth 2.0 + JWT con Flutter y Docker

Proyecto de la práctica "Manual: OAuth 2.0 y JWT juntos en una app Flutter con Docker".
Todo el código viene del manual, archivo por archivo. Aquí están los comandos en orden, para PowerShell en Windows.

> Supuestos del manual: ya tienes el contenedor `flutter-dev` (imagen `ghcr.io/cirruslabs/flutter:stable`)
> con la carpeta `D:\DOCKER\flutter-docker` montada en `/app`, y Docker Desktop abierto.

## Estructura

```
oauth_jwt_demo/
├── docker-compose.yml
├── servidor/            <- Pasos 2 y 3 (Dart + shelf), completo
└── app_archivos/        <- Pasos 4 y 5: archivos que se copian sobre el proyecto Flutter
    ├── lib/  test/  web/auth.html
    └── android/app/src/main/AndroidManifest.xml
```

## Paso 1. Colocar el proyecto

Descomprime el ZIP para que quede `D:\DOCKER\flutter-docker\oauth_jwt_demo`.

```powershell
docker ps                      # flutter-dev debe aparecer en la lista
cd D:\DOCKER\flutter-docker\oauth_jwt_demo
```

## Paso 2 y 3. Servidor OAuth + JWT

```powershell
# Agregar los paquetes (el pubspec.yaml ya está creado)
docker exec -w /app/oauth_jwt_demo/servidor flutter-dev mkdir -p bin lib test
docker exec -w /app/oauth_jwt_demo/servidor flutter-dev dart pub add shelf shelf_router dart_jsonwebtoken crypto
docker exec -w /app/oauth_jwt_demo/servidor flutter-dev dart pub add dev:test

# Verificar: debe decir "No issues found!" y "All tests passed!" (11 pruebas)
docker exec -w /app/oauth_jwt_demo/servidor flutter-dev dart analyze
docker exec -w /app/oauth_jwt_demo/servidor flutter-dev dart test
```

## Paso 4 y 5. App Flutter

```powershell
# 4.1 Crear el proyecto y los paquetes
docker exec -w /app/oauth_jwt_demo flutter-dev flutter create --org ec.edu.ingsoft --project-name llave_segura --platforms web,android app
docker exec -w /app/oauth_jwt_demo/app flutter-dev flutter pub add flutter_web_auth_2 shared_preferences http crypto

# Copiar el código del manual sobre el proyecto (reemplaza main.dart, widget_test.dart y AndroidManifest.xml)
Copy-Item -Path .\app_archivos\* -Destination .\app\ -Recurse -Force

# Verificar: "No issues found!" y "All tests passed!" (4 pruebas)
docker exec -w /app/oauth_jwt_demo/app flutter-dev flutter analyze
docker exec -w /app/oauth_jwt_demo/app flutter-dev flutter test
```

## Paso 6. Compilar y desplegar

```powershell
# Compilar la app web dentro de flutter-dev
docker exec -w /app/oauth_jwt_demo/app flutter-dev flutter build web --release

# Levantar servidor + nginx (la primera vez tarda 2 a 4 minutos)
docker compose up -d --build
docker compose ps
```

- Servidor: http://localhost:9000 (debe responder `{"servicio":"Servidor OAuth 2.0 + API JWT", ...}`)
- App: http://localhost:8082, inicia sesión con `ana / ana123` (docente: `profe / profe123`)
- Bitácora del servidor, en otra terminal: `docker logs -f llave-segura-auth`

| Si cambias... | Ejecuta |
|---|---|
| Código de la app (`app\lib`) | `flutter build web --release` en flutter-dev y Ctrl + F5 |
| Código del servidor (`servidor\lib`) | `docker compose up -d --build auth-server` |
| `ACCESS_TTL_SECONDS` o `JWT_SECRET` | `docker compose up -d` |
| Apagar todo | `docker compose down` |

## Modo desarrollo y Android (opcional)

```powershell
# Web con hot reload en el puerto 8080 (ya registrado como redirect_uri)
docker exec -it flutter-dev bash -c "cd /app/oauth_jwt_demo/app && flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0"

# APK (10.0.2.2 = tu PC vista desde el emulador; en celular físico usa la IP de tu PC)
docker exec -w /app/oauth_jwt_demo/app flutter-dev flutter build apk --dart-define=AUTH_SERVER=http://10.0.2.2:9000
```

## Experimentos (pestaña Laboratorio)

| # | Experimento | Resultado esperado |
|---|---|---|
| 1 | Sin token | 401 invalid_request |
| 2 | Token alterado (rol a docente) | 401 invalid signature |
| 3 | Scope insuficiente (ana pide /api/admin) | 403 insufficient_scope |
| 4 | Token expirado (copia usada tras 60 s) | 401 El token expiró |
| 5 | Renovación automática (tras 60 s) | 200 + "JWT renovado" |
| 6 | Login como profe marcando admin | 200 en Panel docente |
| 7 | Login como ana marcando admin | El token llega sin admin |
| 8 | Copiar el JWT en jwt.io | Se lee todo el payload |

## Si algo falla

| Síntoma | Solución |
|---|---|
| El botón de login no abre nada | Permite ventanas emergentes para localhost:8082 |
| "redirect_uri no registrado" | Agrega esa URL en `servidor/lib/datos.dart` y reconstruye |
| Siempre 401 "invalid signature" | Cierra sesión y vuelve a entrar (cambió JWT_SECRET) |
| La renovación falla tras reiniciar el servidor | Es esperado: los refresh tokens están en memoria |
| En Android no vuelve a la app | Revisa el AndroidManifest.xml (CallbackActivity y esquema `llavesegura`) |

## Nota sobre secretos

`JWT_SECRET` está en el `docker-compose.yml` solo por ser una práctica. En un proyecto real va en un `.env` fuera de Git.

Secretos: copia .env.example a .env y cambia JWT_SECRET antes de ejecutar docker compose up -d. El archivo .env no se sube a Git.
