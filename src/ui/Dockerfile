# 1. Fijar versión menor exacta para evitar cambios de última hora en el CI
ARG NODE_VERSION=22.14.0-alpine

# Stage 1: deps (solo producción)
FROM node:${NODE_VERSION} AS deps
WORKDIR /app
COPY package.json ./
# Parche de seguridad para el SO base y limpieza preventiva de caché
RUN apk update && apk upgrade --no-cache && \
    npm install --omit=dev && \
    npm cache clean --force

# Stage 2: build
FROM node:${NODE_VERSION} AS builder
WORKDIR /app
COPY package.json tsconfig.json ./
# Parche de seguridad para el SO base en la etapa de compilación
RUN apk update && apk upgrade --no-cache && \
    npm install
COPY src ./src
COPY public ./public
RUN npm run build

# Stage 3: runtime (El entorno final que audita Trivy)
FROM node:${NODE_VERSION}
WORKDIR /app

# Parche de seguridad crítico: actualiza paquetes del sistema base (corrige CVEs de Alpine)
RUN apk update && apk upgrade --no-cache

# Configuración segura de usuario no-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copia de artefactos con permisos y propietarios limpios
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/public ./public
COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules

USER appuser
ENV PORT=3000
EXPOSE 3000

CMD ["node", "dist/app.js"]
