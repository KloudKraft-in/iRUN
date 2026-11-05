#!/usr/bin/env bash
# =============================================================================
# lab.sh - NET-D2-203 harness - "Intermittent Timeouts Under Load: Connection Pool Exhausted" (Ubuntu, SQL Server on Linux)
#   ./lab.sh start     restore the starting code, (re)create + seed RetailPerformanceDb, run PaymentApi on :5100
#   ./lab.sh restart   stop, rebuild YOUR changes, run again (use after every code edit)
#   ./lab.sh check     validate your fix and your evidence
#   ./lab.sh reset     stop the app, restore starting code, re-seed the database, delete dumps
# PaymentApi runs as a plain Kestrel process under YOUR account. No sudo needed.
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$LAB_DIR/../common/lab-common.sh"

APP_DIR="$LAB_DIR/PaymentApi"
BASE_DIR="$LAB_DIR/_baseline"
LOG_DIR="$LAB_DIR/logs"
DUMP_DIR="$LAB_DIR/Dumps"
EXE="$APP_DIR/bin/Debug/net10.0/PaymentApi"
EVID="$LAB_DIR/evidence"
URL="http://localhost:5100"
mkdir -p "$STATE_DIR" 2>/dev/null || $SUDO mkdir -p "$STATE_DIR"
STATE_F="$STATE_DIR/D2-3.json"

[ -n "${SQL_SA_PASSWORD:-}" ] || die "SQL_SA_PASSWORD not found in $LABS_ROOT/common/lab.env - run setup-ubuntu.sh (Day 2) first"
export ConnectionStrings__RetailPerformanceDb="Server=localhost,1433;Database=RetailPerformanceDb;User Id=sa;Password=${SQL_SA_PASSWORD};TrustServerCertificate=True;Max Pool Size=100;Connect Timeout=3"

health_up() { [ "$(http_status "$URL/health")" = "200" ]; }
stop_app() { pkill -x PaymentApi 2>/dev/null || true; sleep 0.8; }
restore_baseline() { cp -a "$BASE_DIR/." "$APP_DIR/"; }
build_app() {
  step "dotnet build ..."
  if ! out="$(dotnet build "$APP_DIR" -c Debug --nologo -v q 2>&1)"; then echo "$out"; echo "${C_RED}BUILD FAILED - fix the compile error and run: ./lab.sh restart${C_OFF}"; exit 2; fi
}
init_db() {
  step "Making sure SQL Server is up and (re)creating RetailPerformanceDb ..."
  $SUDO systemctl is-active --quiet mssql-server || $SUDO systemctl start mssql-server
  ( cd "$APP_DIR" && "$EXE" --init-db ) || die "database initialisation failed (is mssql-server running? journalctl -u mssql-server)"
}
start_app() {
  mkdir -p "$LOG_DIR" "$DUMP_DIR"
  ( cd "$APP_DIR" && DOTNET_ENVIRONMENT=Production ASPNETCORE_ENVIRONMENT=Production ASPNETCORE_URLS="$URL" \
      nohup "$EXE" >"$LOG_DIR/app.out.log" 2>"$LOG_DIR/app.err.log" & echo $! > "$STATE_DIR/D2-3.pid" )
  printf '{"pid": %s, "startedUtc": "%s"}\n' "$(cat "$STATE_DIR/D2-3.pid")" "$(date -u +%FT%TZ)" > "$STATE_F"
  wait_until 40 health_up || { echo "${C_RED}PaymentApi did not answer on $URL - see $LOG_DIR/app.out.log${C_OFF}"; exit 2; }
}

do_start() {
  step "Preparing NET-D2-203 ..."
  command -v dotnet >/dev/null || die "dotnet not found - run the setup script first"
  stop_app; restore_baseline; build_app; init_db; start_app
  echo
  echo "${C_YELLOW}TICKET NET-D2-203  [P2: errors come and go under peak load]${C_OFF}"
  echo "  At midday peaks, checkout intermittently fails: 'Timeout expired ... all pooled connections were in use and max pool size was reached'."
  echo "  CPU and memory look normal, but latency and thread count spike. Pool: Max Pool Size=100."
  echo "  PaymentApi PID: $(pgrep -x PaymentApi | head -1)   URL: $URL   Logs: $LOG_DIR"
  echo
  echo "${C_CYAN}NEXT:${C_OFF} open a 2nd and 3rd terminal; follow 02_Participant_Guide.md section D2-3."
}
do_restart() { step "Restarting PaymentApi with your latest code ..."; stop_app; build_app; start_app; echo "${C_GREEN}Running again on $URL with a fresh, empty connection pool.${C_OFF}"; }
do_reset() {
  stop_app; restore_baseline
  rm -rf "$DUMP_DIR" "$LOG_DIR"
  ( build_app && init_db ) || echo "${C_YELLOW}Could not re-seed the database (run start to rebuild it).${C_OFF}"
  rm -f "$STATE_F" "$STATE_DIR/D2-3.pid"
  echo "${C_GREEN}D2-3 reset complete (app stopped, code restored, database re-seeded, dumps deleted).${C_OFF}"
}

do_check() {
  [ -f "$STATE_F" ] || { echo "${C_YELLOW}Lab not started. Run: ./lab.sh start${C_OFF}"; exit 3; }

  health_up && record PASS "PaymentApi answers on /health" || record FAIL "PaymentApi answers on /health" "start it with ./lab.sh restart"

  info "Running a 150-request / 25-worker probe (a leaking build fails this) ..."
  probe="$("$LAB_DIR/load-test.sh" -r 150 -c 25 -j 2>/dev/null | tail -1)"
  failed="$(echo "$probe" | sed -n 's/.*"failed":\([0-9]*\).*/\1/p')"; failed="${failed:--1}"
  [ "$failed" = "0" ] && record PASS "Probe load: 150 requests, 0 failures (no connection leak)" || record FAIL "Probe load: 150 requests, 0 failures (no connection leak)" "failed: $failed - did you run ./lab.sh restart after the fix?"

  body="$(curl -s --max-time 90 "$URL/api/orders/summary")"
  qc="$(echo "$body" | sed -n 's/.*"queryCount":\([0-9]*\).*/\1/p')"; qc="${qc:--1}"
  if [ "$qc" -ge 1 ] && [ "$qc" -le 3 ]; then record PASS "EF Core N+1 removed: /api/orders/summary runs <= 3 SQL queries"; else record FAIL "EF Core N+1 removed: /api/orders/summary runs <= 3 SQL queries" "queryCount = $qc (the starting code runs about 401)"; fi

  grep -Eq 'using\s+var\s+\w+\s*=\s*new\s+SqlConnection|await\s+using' "$APP_DIR/Services/DapperPaymentRepository.cs" && record PASS "DapperPaymentRepository disposes its SqlConnection (using)" || record FAIL "DapperPaymentRepository disposes its SqlConnection (using)" "wrap the connection in a using statement"

  for f in load-test-before.txt counters-before.csv counters-after.csv dapper.diff orderquery.diff load-test-after.txt; do
    [ -s "$EVID/$f" ] && [ "$(wc -c < "$EVID/$f")" -gt 20 ] && record PASS "Evidence: $f present and non-empty" || record FAIL "Evidence: $f present and non-empty"
  done
  grep -Eq 'Failed:[[:space:]]*[1-9]' "$EVID/load-test-before.txt" 2>/dev/null && record PASS "Evidence: load-test-before.txt really shows failures (the leak)" || record FAIL "Evidence: load-test-before.txt really shows failures (the leak)"
  grep -Eq 'Failed:[[:space:]]*0([^0-9]|$)' "$EVID/load-test-after.txt" 2>/dev/null && record PASS 'Evidence: load-test-after.txt shows "Failed: 0"' || record FAIL 'Evidence: load-test-after.txt shows "Failed: 0"'
  ls "$DUMP_DIR"/*.dmp >/dev/null 2>&1 && record PASS "A process dump was captured with dotnet-dump (Dumps/*.dmp)" || record WARN "A process dump was captured with dotnet-dump (Dumps/*.dmp)" "dotnet-dump collect -n PaymentApi -o ./Dumps/leak.dmp"

  finish_checks "NET-D2-203"
}

case "${1:-help}" in
  start) do_start ;;
  restart) do_restart ;;
  check) do_check ;;
  reset) do_reset ;;
  *) echo "Usage: ./lab.sh start | restart | check | reset" ;;
esac
