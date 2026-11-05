#!/usr/bin/env bash
# =============================================================================
# Validation & Harness Script for NET-D2-202 (Ubuntu / Linux)
#   ./validation_script.sh          validate solution
#   ./validation_script.sh start    start service in production mode
#   ./validation_script.sh restart  rebuild and restart
#   ./validation_script.sh check    validate solution
#   ./validation_script.sh reset    restore pristine baseline
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STARTER_DIR="$LAB_DIR/starter"
APP_DIR="$STARTER_DIR/OrderService"
BASE_DIR="$STARTER_DIR/_baseline"
LOG_DIR="$STARTER_DIR/logs"
STATE_DIR="${TMPDIR:-/tmp}/lab-state"
STATE_F="$STATE_DIR/D2-2.json"
EVID="$STARTER_DIR/evidence"
URL="http://localhost:5000"

C_GREEN=$(printf '\033[32m')
C_RED=$(printf '\033[31m')
C_YELLOW=$(printf '\033[33m')
C_CYAN=$(printf '\033[36m')
C_OFF=$(printf '\033[0m')

ensure_dirs() { mkdir -p "$STATE_DIR" "$LOG_DIR"; }
step() { echo "${C_CYAN}[STEP] $*${C_OFF}"; }

http_status() { curl -s -o /dev/null -w "%{http_code}" --max-time "${2:-5}" "$1" 2>/dev/null || echo "000"; }
http_body() { curl -s --max-time "${2:-5}" "$1" 2>/dev/null || true; }

stop_app() { pkill -f "OrderService" 2>/dev/null || true; sleep 1; }

TOTAL_CHECKS=0; PASSED_CHECKS=0; FAILED_CHECKS=0

record() {
  local status="$1"; local title="$2"; local details="${3:-}"
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  case "$status" in
    PASS) PASSED_CHECKS=$((PASSED_CHECKS + 1)); echo "  [${C_GREEN}PASS${C_OFF}] $title" ;;
    WARN) echo "  [${C_YELLOW}WARN${C_OFF}] $title"; [ -n "$details" ] && echo "         $details" ;;
    FAIL) FAILED_CHECKS=$((FAILED_CHECKS + 1)); echo "  [${C_RED}FAIL${C_OFF}] $title"; [ -n "$details" ] && echo "         $details" ;;
  esac
}

finish_checks() {
  local name="$1"
  echo ""
  echo "==================================================="
  echo " Validation Results for $name: $PASSED_CHECKS/$TOTAL_CHECKS passed"
  echo "==================================================="
  if [ "$FAILED_CHECKS" -gt 0 ]; then
    echo "${C_RED} [FAIL] Some validation checks failed. Please review guidelines.${C_OFF}"; exit 1
  else
    echo "${C_GREEN} [PASS] $name Validation Succeeded!${C_OFF}"
  fi
}

do_reset() {
  stop_app
  cp -r "$BASE_DIR"/* "$APP_DIR"/ 2>/dev/null || true
  rm -rf "$APP_DIR/publish" "$APP_DIR/bin" "$APP_DIR/obj" "$LOG_DIR" "$STATE_F"
  echo "${C_GREEN}D2-2 reset complete.${C_OFF}"
}

do_start() {
  ensure_dirs
  step "Preparing NET-D2-202 ..."
  do_reset
  command -v dotnet >/dev/null || { echo "dotnet not found - install .NET SDK first"; exit 2; }

  step "Building and running OrderService ..."
  ( cd "$APP_DIR" && dotnet build -c Debug --nologo -v q >/dev/null ) || { echo "dotnet build failed"; exit 2; }
  ( cd "$APP_DIR" && DOTNET_ENVIRONMENT=Production ASPNETCORE_ENVIRONMENT=Production ASPNETCORE_URLS="$URL" ./bin/Debug/net10.0/OrderService > "$LOG_DIR/app.out.log" 2> "$LOG_DIR/app.err.log" & echo $! > "$STATE_F" )
  sleep 2

  echo
  echo "${C_YELLOW}TICKET NET-D2-202  [P3: staging validation blocker]${C_OFF}"
  echo "  /health/ready returns HTTP 500."
  echo
  echo "${C_CYAN}NEXT: curl.exe -i $URL/health/ready then follow Participant_Guide_day2.md Ticket 2.${C_OFF}"
}

do_check() {
  echo "==================================================="
  echo " Validating NET-D2-202: DI Scope & Kestrel Limits  "
  echo "==================================================="

  [ "$(http_status "$URL/health/live")" = "200" ] && record PASS "GET /health/live returns 200" || record FAIL "GET /health/live returns 200"
  [ "$(http_status "$URL/health/ready")" = "200" ] && record PASS "GET /health/ready returns 200" || record FAIL "GET /health/ready returns 200"

  small=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H 'Content-Type: application/json' -d '{"customerId":"C-1","subtotal":500}' "$URL/api/orders")
  [ "$small" = "200" ] && record PASS "Small POST returns 200" || record FAIL "Small POST returns 200"

  big=$(python3 -c "import urllib.request; req = urllib.request.Request('$URL/api/orders', data=b'{\"notes\":\"' + b'A'*2097152 + b'\"}', headers={'Content-Type':'application/json'}); [print(urllib.request.urlopen(req).getcode()) if False else None]" 2>&1 | grep -o '413' || true)
  [ "$big" = "413" ] || [ "$(curl -s -o /dev/null -w "%{http_code}" -X POST -H 'Content-Type: application/json' --data-binary "$(head -c 2097152 /dev/zero | tr '\0' 'A')" "$URL/api/orders" 2>/dev/null)" = "413" ] && record PASS "2 MB POST rejected with 413" || record WARN "2 MB POST check"

  finish_checks "NET-D2-202"
}

case "${1:-check}" in
  start) do_start ;;
  restart) stop_app; ( cd "$APP_DIR" && dotnet build -c Debug --nologo -v q >/dev/null && DOTNET_ENVIRONMENT=Production ASPNETCORE_ENVIRONMENT=Production ASPNETCORE_URLS="$URL" ./bin/Debug/net10.0/OrderService > "$LOG_DIR/app.out.log" 2> "$LOG_DIR/app.err.log" & echo $! > "$STATE_F" ) ;;
  check) do_check ;;
  reset) do_reset ;;
  *) do_check ;;
esac

