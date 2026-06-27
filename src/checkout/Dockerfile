ARG NODE_VERSION=22.14.0-alpine

# Stage 1: deps
FROM node:${NODE_VERSION} AS deps
WORKDIR /app

# Parche de seguridad para el SO base Alpine
RUN apk update && apk upgrade --no-cache

COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# CORRECCIÓN YARN v4: Habilitar corepack e instalar dependencias de forma inmutable
RUN corepack enable && yarn install --immutable

# Stage 2: build
FROM node:${NODE_VERSION} AS builder
WORKDIR /app

# Parche de seguridad para el SO base Alpine
RUN apk update && apk upgrade --no-cache

COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
COPY --from=deps /app/node_modules ./node_modules

# CORRECCIÓN YARN v4: Habilitar corepack y ejecutar el build de NestJS
RUN corepack enable && yarn build

# Stage 3: runtime (Producción)
FROM node:${NODE_VERSION}
WORKDIR /app

# Parche de seguridad crítico para pasar Trivy sin vulnerabilidades OS
RUN apk update && apk upgrade --no-cache

# Configuración segura de usuario no-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiar artefactos finales con permisos limpios
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules

USER appuser
ENV PORT=8003
EXPOSE 8003

CMD ["node", "dist/main.js"]
