FROM python:3.11-slim-bookworm AS builder
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir "pip==25.1.1" \
 && pip install --no-cache-dir -r requirements.txt

FROM gcr.io/distroless/python3-debian12:nonroot
WORKDIR /app

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin/uvicorn                  /usr/local/bin/uvicorn
COPY app/ ./app/

ENV PORT=8002
EXPOSE 8002

CMD ["/usr/local/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002"]
