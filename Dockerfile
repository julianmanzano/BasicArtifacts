FROM node:lts-alpine3.20
WORKDIR /app/react-app
COPY . .
RUN groupadd user && \
    useradd -r -g user user && \
    chown user:user /app/react-app && \
    chmod -R 755 /app/react-app
EXPOSE 8080
USER user
CMD [ "npm", "run", "preview" ]

# Plantilla Base de Dockerfile según practicas
# Guía: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
# Referencia comandos: https://docs.docker.com/reference/dockerfile/

#Para las imagenes se recomiendan usar las imagenes oficiales y para los tags de las images se recomienda usar images Alpine
# Se debe poner nombre a cada imagen ya que debemos implementar las capas que nos permitan construir la imagen y crear una imagen nueva para publicar
# limpia de artefactos no necesarios para desplegar
FROM imagen:alpine AS Build

# Se pueden usar LABELS para marcar las imagenes en caso de ser neceario, esto es opcional
LABEL app.dominio.com.version="1.0.0"
LABEL app.dominio.com.release-date="03-05-2024"
LABEL app.dominio.com.enviroment="PRD"

# ARGS en caso de requerir valores para la creación y se reciben como parametros en el docker build: --build-arg="PARAM=Valor"
ARG PARAM
ARG PORT
# Variables de ambiente en caso de ser requeridas
# Simple
ENV ENV_KEY=ENV_VAL
# Desde Argumento
ENV ENV_ARG_KEY=$PARAM
ENV PORT=8080

# Directorio de trabajo
WORKDIR /the/workdir/path

# COPY o ADD, cual usar? COPY se usa para copiar los archivos al conteneor desde donde se compila el Dockerfile, y al ADD se usa cuando obtenemos
# los archvos de ubicaciones remotas por medio de HTTPS o direcciones GIT (Sí son archivos tar, los extrae autometicamente)
# Carpetas completas
COPY sourceFolder /the/workdir/path
# Archivos puntuales
COPY file.yaml /the/workdir/path
# Ejemplo con ADD
ADD --checksum=sha256:270d731bd08040c6a3228115de1f74b91cf441c584139ff8f8f6503447cebdbb \
    https://dotnetcli.azureedge.net/dotnet/Runtime/$DOTNET_VERSION/dotnet-runtime-linux-arm64.tar.gz /the/workdir/path/dotnet.tar.gz

# Instalar dependencias
RUN npm install
# Ejecutar comandos de compilación con el comando RUN

# Imagen para crear el contenedor final, como se recomienda al inicio tambien usar imagenes oficiales ademas imagenes reducidas Alpine
FROM imagenfinal:alpine AS final

# Comandos RUN
# Cración de usuario non-root para ejecutar la aplicación o servicio
# Obligatorio
RUN adduser --system --no-create-home nonroot

# Instalación de librerias y servicios adicionales que se requieran puntuales, es buena practica remover cache al final de la instalación de temas adicionales
RUN RUN apt-get update && \
    apt-get install -y libreria1 libreria2 paquete1 && \
    comandoAEjecutar && \
    apt-get clean && \
    # Asegurar los permisos necesarios a usuario non-root para que pueda ejecutar y acceder a todos los repositorios necesarios
    groupadd user && \ 
    useradd -r -g user user && \
    chown user:user /app/react-app && \
    chmod -R 755 /app/react-app

# COPY la app compilada o final proveniente del contedor que se encargo de crearla. Se pone el comando --from=NombreImagenBuild ... AS Build
# Ejemplos Carpetas
COPY --from=Build /the/workdir/source /the/workdir/destination
# Ejemplo Archivo
COPY --from=Build /the/workdir/source/file.ext /the/workdir/destination/file.ext

# EXPOSE indica el puerto por el que el contenedor escucha, formato numero o puede ser por parametro, evitar el puerto 80 y 443 que se puede prestar para confusion del orquestador
# Simple 
EXPOSE 8080
# Parametro ambiente o argumento
EXPOSE $PORT

# USER indica con que usuario se va a ejecutar, es buena paractica que un usuario no root sea quien ejecuta el comando principal del contenedor
# Obligatorio
USER nonroot

# Es buena practica hacer un chequeo de la salud del contendor y se usa el comando HEALTHCHECK
HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost:8080/ || exit 1

# ENTRYPOINT es el comando inicial con el que el contenedor se va a ejecutar
ENTRYPOINT [ "executable", "parametro", "nombreFile" ]
# Ejemplo
ENTRYPOINT [ "npm", "run", "start:prod" ]
