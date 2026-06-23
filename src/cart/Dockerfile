# Stage 1: deps
FROM python:3.13-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: runtime
FROM python:3.13-slim
WORKDIR /app
# Patch OS packages to eliminate known CVEs in base image layers
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
COPY --from=builder /install /usr/local
COPY --chown=appuser:appgroup app/ ./app/
USER appuser
ENV PORT=8002
EXPOSE 8002
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
