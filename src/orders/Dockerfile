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
          golang.org/x/crypto \
          golang.org/x/net && \
    go mod tidy

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o orders .

# Stage 2: runtime
FROM gcr.io/distroless/static:${DISTROLESS_VERSION}
WORKDIR /app
COPY --from=builder /app/orders .
EXPOSE 8004

# 🔥 CUMPLIMIENTO DE SEGURIDAD: Usuario numérico personalizado (No root, no appuser)
USER 10002:10002

CMD ["/app/orders"]
