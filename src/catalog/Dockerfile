# Stage 1: build
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o catalog .

# Stage 2: runtime
FROM gcr.io/distroless/static:nonroot
WORKDIR /app
COPY --from=builder /app/catalog .
EXPOSE 8080
USER nonroot:nonroot
CMD ["/app/catalog"]
