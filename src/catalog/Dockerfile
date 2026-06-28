ARG GOLANG_VERSION=1.25.7-alpine
ARG DISTROLESS_VERSION=nonroot

# Stage 1: build
FROM golang:${GOLANG_VERSION} AS builder
WORKDIR /app

RUN apk update && apk upgrade --no-cache

COPY go.mod go.sum ./

# Corregir dependencias vulnerables en caliente antes de compilar
RUN go mod download && \
    go get -u ://github.com \
          go.opentelemetry.io/otel \
          go.opentelemetry.io/otel/sdk \
          golang.org/x/crypto \
          golang.org/x/net \
          golang.org/x/sys && \
    go mod tidy

COPY main.go ./
COPY api ./api
COPY config ./config
COPY controller ./controller
COPY httputil ./httputil
COPY middleware ./middleware
COPY model ./model
COPY repository ./repository

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o catalog .

# Stage 2: runtime
FROM gcr.io/distroless/static:${DISTROLESS_VERSION}
WORKDIR /app
COPY --from=builder /app/catalog .
EXPOSE 8001

# 🔥 CUMPLIMIENTO DE SEGURIDAD: Usuario numérico personalizado (No root, no appuser)
USER 10001:10001

CMD ["/app/catalog"]
