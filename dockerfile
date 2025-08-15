# --- Etapa 1: Builder ---
FROM node:22-bookworm AS builder
RUN apt-get update && apt-get install -y build-essential libsqlite3-dev --no-install-recommends
WORKDIR /app
RUN npm install -g pnpm@10
COPY . .
ENV NODE_OPTIONS=--max-old-space-size=8192
RUN pnpm install --ignore-scripts
RUN pnpm exec turbo run build --filter="!@n8n/n8n-nodes-langchain"

# --- Etapa 2: Production ---
FROM node:22-alpine
WORKDIR /app
RUN npm install -g pnpm@10
COPY --from=builder /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./
COPY --from=builder /app/packages/cli ./packages/cli
RUN pnpm install --prod --filter=@n8n/cli --ignore-scripts
EXPOSE 5678
CMD ["node", "packages/cli/bin/n8n"]
