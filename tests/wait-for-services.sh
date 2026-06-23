#!/bin/bash
# Espera hasta que todos los servicios respondan HTTP 200
# Uso: ./tests/wait-for-services.sh [base-url] [timeout-segundos]

BASE_URL="${1:-http://retailstore-dev-alb-1858888559.us-east-1.elb.amazonaws.com}"
MAX_WAIT="${2:-300}"
INTERVAL=10
ELAPSED=0

ENDPOINTS=(
  "$BASE_URL:8001/health"
  "$BASE_URL:8002/health"
  "$BASE_URL:8003/health"
  "$BASE_URL:8004/health"
  "$BASE_URL"
  "$BASE_URL:3001"
)

echo "Esperando que los servicios estén listos (máx ${MAX_WAIT}s)..."

while [ "$ELAPSED" -lt "$MAX_WAIT" ]; do
  ALL_UP=true

  for url in "${ENDPOINTS[@]}"; do
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url" 2>/dev/null || echo "000")
    if [ "$status" != "200" ]; then
      ALL_UP=false
      break
    fi
  done

  if [ "$ALL_UP" = "true" ]; then
    echo "✅ Todos los servicios están listos (${ELAPSED}s)"
    exit 0
  fi

  echo "  Esperando... (${ELAPSED}s / ${MAX_WAIT}s)"
  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "❌ Timeout: servicios no respondieron en ${MAX_WAIT}s"
exit 1
