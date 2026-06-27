# Stage 1: deps 
ARG NODE_VERSION=22.14.0-alpine
FROM node:${NODE_VERSION} AS deps
WORKDIR /app
COPY package.json ./
# Actualiza parches de seguridad críticos del SO base y limpia caché de npm
RUN apk update && apk upgrade --no-cache && \
    npm install --omit=dev && \
    npm cache clean --force

# Stage 2: build
FROM node:${NODE_VERSION} AS builder
WORKDIR /app
COPY package.json tsconfig.json ./
# Actualiza parches de seguridad del SO base
RUN apk update && apk upgrade --no-cache && \
    npm install
COPY src ./src
COPY public ./public
RUN npm run build

# Stage 3: runtime
FROM node:${NODE_VERSION}
WORKDIR /app

# 1. Parche de seguridad crítico: actualiza paquetes del sistema base (corrige CVEs de Alpine)
RUN apk update && apk upgrade --no-cache

# 2. Configuración segura de usuario no-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 3. Copia de artefactos con permisos limpios
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/public ./public
COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules

USER appuser
ENV PORT=3001
EXPOSE 3001

CMD ["node", "dist/app.js"]