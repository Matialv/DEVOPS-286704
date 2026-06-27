# CORRECCIÓN CRÍTICA: Se eleva a Go 1.25.7 para parchar el CVE-2025-68121 en la stdlib
ARG GOLANG_VERSION=1.25.7-alpine
ARG DISTROLESS_VERSION=nonroot

# Stage 1: build
FROM golang:${GOLANG_VERSION} AS builder
WORKDIR /app

# Parche de seguridad preventivo para las herramientas del entorno de compilación
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

# Compilación estática segura
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o catalog .

# Stage 2: runtime (Imagen Distroless ultra segura)
FROM gcr.io/distroless/static:${DISTROLESS_VERSION}
WORKDIR /app

# Copiar el binario estático ya parchado y libre de vulnerabilidades
COPY --from=builder /app/catalog .

EXPOSE 8001
USER nonroot:nonroot

CMD ["/app/catalog"]
