#!/bin/bash
# Smoke tests para RetailStore — verifican disponibilidad de servicios post-deploy
# No modifica el código fuente; opera contra endpoints HTTP externos
# Uso: ./tests/smoke-tests.sh [base-url]
# Ejemplo: ./tests/smoke-tests.sh http://my-alb.us-east-1.elb.amazonaws.com

set -euo pipefail

BASE_URL="${1:-http://retailstore-dev-alb-1858888559.us-east-1.elb.amazonaws.com}"
TIMEOUT=10
PASS=0
FAIL=0

check() {
  local name="$1"
  local url="$2"
  local expected_status="${3:-200}"

  actual_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$url" 2>/dev/null || echo "000")

  if [ "$actual_status" = "$expected_status" ]; then
    echo "  ✓ $name → $url [$actual_status]"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name → $url [esperado $expected_status, recibido $actual_status]"
    FAIL=$((FAIL + 1))
  fi
}

echo ""
echo "════════════════════════════════════════"
echo "  RetailStore — Smoke Tests"
echo "  Base URL: $BASE_URL"
echo "════════════════════════════════════════"
echo ""

echo "▶ Catalog Service (Go - puerto 8001)"
check "Catalog health"    "$BASE_URL:8001/health"
check "Catalog products"  "$BASE_URL:8001/catalog/products"

echo ""
echo "▶ Cart Service (Python - puerto 8002)"
check "Cart health"       "$BASE_URL:8002/health"
check "Cart endpoint"     "$BASE_URL:8002/carts/smoke-test-user"

echo ""
echo "▶ Checkout Service (NestJS - puerto 8003)"
check "Checkout health"   "$BASE_URL:8003/health"

echo ""
echo "▶ Orders Service (Go - puerto 8004)"
check "Orders health"     "$BASE_URL:8004/health"
check "Orders list"       "$BASE_URL:8004/orders"

echo ""
echo "▶ UI Service (Express - puerto 80)"
check "UI homepage"       "$BASE_URL" "200"

echo ""
echo "▶ Admin Service (Express - puerto 3001)"
check "Admin homepage"    "$BASE_URL:3001" "200"

echo ""
echo "════════════════════════════════════════"
echo "  Resultados: $PASS pasaron, $FAIL fallaron"
echo "════════════════════════════════════════"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "❌ Smoke tests FALLARON — revisar servicios antes de continuar"
  exit 1
else
  echo "✅ Todos los smoke tests pasaron"
  exit 0
fi
