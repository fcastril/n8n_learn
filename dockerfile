# --- Etapa 1: Builder ---
FROM node:22-bookworm AS builder

WORKDIR /app

RUN npm install -g pnpm@10

COPY . .

ENV NODE_OPTIONS=--max-old-space-size=8192

# Instalar y luego limpiar el caché
RUN pnpm install && pnpm store prune

# Construir el proyecto
RUN pnpm run build


# --- Etapa 2: Production ---
FROM node:22-alpine

WORKDIR /app

RUN npm install -g pnpm@10

COPY --from=builder /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/cli ./packages/cli

RUN pnpm install --prod --filter=@n8n/cli

EXPOSE 5678

CMD ["node", "packages/cli/bin/n8n"]
