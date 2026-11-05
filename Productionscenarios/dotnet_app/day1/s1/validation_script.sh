#!/usr/bin/env bash
# =============================================================================
# Validation & Harness Script for NET-D1-101 (Ubuntu / Linux)
#   ./validation_script.sh          validate solution
#   ./validation_script.sh start    initialize incident
#   ./validation_script.sh check    validate solution
#   ./validation_script.sh reset    restore pristine baseline
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STARTER_DIR="$LAB_DIR/starter"
APP_DIR="$STARTER_DIR/OrdersApi"
DAEMON="$STARTER_DIR/legacy-sync-daemon.py"
STATE_DIR="${TMPDIR:-/tmp}/lab-state"
STATE_F="$STATE_DIR/D1-1.json"
VAR_NAME="Kestrel__Endpoints__Http__Url"
BAD_VALUE="http://localhost:5055"
EVIDENCE="$STARTER_DIR/evidence/evidence_D1_1.json"
UNIT="legacy-sync-daemon"

C_GREEN=$(printf '\033[32m')
C_RED=$(printf '\033[31m')
C_YELLOW=$(printf '\033[33m')
C_CYAN=$(printf '\033[36m')
C_OFF=$(printf '\033[0m')

SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

ensure_dirs() { mkdir -p "$STATE_DIR"; }

step() { echo "${C_CYAN}[STEP] $*${C_OFF}"; }

listener_pid() {
  local p="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltnp "sport = :$p" 2>/dev/null | grep -o 'pid=[0-9]*' | head -n1 | cut -d= -f2
  else
    lsof -ti ":$p" 2>/dev/null | head -n1
  fi
}

wait_until() {
  local sec="$1"; shift
  local end=$(( $(date +%s) + sec ))
  while [ $(date +%s) -lt $end ]; do
    if "$@"; then return 0; fi
    sleep 1
  done
  return 1
}

http_status() {
  curl -s -o /dev/null -w "%{http_code}" --max-time "${2:-5}" "$1" 2>/dev/null || echo "000"
}

http_body() {
  curl -s --max-time "${2:-5}" "$1" 2>/dev/null || true
}

daemon_up() { [ -n "$(listener_pid 5055)" ]; }

TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

record() {
  local status="$1"; local title="$2"; local details="${3:-}"
  TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
  case "$status" in
    PASS)
      PASSED_CHECKS=$((PASSED_CHECKS + 1))
      echo "  [${C_GREEN}PASS${C_OFF}] $title"
      ;;
    WARN)
      echo "  [${C_YELLOW}WARN${C_OFF}] $title"
      [ -n "$details" ] && echo "         $details"
      ;;
    FAIL)
      FAILED_CHECKS=$((FAILED_CHECKS + 1))
      echo "  [${C_RED}FAIL${C_OFF}] $title"
      [ -n "$details" ] && echo "         $details"
      ;;
  esac
}

finish_checks() {
  local name="$1"
  echo ""
  echo "==================================================="
  echo " Validation Results for $name: $PASSED_CHECKS/$TOTAL_CHECKS passed"
  echo "==================================================="
  if [ "$FAILED_CHECKS" -gt 0 ]; then
    echo "${C_RED} [FAIL] Some validation checks failed. Please review guidelines.${C_OFF}"
    exit 1
  else
    echo "${C_GREEN} [PASS] $name Validation Succeeded!${C_OFF}"
  fi
}

do_reset() {
  ensure_dirs
  $SUDO systemctl stop "$UNIT" 2>/dev/null || true
  $SUDO systemctl reset-failed "$UNIT" 2>/dev/null || true
  $SUDO sed -i "/^# lab D1-1/d;/^${VAR_NAME}=/d" /etc/environment 2>/dev/null || true
  pkill -f "OrdersApi" 2>/dev/null || true
  rm -f "$STATE_F"
  [ "${1:-}" = "quiet" ] || { echo "${C_GREEN}D1-1 reset complete.${C_OFF} (Open shells keep stale env vars: run  unset $VAR_NAME  or open a new shell.)"; }
}

do_start() {
  ensure_dirs
  step "Preparing NET-D1-101 ..."
  do_reset quiet
  command -v dotnet >/dev/null || { echo "dotnet not found - install .NET SDK first"; exit 2; }
  command -v python3 >/dev/null || { echo "python3 not found"; exit 2; }

  $SUDO systemd-run --quiet --unit="$UNIT" --description="Legacy integration sync daemon" python3 "$DAEMON" 5055
  wait_until 15 daemon_up || { echo "legacy daemon failed to start"; exit 2; }
  DPID="$(listener_pid 5055)"

  echo "# lab D1-1" | $SUDO tee -a /etc/environment >/dev/null
  echo "${VAR_NAME}=${BAD_VALUE}" | $SUDO tee -a /etc/environment >/dev/null

  step "Building OrdersApi ..."
  ( cd "$APP_DIR" && dotnet build -c Debug --nologo -v q >/dev/null ) || { echo "dotnet build failed"; exit 2; }

  printf '{"daemonPid": %s, "startedUtc": "%s"}\n' "$DPID" "$(date -u +%FT%TZ)" > "$STATE_F"

  echo
  echo "${C_YELLOW}TICKET NET-D1-101  [P2: app is completely down]${C_OFF}"
  echo "  The Orders API was reconfigured to listen on http://localhost:5060 (appsettings.json)"
  echo "  but on deployment it crashes: 'Failed to bind ... address already in use'."
  echo "  A legacy daemon on port 5055 must NOT be disturbed."
  echo
  echo "${C_CYAN}NEXT:${C_OFF}"
  echo "  1. Re-read the machine-wide environment: set -a; . /etc/environment; set +a"
  echo "  2. cd starter/OrdersApi && dotnet run --no-build"
  echo "  3. Follow Participant_Guide_day1.md Ticket 1."
}

do_check() {
  echo "==================================================="
  echo " Validating NET-D1-101: Orders API Port Conflict   "
  echo "==================================================="

  d="$(listener_pid 5055)"
  if [ -f "$STATE_F" ]; then
    DPID_EXPECT="$(grep -o '"daemonPid": [0-9]*' "$STATE_F" | cut -d: -f2 | tr -d ' ')"
    [ "$d" = "$DPID_EXPECT" ] && record PASS "Legacy daemon still serves port 5055 with the SAME PID (it was not killed)" \
      || record FAIL "Legacy daemon still serves port 5055 with the SAME PID (it was not killed)" "expected PID $DPID_EXPECT, found '${d:-none}'"
  else
    [ -n "$d" ] && record PASS "Legacy daemon still serves port 5055" || record FAIL "Legacy daemon still serves port 5055" "no listener on 5055"
  fi

  o="$(listener_pid 5060)"
  if [ -n "$o" ]; then record PASS "OrdersApi is listening on port 5060"; else record FAIL "OrdersApi is listening on port 5060" "Start the API (dotnet run --no-build) in another terminal."; fi
  if [ -n "$o" ]; then
    pname="$(ps -o comm= -p "$o" 2>/dev/null)"
    case "$pname" in OrdersApi*|dotnet*) record PASS "The listener on 5060 is OrdersApi (not something else)";; *) record FAIL "The listener on 5060 is OrdersApi (not something else)" "listener is '$pname'";; esac
  fi
  code="$(http_status http://localhost:5060/health)"
  [ "$code" = "200" ] && record PASS "GET /health on 5060 returns 200" || record FAIL "GET /health on 5060 returns 200" "got HTTP ${code:-000}"
  http_body http://localhost:5060/health | grep -q Healthy && record PASS "/health body reports Healthy" || record FAIL "/health body reports Healthy"

  if grep -q "^${VAR_NAME}=" /etc/environment 2>/dev/null; then
    record WARN "Machine-wide override removed (permanent fix)" "$VAR_NAME is still defined in /etc/environment."
  else record PASS "Machine-wide override removed (permanent fix)"; fi

  if [ -f "$EVIDENCE" ] && python3 - "$EVIDENCE" <<'PY'
import json,sys
j=json.load(open(sys.argv[1])); miss=[]
g=lambda *p: __import__('functools').reduce(lambda a,k:(a or {}).get(k) if isinstance(a,dict) else None,p,j)
s=g('startupLogLine') or ''
if 'Now listening on' not in s or '5060' not in s: miss.append('startupLogLine')
if g('healthResponse','statusCode')!=200: miss.append('healthResponse.statusCode')
for k in ('sdkVersion','runtimeVersion','frameworkDescription','os'):
    if not g('runtime',k): miss.append('runtime.'+k)
if g('runtime','deploymentModel') not in ('framework-dependent','self-contained'): miss.append('runtime.deploymentModel')
for k in ('name','scope','value'):
    if not g('overridingVariable',k): miss.append('overridingVariable.'+k)
if len(g('rootCause') or '')<20: miss.append('rootCause')
if not g('legacyDaemon','pid'): miss.append('legacyDaemon.pid')
if miss: sys.exit(1)
PY
  then record PASS "evidence_D1_1.json is complete"
  else record FAIL "evidence_D1_1.json is complete" "fill every field in starter/evidence/evidence_D1_1.json"; fi

  finish_checks "NET-D1-101"
}

case "${1:-check}" in
  start) do_start ;;
  check) do_check ;;
  reset) do_reset ;;
  *) do_check ;;
esac

