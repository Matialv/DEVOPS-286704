# Stage 1: deps
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json yarn.lock .yarnrc.yml* ./
RUN corepack enable && yarn install --immutable

# Stage 2: build
FROM node:22-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN yarn build

# Stage 3: runtime
FROM node:22-alpine
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules
USER appuser
EXPOSE 8080
CMD ["node", "dist/main.js"]
