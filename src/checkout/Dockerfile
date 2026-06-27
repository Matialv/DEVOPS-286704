# 1. Congelar la versión menor exacta de Node Alpine
ARG NODE_VERSION=22.14.0-alpine

# Stage 1: deps
FROM node:${NODE_VERSION} AS deps
WORKDIR /app

# Parche de seguridad para el SO base en la etapa de dependencias
RUN apk update && apk upgrade --no-cache

COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Habilitar Corepack y Yarn de forma segura
RUN corepack enable && corepack install && yarn install --immutable

# Stage 2: build
FROM node:${NODE_VERSION} AS builder
WORKDIR /app

# Parche de seguridad para el SO base en la etapa de build
RUN apk update && apk upgrade --no-cache

COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
COPY --from=deps /app/node_modules ./node_modules

RUN corepack enable && yarn build

# Stage 3: runtime (El entorno final que analiza Trivy)
FROM node:${NODE_VERSION}
WORKDIR /app

# Parche de seguridad crítico: actualiza paquetes del sistema base (corrige CVEs de Alpine)
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
