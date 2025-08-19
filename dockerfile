# Usa una imagen específica de Debian Bookworm como base
FROM node:22-bookworm AS base

# Instala pnpm globalmente
RUN npm install -g pnpm@10

# Crea el directorio de la aplicación
WORKDIR /app

# --- Etapa de Dependencias ---
FROM base AS dependencies

# Copia los manifiestos del proyecto
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Copia la carpeta de parches para que pnpm pueda aplicarlos
COPY patches ./patches

# Instala TODAS las dependencias.
RUN pnpm install --frozen-lockfile

# --- Etapa de Compilación (Builder) ---
FROM base AS builder

# Copia las dependencias ya instaladas de la etapa anterior
COPY --from=dependencies /app/node_modules ./node_modules

# Copia todo el código fuente del proyecto
COPY . .

# Aumenta el límite de memoria de Node.js
ENV NODE_OPTIONS=--max-old-space-size=8192

# Ejecuta el script de compilación oficial del proyecto
RUN pnpm run build

# --- Etapa Final de Producción ---
FROM base AS final

# Establece el entorno a producción
ENV NODE_ENV=production

# Copia los manifiestos del proyecto
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./

# Copia la carpeta de parches también para la instalación de producción
COPY patches ./patches

# --- INICIO DEL CAMBIO ---
# Instala únicamente las dependencias de PRODUCCIÓN, ignorando scripts.
RUN pnpm install --prod --frozen-lockfile --ignore-scripts