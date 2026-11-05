#!/usr/bin/env bash
# =============================================================================
# lab.sh - NET-D1-103 harness - "Staging Invoice-Sync Service Runs as 'Production' and Stops" (Ubuntu / systemd)
#   ./lab.sh start | check | reset
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$LAB_DIR/../common/lab-common.sh"

SRC="$LAB_DIR/InvoiceSync"
SVC_DIR="$LAB_DIR/service"
LOG_DIR="$LAB_DIR/Logs"
LOG_FILE="$LOG_DIR/invoice_sync.log"
UNIT="invoicesync"
UNIT_F="/etc/systemd/system/${UNIT}.service"
EVID="$LAB_DIR/evidence/evidence_D1_3.md"
STATE_F="$STATE_DIR/D1-3.json"

do_reset() {
  require_sudo; ensure_dirs
  $SUDO systemctl stop "$UNIT" 2>/dev/null || true
  $SUDO rm -rf "$UNIT_F" "${UNIT_F}.d" "$SVC_DIR" "$LOG_DIR"
  $SUDO systemctl daemon-reload
  $SUDO systemctl reset-failed "$UNIT" 2>/dev/null || true
  rm -f "$STATE_F"
  [ "${1:-}" = "quiet" ] || echo "${C_GREEN}D1-3 reset complete (unit, binaries and logs removed).${C_OFF}"
}

do_start() {
  require_sudo; ensure_dirs
  step "Preparing NET-D1-103 ..."
  do_reset quiet
  command -v dotnet >/dev/null || die "dotnet not found - run the setup script first"

  step "Publishing InvoiceSync ..."
  dotnet publish "$SRC" -c Release -o "$SVC_DIR" --nologo -v q >/dev/null || die "dotnet publish failed"
  id invoicesync >/dev/null 2>&1 || $SUDO useradd --system --no-create-home --shell /usr/sbin/nologin invoicesync
  mkdir -p "$LOG_DIR"
  $SUDO chown -R root:root "$SVC_DIR"; $SUDO chmod -R a+rX "$SVC_DIR"
  $SUDO chown invoicesync:invoicesync "$LOG_DIR"; $SUDO chmod 775 "$LOG_DIR"

  # the deployment script's mistake: it set the ASP.NET Core variable name on a worker service
  $SUDO tee "$UNIT_F" >/dev/null <<EOF
[Unit]
Description=Invoice Sync Service (Staging)
After=network.target

[Service]
Type=simple
User=invoicesync
WorkingDirectory=$SVC_DIR
ExecStart=/usr/bin/dotnet $SVC_DIR/InvoiceSync.dll
Environment=ASPNETCORE_ENVIRONMENT=Staging
Restart=no
SyslogIdentifier=invoicesync

[Install]
WantedBy=multi-user.target
EOF
  $SUDO systemctl daemon-reload
  printf '{"startedUtc": "%s"}\n' "$(date -u +%FT%TZ)" > "$STATE_F"
  step "Starting the service (this is expected to fail) ..."
  $SUDO systemctl start "$UNIT" 2>/dev/null || info "systemctl start reported a failure - as expected"
  sleep 3

  echo
  echo "${C_YELLOW}TICKET NET-D1-103  [P3: before go-live, no live impact]${C_OFF}"
  echo "  The deployment script set ASPNETCORE_ENVIRONMENT=Staging on the invoicesync unit."
  echo "  The service still stops within seconds of starting."
  echo
  echo "${C_CYAN}NEXT:${C_OFF} systemctl status invoicesync   then follow 02_Participant_Guide.md section D1-3."
}

do_check() {
  [ -f "$STATE_F" ] || { echo "${C_YELLOW}Lab not started. Run: ./lab.sh start${C_OFF}"; exit 3; }

  chk "Service invoicesync is active (running)" "systemctl status invoicesync" systemctl is-active --quiet "$UNIT"
  sleep 4
  chk "It is still running 4 seconds later (not crash-looping)" "systemctl status invoicesync" systemctl is-active --quiet "$UNIT"

  envs="$(systemctl show "$UNIT" -p Environment --value 2>/dev/null)"
  case "$envs" in *DOTNET_ENVIRONMENT=Staging*) record PASS "Unit environment contains DOTNET_ENVIRONMENT=Staging";; *) record FAIL "Unit environment contains DOTNET_ENVIRONMENT=Staging" "Environment is: $envs";; esac

  last=""; fresh=1
  if [ -f "$LOG_FILE" ]; then
    last="$(tail -n 1 "$LOG_FILE")"
    age=$(( $(date +%s) - $(stat -c %Y "$LOG_FILE") ))
    case "$last" in *"Environment: Staging"*) [ "$age" -lt 120 ] && fresh=0;; esac
  fi
  [ "$fresh" -eq 0 ] && record PASS 'invoice_sync.log shows a recent "Environment: Staging" heartbeat' || record FAIL 'invoice_sync.log shows a recent "Environment: Staging" heartbeat' "last log line: $last"

  if $SUDO journalctl -u "$UNIT" --no-pager 2>/dev/null | grep -q OptionsValidationException; then
    record PASS "Journal still holds the original OptionsValidationException (you can quote it)"
  else record WARN "Journal still holds the original OptionsValidationException (you can quote it)" "not found - copy it from your notes"; fi

  filled "$EVID" && record PASS "evidence_D1_3.md completed (no <<FILL left)" || record FAIL "evidence_D1_3.md completed (no <<FILL left)"

  finish_checks "NET-D1-103"
}

case "${1:-help}" in
  start) do_start ;;
  check) do_check ;;
  reset) do_reset ;;
  *) echo "Usage: ./lab.sh start | check | reset" ;;
esac
