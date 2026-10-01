# Catálogo A Linhagem: página estática servida por nginx. Porta 80.
# 1º estágio: tira as fotos de dentro do index.html e grava em WebP (publicar/separar_fotos.py).
FROM python:3.12-alpine AS fotos
RUN pip install --no-cache-dir "pillow==12.*"
COPY index.html publicar/separar_fotos.py /src/
RUN python /src/separar_fotos.py /src/index.html /site

FROM nginx:1.27-alpine
COPY publicar/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=fotos /site /usr/share/nginx/html
RUN chmod -R a+rX /usr/share/nginx/html
EXPOSE 80
