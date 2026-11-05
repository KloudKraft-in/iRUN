#!/usr/bin/env bash
# =============================================================================
# Validation & Harness Script for NET-D1-103 (Ubuntu / Linux)
#   ./validation_script.sh          validate solution
#   ./validation_script.sh start    initialize incident
#   ./validation_script.sh check    validate solution
#   ./validation_script.sh reset    restore pristine baseline
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STARTER_DIR="$LAB_DIR/starter"
SRC="$STARTER_DIR/InvoiceSync"
SVC_DIR="$STARTER_DIR/service"
LOG_DIR="$STARTER_DIR/Logs"
LOG_FILE="$LOG_DIR/invoice_sync.log"
UNIT="invoicesync.service"
UNIT_FILE="/etc/systemd/system/$UNIT"
STATE_DIR="${TMPDIR:-/tmp}/lab-state"
STATE_F="$STATE_DIR/D1-3.json"
EVID="$STARTER_DIR/evidence/evidence_D1_3.md"

C_GREEN=$(printf '\033[32m')
C_RED=$(printf '\033[31m')
C_YELLOW=$(printf '\033[33m')
C_CYAN=$(printf '\033[36m')
C_OFF=$(printf '\033[0m')

SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

ensure_dirs() { mkdir -p "$STATE_DIR"; }
step() { echo "${C_CYAN}[STEP] $*${C_OFF}"; }

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
  rm -rf "$SVC_DIR" "$LOG_DIR" "$STATE_F"
  [ "${1:-}" = "quiet" ] || echo "${C_GREEN}D1-3 reset complete (service, binaries and logs removed).${C_OFF}"
}

do_start() {
  ensure_dirs
  step "Preparing NET-D1-103 ..."
  do_reset quiet
  command -v dotnet >/dev/null || { echo "dotnet not found - install .NET SDK first"; exit 2; }

  step "Publishing InvoiceSync ..."
  mkdir -p "$SVC_DIR" "$LOG_DIR"
  dotnet publish "$SRC" -c Release -o "$SVC_DIR" --nologo -v q >/dev/null || { echo "dotnet publish failed"; exit 2; }

  $SUDO bash -c "cat > '$UNIT_FILE'" <<EOF
[Unit]
Description=Invoice Sync Service (Staging)
After=network.target

[Service]
Type=notify
WorkingDirectory=$SVC_DIR
ExecStart=$SVC_DIR/InvoiceSync
Restart=on-failure
RestartSec=5
SyslogIdentifier=invoicesync
Environment=ASPNETCORE_ENVIRONMENT=Staging

[Install]
WantedBy=multi-user.target
EOF

  $SUDO systemctl daemon-reload
  printf '{"startedUtc": "%s"}\n' "$(date -u +%FT%TZ)" > "$STATE_F"

  step "Starting service (expected to fail) ..."
  $SUDO systemctl start "$UNIT" 2>/dev/null || true
  sleep 3

  echo
  echo "${C_YELLOW}TICKET NET-D1-103  [P3: before go-live, no live impact]${C_OFF}"
  echo "  InvoiceSync stops immediately upon starting."
  echo
  echo "${C_CYAN}NEXT: sudo systemctl status $UNIT then follow Participant_Guide_day1.md Ticket 3.${C_OFF}"
}

do_check() {
  echo "==================================================="
  echo " Validating NET-D1-103: Staging Generic Host Config"
  echo "==================================================="

  if systemctl is-active --quiet "$UNIT" 2>/dev/null; then
    record PASS "Service $UNIT is active"
  else
    record FAIL "Service $UNIT is active" "systemctl is-active reports not active"
  fi

  if grep -q "DOTNET_ENVIRONMENT=Staging" "$UNIT_FILE" 2>/dev/null; then
    record PASS "Unit file defines DOTNET_ENVIRONMENT=Staging"
  else
    record FAIL "Unit file defines DOTNET_ENVIRONMENT=Staging" "missing from $UNIT_FILE"
  fi

  if [ -f "$EVID" ] && ! grep -q "<<FILL" "$EVID"; then
    record PASS "Evidence file is complete (no <<FILL left)"
  else
    record FAIL "Evidence file is complete (no <<FILL left)" "complete $EVID"
  fi

  finish_checks "NET-D1-103"
}

case "${1:-check}" in
  start) do_start ;;
  check) do_check ;;
  reset) do_reset ;;
  *) do_check ;;
esac

