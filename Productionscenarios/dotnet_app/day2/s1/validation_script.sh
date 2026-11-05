#!/usr/bin/env bash
# =============================================================================
# Validation & Harness Script for NET-D2-201 (Ubuntu / Linux)
#   ./validation_script.sh          validate solution
#   ./validation_script.sh start    initialize incident
#   ./validation_script.sh check    validate solution
#   ./validation_script.sh reset    restore pristine baseline
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STARTER_DIR="$LAB_DIR/starter"
SRC="$STARTER_DIR/RetailPortal"
DEPLOY_DIR="/opt/retailportal/app"
UNIT="retailportal.service"
UNIT_FILE="/etc/systemd/system/$UNIT"
SVC_USER="retailportal"
STATE_DIR="${TMPDIR:-/tmp}/lab-state"
STATE_F="$STATE_DIR/D2-1.json"
EVID="$STARTER_DIR/evidence"

C_GREEN=$(printf '\033[32m')
C_RED=$(printf '\033[31m')
C_YELLOW=$(printf '\033[33m')
C_CYAN=$(printf '\033[36m')
C_OFF=$(printf '\033[0m')

SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

ensure_dirs() { mkdir -p "$STATE_DIR"; }
step() { echo "${C_CYAN}[STEP] $*${C_OFF}"; }

http_status() { curl -k -s -o /dev/null -w "%{http_code}" --max-time "${2:-5}" "$1" 2>/dev/null || echo "000"; }
http_body() { curl -k -s --max-time "${2:-5}" "$1" 2>/dev/null || true; }

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
  ensure_dirs
  $SUDO systemctl stop "$UNIT" 2>/dev/null || true
  $SUDO systemctl disable "$UNIT" 2>/dev/null || true
  $SUDO rm -f "$UNIT_FILE"
  $SUDO systemctl daemon-reload 2>/dev/null || true
  $SUDO userdel "$SVC_USER" 2>/dev/null || true
  $SUDO rm -rf "$DEPLOY_DIR"
  rm -f "$STATE_F"
  [ "${1:-}" = "quiet" ] || echo "${C_GREEN}D2-1 reset complete (service, binaries, certs and user removed).${C_OFF}"
}

do_start() {
  ensure_dirs
  step "Preparing NET-D2-201 ..."
  do_reset quiet
  command -v dotnet >/dev/null || { echo "dotnet not found - install .NET SDK first"; exit 2; }

  step "Publishing RetailPortal ..."
  $SUDO mkdir -p "$DEPLOY_DIR"
  $SUDO dotnet publish "$SRC" -c Release -o "$DEPLOY_DIR" --nologo -v q >/dev/null || { echo "dotnet publish failed"; exit 2; }

  id "$SVC_USER" &>/dev/null || $SUDO useradd -r -s /usr/sbin/nologin "$SVC_USER" 2>/dev/null || true
  $SUDO chown -R "$SVC_USER:$SVC_USER" "$DEPLOY_DIR"

  $SUDO bash -c "cat > '$UNIT_FILE'" <<EOF
[Unit]
Description=Retail Portal Hardened Service
After=network.target

[Service]
WorkingDirectory=$DEPLOY_DIR
ExecStart=$DEPLOY_DIR/RetailPortal
Restart=on-failure
RestartSec=5
User=nonexistent_user
Environment=ASPNETCORE_ENVIRONMENT=Production

[Install]
WantedBy=multi-user.target
EOF

  $SUDO systemctl daemon-reload
  printf '{"startedUtc": "%s"}\n' "$(date -u +%FT%TZ)" > "$STATE_F"

  $SUDO systemctl start "$UNIT" 2>/dev/null || true
  sleep 2

  echo
  echo "${C_YELLOW}TICKET NET-D2-201  [P2: site is completely down]${C_OFF}"
  echo "  Service fails with 217/USER status."
  echo
  echo "${C_CYAN}NEXT: sudo systemctl status $UNIT then follow Participant_Guide_day2.md Ticket 1.${C_OFF}"
}

do_check() {
  echo "==================================================="
  echo " Validating NET-D2-201: IIS / Systemd Hardening    "
  echo "==================================================="

  if systemctl is-active --quiet "$UNIT" 2>/dev/null; then
    record PASS "Service $UNIT is active"
  else
    record FAIL "Service $UNIT is active" "systemctl is-active reports not active"
  fi

  c1="$(http_status http://127.0.0.1:8080/ 10)"
  [ "$c1" = "200" ] && record PASS "HTTP 8080 returns 200" || record FAIL "HTTP 8080 returns 200" "got $c1"

  [ -f "$EVID/was-events.txt" ] && record PASS "was-events.txt present in evidence" || record FAIL "was-events.txt present in evidence"

  finish_checks "NET-D2-201"
}

case "${1:-check}" in
  start) do_start ;;
  check) do_check ;;
  reset) do_reset ;;
  *) do_check ;;
esac

