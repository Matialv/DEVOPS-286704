ARG NODE_VERSION=22.14.0-alpine

# Stage 1: deps
FROM node:${NODE_VERSION} AS deps
WORKDIR /app

RUN apk update && apk upgrade --no-cache && apk add --no-cache jq

COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

RUN jq '.resolutions = { \
    "@grpc/grpc-js": "^1.12.0", \
    "protobufjs": "^7.4.0", \
    "undici": "^6.21.1", \
    "lodash": "^4.17.21", \
    "js-yaml": "^4.1.0", \
    "minimatch": "^9.0.5", \
    "qs": "^6.13.1", \
    "systeminformation": "^5.23.5" \
  }' package.json > package.json.tmp && mv package.json.tmp package.json

RUN npm install -g corepack@latest --force && \
    corepack enable && \
    corepack prepare yarn@4.11.0 --activate && \
    yarn install

# Stage 2: build
FROM node:${NODE_VERSION} AS builder
WORKDIR /app

RUN apk update && apk upgrade --no-cache && apk add --no-cache jq

COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
COPY --from=deps /app/node_modules ./node_modules

RUN jq '.resolutions = { \
    "@grpc/grpc-js": "^1.12.0", \
    "protobufjs": "^7.4.0", \
    "undici": "^6.21.1", \
    "lodash": "^4.17.21", \
    "js-yaml": "^4.1.0", \
    "minimatch": "^9.0.5", \
    "qs": "^6.13.1", \
    "systeminformation": "^5.23.5" \
  }' package.json > package.json.tmp && mv package.json.tmp package.json

RUN npm install -g corepack@latest --force && \
    corepack enable && \
    corepack prepare yarn@4.11.0 --activate && \
    yarn build

# Stage 3: runtime
FROM node:${NODE_VERSION}
WORKDIR /app

RUN apk update && apk upgrade --no-cache

# 🔥 CUMPLIMIENTO DE SEGURIDAD: Usuario y grupo de sistema personalizados (No root, no appuser)
RUN addgroup -S checkoutgroup && adduser -S checkoutuser -G checkoutgroup

# Copiar artefactos asignando la propiedad al usuario personalizado
COPY --from=builder --chown=checkoutuser:checkoutgroup /app/dist ./dist
COPY --from=deps --chown=checkoutuser:checkoutgroup /app/node_modules ./node_modules

USER checkoutuser
ENV PORT=8003
EXPOSE 8003

CMD ["node", "dist/main.js"]
