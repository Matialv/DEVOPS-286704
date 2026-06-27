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

# Copiar el código fuente de Go
COPY *.go ./

# Compilación estática segura libre de dependencias del sistema operativo
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o orders .

# Stage 2: runtime (Imagen Distroless ultra segura)
FROM gcr.io/distroless/static:${DISTROLESS_VERSION}
WORKDIR /app

# Copiar el binario estático ya parchado y libre de vulnerabilidades
COPY --from=builder /app/orders .

EXPOSE 8004
USER nonroot:nonroot

CMD ["/app/orders"]
