#!/bin/bash
# Smoke tests para RetailStore — verifican disponibilidad y funcionalidad post-deploy
# Uso: ./tests/smoke-tests.sh [base-url]
# Ejemplo: ./tests/smoke-tests.sh http://my-alb.us-east-1.elb.amazonaws.com

set -euo pipefail

BASE_URL="${1:-http://retailstore-dev-alb-1858888559.us-east-1.elb.amazonaws.com}"
TIMEOUT=15
PASS=0
FAIL=0
CUSTOMER_ID="smoke-test-user"
PRODUCT_ID=""
ADMIN_TOKEN=""

# ─── helpers ────────────────────────────────────────────────────────────────

check() {
  local name="$1"
  local url="$2"
  local expected_status="${3:-200}"

  actual_status=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time "$TIMEOUT" "$url" 2>/dev/null || echo "000")

  if [ "$actual_status" = "$expected_status" ]; then
    echo "  ✓ $name [$actual_status]"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name [esperado $expected_status, recibido $actual_status] → $url"
    FAIL=$((FAIL + 1))
  fi
}

check_post() {
  local name="$1"
  local url="$2"
  local body="$3"
  local expected_status="${4:-200}"
  local extra_flags="${5:-}"

  actual_status=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time "$TIMEOUT" \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$body" \
    $extra_flags \
    "$url" 2>/dev/null || echo "000")

  if [ "$actual_status" = "$expected_status" ]; then
    echo "  ✓ $name [$actual_status]"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name [esperado $expected_status, recibido $actual_status] → $url"
    FAIL=$((FAIL + 1))
  fi
}

check_json_field() {
  local name="$1"
  local url="$2"
  local json_field="$3"   # campo a verificar que exista en la respuesta

  response=$(curl -s --max-time "$TIMEOUT" "$url" 2>/dev/null || echo "{}")
  if echo "$response" | grep -q "\"$json_field\""; then
    echo "  ✓ $name (campo '$json_field' presente)"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name (campo '$json_field' ausente en respuesta) → $url"
    FAIL=$((FAIL + 1))
  fi
}

section() {
  echo ""
  echo "▶ $1"
}

# ─── inicio ─────────────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════"
echo "  RetailStore — Smoke Tests"
echo "  Base URL: $BASE_URL"
echo "════════════════════════════════════════════════"

# ─── CATALOG ─────────────────────────────────────────────────────────────────

section "Catalog Service"
check          "Health check"                "$BASE_URL:8001/health"
check_json_field "Listar productos"          "$BASE_URL:8001/catalog/products" "products"
check_json_field "Listar productos paginado" "$BASE_URL:8001/catalog/products?page=1&size=5" "products"
check_json_field "Filtrar por tag"           "$BASE_URL:8001/catalog/products?tags=featured" "products"
check_json_field "Cantidad de productos"     "$BASE_URL:8001/catalog/size" "size"
check_json_field "Listar tags"               "$BASE_URL:8001/catalog/tags" "tags"
check          "Topology"                    "$BASE_URL:8001/topology"

# Obtener primer productId para tests posteriores
PRODUCT_ID=$(curl -s --max-time "$TIMEOUT" \
  "$BASE_URL:8001/catalog/products?page=1&size=1" 2>/dev/null \
  | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")

if [ -n "$PRODUCT_ID" ]; then
  check_json_field "Producto por ID ($PRODUCT_ID)" \
    "$BASE_URL:8001/catalog/products/$PRODUCT_ID" "id"
else
  echo "  ⚠ No se pudo extraer PRODUCT_ID — omitiendo test de producto por ID"
fi

# ─── CART ────────────────────────────────────────────────────────────────────

section "Cart Service"
check          "Health check"                "$BASE_URL:8002/health"
check          "Obtener carrito"             "$BASE_URL:8002/carts/$CUSTOMER_ID"
check          "Listar items del carrito"    "$BASE_URL:8002/carts/$CUSTOMER_ID/items"
check          "Topology"                    "$BASE_URL:8002/topology"

# Agregar item al carrito (POST)
ITEM_BODY="{\"productId\":\"smoke-product\",\"name\":\"Smoke Test Product\",\"quantity\":1,\"price\":9.99}"
check_post     "Agregar item al carrito" \
  "$BASE_URL:8002/carts/$CUSTOMER_ID/items" "$ITEM_BODY" "201"

# Limpiar el carrito al final de esta sección
curl -s -X DELETE --max-time "$TIMEOUT" \
  "$BASE_URL:8002/carts/$CUSTOMER_ID" >/dev/null 2>&1 || true

# ─── CHECKOUT ────────────────────────────────────────────────────────────────

section "Checkout Service"
check          "Health check"                "$BASE_URL:8003/health"
check          "Obtener checkout"            "$BASE_URL:8003/checkout/$CUSTOMER_ID"
check          "Topology"                    "$BASE_URL:8003/topology"

# Actualizar checkout con dirección e items
CHECKOUT_BODY='{
  "items": [{"productId":"smoke-product","name":"Smoke Test Product","quantity":1,"price":9.99}],
  "shippingAddress": {
    "firstName":"Smoke","lastName":"Test","email":"smoke@test.com",
    "address1":"Calle Test 123","city":"Montevideo","state":"Montevideo","zipCode":"11300"
  }
}'
check_post "Actualizar checkout" \
  "$BASE_URL:8003/checkout/$CUSTOMER_ID/update" "$CHECKOUT_BODY" "200"

# ─── ORDERS ──────────────────────────────────────────────────────────────────

section "Orders Service"
check          "Health check"                "$BASE_URL:8004/health"
check_json_field "Listar órdenes"            "$BASE_URL:8004/orders" "orders"

# Crear orden de prueba (POST)
ORDER_BODY='{
  "shippingAddress": {
    "firstName":"Smoke","lastName":"Test","email":"smoke@test.com",
    "address1":"Calle Test 123","city":"Montevideo","state":"Montevideo","zipCode":"11300"
  },
  "items": [{"productId":"smoke-product","name":"Smoke Test Product","quantity":1,"price":9.99}]
}'
check_post "Crear orden" \
  "$BASE_URL:8004/orders" "$ORDER_BODY" "201"

# ─── ADMIN ───────────────────────────────────────────────────────────────────

section "Admin Service"
check          "Health check"                "$BASE_URL:3001/health"
check          "Homepage admin"              "$BASE_URL:3001"

# Login y captura de token
LOGIN_RESPONSE=$(curl -s -c /tmp/smoke_cookies.txt \
  --max-time "$TIMEOUT" \
  -X POST -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}' \
  -w "\n%{http_code}" \
  "$BASE_URL:3001/auth/login" 2>/dev/null || echo -e "\n000")

LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | tail -1)
if [ "$LOGIN_STATUS" = "200" ] || [ "$LOGIN_STATUS" = "201" ]; then
  echo "  ✓ Admin login [$LOGIN_STATUS]"
  PASS=$((PASS + 1))

  # Verificar sesión
  ME_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time "$TIMEOUT" \
    -b /tmp/smoke_cookies.txt \
    "$BASE_URL:3001/auth/me" 2>/dev/null || echo "000")
  if [ "$ME_STATUS" = "200" ]; then
    echo "  ✓ Verificar sesión JWT [$ME_STATUS]"
    PASS=$((PASS + 1))
  else
    echo "  ✗ Verificar sesión JWT [esperado 200, recibido $ME_STATUS]"
    FAIL=$((FAIL + 1))
  fi

  # Listar productos (requiere auth)
  check_json_field_auth() {
    local pname="$1" purl="$2" pfield="$3"
    resp=$(curl -s --max-time "$TIMEOUT" -b /tmp/smoke_cookies.txt "$purl" 2>/dev/null || echo "{}")
    if echo "$resp" | grep -q "\"$pfield\""; then
      echo "  ✓ $pname (campo '$pfield' presente)"
      PASS=$((PASS + 1))
    else
      echo "  ✗ $pname (campo '$pfield' ausente)"
      FAIL=$((FAIL + 1))
    fi
  }
  check_json_field_auth "Admin listar productos" "$BASE_URL:3001/admin/api/products" "id"
  check_json_field_auth "Admin listar órdenes"   "$BASE_URL:3001/admin/api/orders"   "id"

  # Logout
  LOGOUT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    --max-time "$TIMEOUT" \
    -b /tmp/smoke_cookies.txt \
    -X POST "$BASE_URL:3001/auth/logout" 2>/dev/null || echo "000")
  if [ "$LOGOUT_STATUS" = "200" ] || [ "$LOGOUT_STATUS" = "204" ]; then
    echo "  ✓ Admin logout [$LOGOUT_STATUS]"
    PASS=$((PASS + 1))
  else
    echo "  ✗ Admin logout [esperado 200/204, recibido $LOGOUT_STATUS]"
    FAIL=$((FAIL + 1))
  fi

  rm -f /tmp/smoke_cookies.txt
else
  echo "  ✗ Admin login [esperado 200, recibido $LOGIN_STATUS]"
  FAIL=$((FAIL + 1))
  echo "  ⚠ Tests de admin autenticados omitidos"
fi

# ─── UI (API GATEWAY) ────────────────────────────────────────────────────────

section "UI Service (API Gateway)"
check          "Health check"                "$BASE_URL/health"
check          "Homepage"                    "$BASE_URL"
check_json_field "Proxy → Catalog"           "$BASE_URL/api/catalog/products" "products"
check          "Proxy → Cart"                "$BASE_URL/api/carts/$CUSTOMER_ID"
check          "Proxy → Checkout"            "$BASE_URL/api/checkout/$CUSTOMER_ID"
check_json_field "Proxy → Orders"            "$BASE_URL/api/orders" "orders"

# ─── RESULTADO FINAL ─────────────────────────────────────────────────────────

echo ""
echo "════════════════════════════════════════════════"
printf "  Resultados: %s pasaron, %s fallaron\n" "$PASS" "$FAIL"
echo "════════════════════════════════════════════════"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "❌ Smoke tests FALLARON — revisar servicios antes de continuar"
  exit 1
else
  echo "✅ Todos los smoke tests pasaron"
  exit 0
fi
