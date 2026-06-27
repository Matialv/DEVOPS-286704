# 1. Fijar versiones menores exactas para garantizar estabilidad
ARG GOLANG_VERSION=1.25.1-alpine
ARG DISTROLESS_VERSION=nonroot

# Stage 1: build
FROM golang:${GOLANG_VERSION} AS builder
WORKDIR /app

# Parche de seguridad para el entorno de compilación de Alpine
RUN apk update && apk upgrade --no-cache

COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./
COPY api ./api
COPY config ./config
COPY controller ./controller
COPY httputil ./httputil
COPY middleware ./middleware
COPY model ./model
COPY repository ./repository

# Compilación estática segura sin dependencias externas
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o catalog .

# Stage 2: runtime
FROM gcr.io/distroless/static:${DISTROLESS_VERSION}
WORKDIR /app

# Copiar el binario compilado de forma segura
COPY --from=builder /app/catalog .

EXPOSE 8001
USER nonroot:nonroot

CMD ["/app/catalog"]
