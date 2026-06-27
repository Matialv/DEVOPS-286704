# 1. Congelar la versión menor exacta para garantizar builds reproducibles
ARG GOLANG_VERSION=1.25.1-alpine
ARG DISTROLESS_VERSION=nonroot

# Stage 1: build
FROM golang:${GOLANG_VERSION} AS builder
WORKDIR /app

# Parche de seguridad para el entorno de compilación
RUN apk update && apk upgrade --no-cache

COPY go.mod go.sum ./
RUN go mod download

# Copiar el código fuente de Go
COPY *.go ./

# Compilación estática segura
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o orders .

# Stage 2: runtime
FROM gcr.io/distroless/static:${DISTROLESS_VERSION}
WORKDIR /app

# Copiar el binario estático limpio
COPY --from=builder /app/orders .

EXPOSE 8004
USER nonroot:nonroot

CMD ["/app/orders"]
