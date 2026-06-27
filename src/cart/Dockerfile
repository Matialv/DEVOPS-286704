# 1. Definir una versión exacta para congelar la imagen base y evitar sorpresas
ARG PYTHON_VERSION=3.13.2-slim

# Stage 1: deps
FROM python:${PYTHON_VERSION} AS builder
WORKDIR /app

# Parchar el sistema operativo también en el builder antes de compilar/instalar
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Forzar una versión ultra segura de pip, actualizar herramientas de empaquetado 
# y realizar una auditoría automática de las dependencias de Python
RUN pip install --no-cache-dir "pip==25.1.1" "setuptools>=70.0.0" \
 && pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: runtime
FROM python:${PYTHON_VERSION}
WORKDIR /app

# Parche de seguridad crítico para el SO (Debian)
RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

# Configuración segura de usuario no-root
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Copiar las librerías de Python ya verificadas
COPY --from=builder /install /usr/local
COPY --chown=appuser:appgroup app/ ./app/

USER appuser
ENV PORT=8002
EXPOSE 8002

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port $PORT"]