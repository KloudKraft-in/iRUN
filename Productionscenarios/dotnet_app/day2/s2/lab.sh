#!/usr/bin/env bash
# =============================================================================
# lab.sh - NET-D2-202 harness - "Release Passes Startup but Health Check Fails in Production" (Ubuntu)
#   ./lab.sh start     restore the starting code, build, and run OrderService in PRODUCTION mode on :5000
#   ./lab.sh restart   stop, rebuild YOUR changes, run again (use after every code edit)
#   ./lab.sh check     validate your fix, your publish folder and your evidence
#   ./lab.sh reset     stop the app and restore the starting code (also removes ./OrderService/publish)
# No sudo needed.
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$LAB_DIR/../common/lab-common.sh"

APP_DIR="$LAB_DIR/OrderService"
BASE_DIR="$LAB_DIR/_baseline"
LOG_DIR="$LAB_DIR/logs"
EXE="$APP_DIR/bin/Debug/net10.0/OrderService"
EVID="$LAB_DIR/evidence"
URL="http://localhost:5000"
mkdir -p "$STATE_DIR" 2>/dev/null || $SUDO mkdir -p "$STATE_DIR"
STATE_F="$STATE_DIR/D2-2.json"

live_up() { [ "$(http_status "$URL/health/live")" = "200" ]; }
stop_app() { pkill -x OrderService 2>/dev/null || true; sleep 0.5; }
restore_baseline() { cp -a "$BASE_DIR/." "$APP_DIR/"; rm -rf "$APP_DIR/publish"; }
build_app() {
  step "dotnet build ..."
  if ! out="$(dotnet build "$APP_DIR" -c Debug --nologo -v q 2>&1)"; then echo "$out"; echo "${C_RED}BUILD FAILED - fix the compile error and run: ./lab.sh restart${C_OFF}"; exit 2; fi
}
start_app() {
  mkdir -p "$LOG_DIR"
  DOTNET_ENVIRONMENT=Production ASPNETCORE_ENVIRONMENT=Production ASPNETCORE_URLS="$URL" \
    nohup "$EXE" >"$LOG_DIR/app.out.log" 2>"$LOG_DIR/app.err.log" &
  APP_PID=$!; disown
  printf '{"pid": %s, "startedUtc": "%s"}\n' "$APP_PID" "$(date -u +%FT%TZ)" > "$STATE_F"
  wait_until 30 live_up || { echo "${C_RED}App did not answer on $URL - see $LOG_DIR/app.out.log${C_OFF}"; exit 2; }
}

do_start() {
  step "Preparing NET-D2-202 ..."
  command -v dotnet >/dev/null || die "dotnet not found - run the setup script first"
  stop_app; restore_baseline; build_app; start_app
  echo
  echo "${C_YELLOW}TICKET NET-D2-202  [P3: staging / pre-release validation blocker]${C_OFF}"
  echo "  The release started cleanly and the pipeline reported success - but the load balancer marks the node unhealthy:"
  echo "  /health/ready returns HTTP 500 and /api/orders throws InvalidOperationException."
  echo "  Logs: $LOG_DIR/app.out.log and app.err.log"
  echo
  echo "${C_CYAN}NEXT:${C_OFF} curl -i $URL/health/live ; curl -i $URL/health/ready   then follow 02_Participant_Guide.md section D2-2."
}
do_restart() { step "Restarting OrderService with your latest code ..."; stop_app; build_app; start_app; echo "${C_GREEN}Running again on $URL (Production mode).${C_OFF}"; }
do_reset() {
  stop_app; restore_baseline
  rm -rf "$APP_DIR/bin" "$APP_DIR/obj" "$LOG_DIR" "$STATE_F"
  echo "${C_GREEN}D2-2 reset complete (app stopped, starting code restored, publish folder removed).${C_OFF}"
}

do_check() {
  [ -f "$STATE_F" ] || { echo "${C_YELLOW}Lab not started. Run: ./lab.sh start${C_OFF}"; exit 3; }

  [ "$(http_status "$URL/health/live")" = "200" ] && record PASS "GET /health/live returns 200" || record FAIL "GET /health/live returns 200"
  r="$(http_status "$URL/health/ready")"; [ "$r" = "200" ] && record PASS "GET /health/ready returns 200 (DI graph is complete)" || record FAIL "GET /health/ready returns 200 (DI graph is complete)" "got HTTP ${r:-000} - did you run ./lab.sh restart after editing Program.cs?"
  o="$(http_status "$URL/api/orders")"; [ "$o" = "200" ] && record PASS "GET /api/orders returns 200" || record FAIL "GET /api/orders returns 200" "got HTTP ${o:-000}"

  small="$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' -d '{"customerId":"C-9","subtotal":600}' "$URL/api/orders")"
  [ "$small" = "200" ] && record PASS "A normal (small) POST /api/orders still returns 200" || record FAIL "A normal (small) POST /api/orders still returns 200" "got $small - the limit must not be set too low"

  BIG="$(mktemp)"; { printf '{"customerId":"C-9","subtotal":100,"notes":"'; head -c 2097152 /dev/zero | tr '\0' 'A'; printf '"}'; } > "$BIG"
  code="$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Content-Type: application/json' --data-binary "@$BIG" "$URL/api/orders")"; rm -f "$BIG"
  [ "$code" = "413" ] && record PASS "A 2 MB POST /api/orders is rejected with 413 Payload Too Large" || record FAIL "A 2 MB POST /api/orders is rejected with 413 Payload Too Large" "got $code - set Limits.MaxRequestBodySize = 1048576"

  grep -q 'Http1AndHttp2' "$APP_DIR/Program.cs" && record PASS "Program.cs sets Protocols = Http1AndHttp2 on endpoint defaults" || record WARN "Program.cs sets Protocols = Http1AndHttp2 on endpoint defaults" "ConfigureEndpointDefaults(listen => listen.Protocols = HttpProtocols.Http1AndHttp2)"

  PUB="$APP_DIR/publish"; sz=0; [ -f "$PUB/OrderService" ] && sz="$(stat -c %s "$PUB/OrderService")"
  [ "$sz" -gt 20971520 ] && record PASS "publish/OrderService exists and is large enough to be self-contained (> 20 MB)" || record FAIL "publish/OrderService exists and is large enough to be self-contained (> 20 MB)" "size: $((sz/1048576)) MB"
  [ -f "$PUB/OrderService" ] && [ ! -f "$PUB/OrderService.dll" ] && record PASS "It is a single-file build (no separate OrderService.dll next to it)" || record FAIL "It is a single-file build (no separate OrderService.dll next to it)"

  grep -q 'IDiscountRule' "$EVID/dev-validation.txt" 2>/dev/null && grep -qE 'Error while validating|not able to be constructed' "$EVID/dev-validation.txt" && record PASS "Evidence: dev-validation.txt shows the startup validation error for IDiscountRule" || record FAIL "Evidence: dev-validation.txt shows the startup validation error for IDiscountRule"
  grep -q 'IDiscountRule' "$EVID/program.diff" 2>/dev/null && record PASS "Evidence: program.diff is present and shows the registration" || record FAIL "Evidence: program.diff is present and shows the registration"
  grep -q '200' "$EVID/requests.txt" 2>/dev/null && grep -q '413' "$EVID/requests.txt" && record PASS "Evidence: requests.txt shows 200 and 413" || record FAIL "Evidence: requests.txt shows 200 and 413"
  [ -s "$EVID/publish-listing.txt" ] && record PASS "Evidence: publish-listing.txt present" || record FAIL "Evidence: publish-listing.txt present"

  finish_checks "NET-D2-202"
}

case "${1:-help}" in
  start) do_start ;;
  restart) do_restart ;;
  check) do_check ;;
  reset) do_reset ;;
  *) echo "Usage: ./lab.sh start | restart | check | reset" ;;
esac
