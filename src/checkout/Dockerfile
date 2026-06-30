FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
RUN corepack enable && corepack install && yarn install

# Stage 2: build
FROM node:24-alpine AS builder
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src
COPY --from=deps /app/node_modules ./node_modules
RUN corepack enable && yarn build

# Stage 3: runtime
FROM node:24-alpine
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules
USER appuser
ENV PORT=8003
EXPOSE 8003
CMD ["node", "dist/main.js"]