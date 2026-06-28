FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev

# Stage 2: build
FROM node:24-alpine AS builder
WORKDIR /app
COPY package.json tsconfig.json ./
RUN npm install
COPY src ./src
COPY public ./public
RUN npm run build

# Stage 3: runtime
FROM node:24-alpine
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/public ./public
COPY --from=deps --chown=appuser:appgroup /app/node_modules ./node_modules
USER appuser
ENV PORT=3001
EXPOSE 3001
CMD ["node", "dist/app.js"]