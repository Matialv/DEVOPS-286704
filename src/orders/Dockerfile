FROM golang:1.25-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o orders .

# Stage 2: runtime
FROM gcr.io/distroless/static:nonroot
WORKDIR /app
COPY --from=builder /app/orders .
EXPOSE 8080
USER nonroot:nonroot
CMD ["/app/orders"]
