#!/usr/bin/env bash
# =============================================================================
# lab.sh - NET-D1-101 harness - "Orders API Ignores Its New Port and Won't Start" (Ubuntu)
#   ./lab.sh start   inject the fault (legacy daemon on 5055 + hidden machine-wide override)
#   ./lab.sh check   validate your fix and your evidence
#   ./lab.sh reset   restore the pristine baseline
# This file is the harness - the exercise is to find the cause with the tools in the guide.
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$LAB_DIR/../common/lab-common.sh"

APP_DIR="$LAB_DIR/OrdersApi"
DAEMON="$LAB_DIR/legacy-sync-daemon.py"
STATE_F="$STATE_DIR/D1-1.json"
VAR_NAME="Kestrel__Endpoints__Http__Url"
BAD_VALUE="http://localhost:5055"
EVIDENCE="$LAB_DIR/evidence/evidence_D1_1.json"
UNIT="legacy-sync-daemon"

daemon_up() { [ -n "$(listener_pid 5055)" ]; }

do_reset() {
  require_sudo; ensure_dirs
  $SUDO systemctl stop "$UNIT" 2>/dev/null || true
  $SUDO systemctl reset-failed "$UNIT" 2>/dev/null || true
  $SUDO sed -i "/^# lab D1-1/d;/^${VAR_NAME}=/d" /etc/environment 2>/dev/null || true
  pkill -f "OrdersApi" 2>/dev/null || true
  rm -f "$STATE_F"
  [ "${1:-}" = "quiet" ] || { echo "${C_GREEN}D1-1 reset complete.${C_OFF} (Open shells keep stale env vars: run  unset $VAR_NAME  or open a new shell.)"; }
}

do_start() {
  require_sudo; ensure_dirs
  step "Preparing NET-D1-101 ..."
  do_reset quiet
  command -v dotnet >/dev/null || die "dotnet not found - run the setup script first"
  command -v python3 >/dev/null || die "python3 not found"

  # 1. the legacy integration daemon that owns port 5055 (a transient systemd unit)
  $SUDO systemd-run --quiet --unit="$UNIT" --description="Legacy integration sync daemon" python3 "$DAEMON" 5055
  wait_until 15 daemon_up || die "legacy daemon failed to start"
  DPID="$(listener_pid 5055)"

  # 2. the "hidden" machine-wide override left behind by an earlier project
  echo "# lab D1-1" | $SUDO tee -a /etc/environment >/dev/null
  echo "${VAR_NAME}=${BAD_VALUE}" | $SUDO tee -a /etc/environment >/dev/null

  # 3. build once so `dotnet run --no-build` is quick
  step "Building OrdersApi ..."
  ( cd "$APP_DIR" && dotnet build -c Debug --nologo -v q >/dev/null ) || die "dotnet build failed"

  printf '{"daemonPid": %s, "startedUtc": "%s"}\n' "$DPID" "$(date -u +%FT%TZ)" > "$STATE_F"

  echo
  echo "${C_YELLOW}TICKET NET-D1-101  [P2: app is completely down]${C_OFF}"
  echo "  The Orders API was reconfigured to listen on http://localhost:5060 (appsettings.json)"
  echo "  but on deployment it crashes: 'Failed to bind ... address already in use'."
  echo "  A legacy daemon on port 5055 must NOT be disturbed."
  echo
  echo "${C_CYAN}NEXT:${C_OFF}"
  echo "  1. Re-read the machine-wide environment in THIS shell (a shell that was already open does not see it):"
  echo "       set -a; . /etc/environment; set +a"
  echo "  2. cd $APP_DIR && dotnet run --no-build"
  echo "  3. Follow 02_Participant_Guide.md, section D1-1."
}

do_check() {
  [ -f "$STATE_F" ] || { echo "${C_YELLOW}Lab not started. Run: ./lab.sh start${C_OFF}"; exit 3; }
  DPID_EXPECT="$(json_get "$STATE_F" "d['daemonPid']")"

  d="$(listener_pid 5055)"
  [ "$d" = "$DPID_EXPECT" ] && record PASS "Legacy daemon still serves port 5055 with the SAME PID (it was not killed)" \
    || record FAIL "Legacy daemon still serves port 5055 with the SAME PID (it was not killed)" "expected PID $DPID_EXPECT, found '${d:-none}'"

  o="$(listener_pid 5060)"
  if [ -n "$o" ]; then record PASS "OrdersApi is listening on port 5060"; else record FAIL "OrdersApi is listening on port 5060" "Start the API (dotnet run --no-build) and leave it running in another terminal while you run check."; fi
  if [ -n "$o" ]; then
    pname="$(ps -o comm= -p "$o" 2>/dev/null)"
    case "$pname" in OrdersApi*|dotnet*) record PASS "The listener on 5060 is OrdersApi (not something else)";; *) record FAIL "The listener on 5060 is OrdersApi (not something else)" "listener is '$pname'";; esac
  fi
  code="$(http_status http://localhost:5060/health)"
  [ "$code" = "200" ] && record PASS "GET /health on 5060 returns 200" || record FAIL "GET /health on 5060 returns 200" "got HTTP ${code:-000}"
  http_body http://localhost:5060/health | grep -q Healthy && record PASS "/health body reports Healthy" || record FAIL "/health body reports Healthy"

  if grep -q "^${VAR_NAME}=" /etc/environment 2>/dev/null; then
    record WARN "Machine-wide override removed (permanent fix)" "$VAR_NAME is still defined in /etc/environment. A launch-time override works today but breaks the next deploy."
  else record PASS "Machine-wide override removed (permanent fix)"; fi

  if [ -f "$EVIDENCE" ] && python3 - "$EVIDENCE" <<'PY'
import json,sys,re
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
if miss: print('incomplete: '+', '.join(miss), file=sys.stderr); sys.exit(1)
PY
  then record PASS "evidence_D1_1.json is complete"
  else record FAIL "evidence_D1_1.json is complete" "fill every field in $EVIDENCE (valid JSON, deploymentModel exactly framework-dependent|self-contained)"; fi

  finish_checks "NET-D1-101"
}

case "${1:-help}" in
  start) do_start ;;
  check) do_check ;;
  reset) do_reset ;;
  *) echo "Usage: ./lab.sh start | check | reset" ;;
esac
