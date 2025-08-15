# --- Etapa 1: Builder ---
# Usamos la imagen robusta y le añadimos las herramientas de compilación específicas
FROM node:22-bookworm AS builder

# Instalar las herramientas de compilación y las librerías de desarrollo de SQLite
RUN apt-get update && apt-get install -y build-essential libsqlite3-dev --no-install-recommends

WORKDIR /app

# Instalar pnpm
RUN npm install -g pnpm@10

# Copiar todo el código fuente
COPY . .

# Aumentar el límite de memoria para Node.js
ENV NODE_OPTIONS=--max-old-space-size=8192

# Instalar dependencias ignorando los scripts de post-instalación
RUN pnpm install --ignore-scripts

# --- INICIO DEL CAMBIO ---
# Construir el proyecto, pasando el filtro a Turbo con la sintaxis correcta (usando --)
# para excluir el paquete problemático.
RUN pnpm run build -- --filter="!@n8n/n8n-nodes-langchain"
# --- FIN DEL CAMBIO ---


# --- Etapa 2: Production ---
# Volvemos a la imagen ligera para la imagen final
FROM node:22-alpine

WORKDIR /app

# Instalar pnpm para manejar el workspace
RUN npm install -g pnpm@10

# Copiar los manifiestos desde la etapa de 'builder'
COPY --from=builder /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./

# Copiar SOLO el paquete 'cli' ya compilado desde la etapa de 'builder'
COPY --from=builder /app/packages/cli ./packages/cli

# Instalar únicamente las dependencias de PRODUCCIÓN.
RUN pnpm install --prod --filter=@n8n/cli --ignore-scripts

# Exponer el puerto por defecto de n8n
EXPOSE 5678

# Comando para iniciar la aplicación
CMD ["node", "packages/cli/bin/n8n"]
