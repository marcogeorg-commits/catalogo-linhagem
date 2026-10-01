# Catálogo A Linhagem: uma página estática servida por nginx. Porta 80.
FROM nginx:1.27-alpine
COPY publicar/nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
RUN chmod 644 /usr/share/nginx/html/index.html
EXPOSE 80
