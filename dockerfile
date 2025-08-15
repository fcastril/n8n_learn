# --- Etapa 1: Builder ---
# Usamos la imagen robusta para la compilación
FROM node:22-bookworm AS builder

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
# Construir el proyecto, excluyendo el paquete problemático @n8n/n8n-nodes-langchain
# usando el flag --filter de Turbo.
RUN pnpm run build --filter="!@n8n/n8n-nodes-langchain"
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
