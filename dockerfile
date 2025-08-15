# --- Etapa 1: Builder ---
# Aquí instalamos todo (incluyendo dependencias de desarrollo) y construimos el proyecto.
FROM node:22-alpine AS builder

# Instalar las herramientas de compilación necesarias para node-gyp
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Instalar pnpm
RUN npm install -g pnpm@10

# --- INICIO DEL CAMBIO ---
# Copiar todo el código fuente del proyecto PRIMERO
COPY . .

# Ahora que todos los archivos están presentes, instalar las dependencias
RUN pnpm install
# --- FIN DEL CAMBIO ---

# Construir el proyecto
RUN pnpm run build


# --- Etapa 2: Production ---
# Aquí creamos la imagen final, copiando solo los artefactos de la etapa anterior.
FROM node:22-alpine

WORKDIR /app

# Instalar pnpm para manejar las dependencias de producción
RUN npm install -g pnpm@10

# Copiar los manifiestos desde la etapa de 'builder'
COPY --from=builder /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./

# Copiar SOLO el paquete 'cli' ya compilado desde la etapa de 'builder'
COPY --from=builder /app/packages/cli ./packages/cli

# Instalar únicamente las dependencias de PRODUCCIÓN para el paquete 'cli'
RUN pnpm install --prod --filter=@n8n/cli

# Exponer el puerto por defecto de n8n
EXPOSE 5678

# Comando para iniciar la aplicación
CMD ["node", "packages/cli/bin/n8n"]
