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

# --- INICIO DEL CAMBIO ---
# Instalar dependencias ignorando los scripts de post-instalación
# para evitar que scripts problemáticos de paquetes individuales fallen.
RUN pnpm install --ignore-scripts
# --- FIN DEL CAMBIO ---

# Construir el proyecto. Este paso compilará todo lo necesario.
RUN pnpm run build


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
