# Etapa 1: compilar el servidor Dart a un ejecutable nativo
FROM dart:stable AS build
WORKDIR /app
# Copiamos primero pubspec para que Docker reutilice la caché de
# "dart pub get" mientras las dependencias no cambien.
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/servidor.dart -o bin/servidor

# Etapa 2: imagen mínima, solo el ejecutable
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/servidor /app/bin/servidor
EXPOSE 8080
CMD ["/app/bin/servidor"]
