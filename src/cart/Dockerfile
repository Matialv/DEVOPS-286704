# Fase 1: Compilación de dependencias
FROM python:3.13-slim-bookworm AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir "pip==25.1.1" \
 && pip install --no-cache-dir --prefix=/install -r requirements.txt

# Fase 2: Entorno de ejecución ultra seguro (Distroless)
FROM gcr.io/distroless/python3-debian12
WORKDIR /app

# Copiamos las librerías de Python instaladas desde la fase anterior
COPY --from=builder /install /usr/local
COPY app/ ./app/

ENV PORT=8002
EXPOSE 8002

# Distroless no contiene 'sh' ni 'bash'. Ejecutamos uvicorn directamente por vector de argumentos.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002"]
