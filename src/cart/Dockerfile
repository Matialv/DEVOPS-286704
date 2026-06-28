# 1. Usar la misma versión de Python que tiene la imagen Distroless (3.11)
FROM python:3.11-slim-bookworm AS builder
WORKDIR /app

COPY requirements.txt .

# 2. Instalar dependencias en el prefijo correcto
RUN pip install --no-cache-dir "pip==25.1.1" \
 && pip install --no-cache-dir --prefix=/install -r requirements.txt

# 3. Imagen final Distroless basado en Python 3.11
FROM gcr.io/distroless/python3-debian12:nonroot
WORKDIR /app

# 4. Copiar los artefactos instalados y el código de la app
COPY --from=builder /install /usr/local
COPY app/ ./app/

ENV PORT=8002
EXPOSE 8002

# 5. Corrección del comando usando la ruta absoluta o el módulo de python
CMD ["/usr/local/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002"]
