# Estágio 1: Build da aplicação Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copia os arquivos do projeto web
COPY src/web/ .

# Obtém dependências e compila para Web em modo release
RUN flutter pub get
RUN flutter build web --release

# Estágio 2: Imagem final leve servindo os arquivos estáticos via Nginx
FROM nginx:alpine

# Copia os arquivos gerados no estágio de build para o diretório padrão do Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Configuração de porta
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
