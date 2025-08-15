# --- Etapa 1: Builder ---
# Usamos una imagen completa basada en Debian para asegurar que todas las herramientas de compilación funcionen.
FROM node:22-bookworm AS builder

WORKDIR /app

# Instalar pnpm
RUN npm install -g pnpm@10

# Copiar todo el código fuente del proyecto
COPY . .

# --- INICIO DEL CAMBIO ---
# Aumentar el límite de memoria para Node.js antes de ejecutar la instalación.
# Esto es crucial para monorepos grandes en entornos con memoria limitada.
ENV NODE_OPTIONS=--max-old-space-size=8192
# --- FIN DEL CAMBIO ---

# Instalar todas las dependencias
RUN pnpm install

# Construir el proyecto
RUN pnpm run build


# --- Etapa 2: Production ---
# Volvemos a la imagen ligera 'alpine' para la imagen final.
FROM node:22-alpine

WORKDIR /app

# Instalar pnpm para manejar el workspace
RUN npm install -g pnpm@10

# Copiar los manifiestos desde la etapa de 'builder'
COPY --from=builder /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./

# Copiar SOLO el paquete 'cli' ya compilado desde la etapa de 'builder'
COPY --from=builder /app/packages/cli ./packages/cli

# Instalar únicamente las dependencias de PRODUCCIÓN.
RUN pnpm install --prod --filter=@n8n/cli

# Exponer el puerto por defecto de n8n
EXPOSE 5678

# Comando para iniciar la aplicación
CMD ["node", "packages/cli/bin/n8n"]
