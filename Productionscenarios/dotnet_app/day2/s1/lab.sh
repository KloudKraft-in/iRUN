#!/usr/bin/env bash
# =============================================================================
# lab.sh - NET-D2-201 harness - "Website Returns 503 After a Password Rotation" (Ubuntu / systemd)
# Ubuntu analogue: a systemd service that runs as a custom account; the identity team's rotation job
# DELETED and rebuilt that account. Fix with a dynamic (virtual) identity + group permissions.
#   ./lab.sh start | check | reset
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$LAB_DIR/../common/lab-common.sh"

SRC="$LAB_DIR/RetailPortal"
BASE="/opt/retailportal"
APP="$BASE/app"
UNIT="retailportal"
UNIT_F="/etc/systemd/system/${UNIT}.service"
EVID="$LAB_DIR/evidence"
STATE_F="$STATE_DIR/D2-1.json"

site_up() { [ "$(http_status http://localhost:8080/)" = "200" ]; }

do_reset() {
  require_sudo; ensure_dirs
  $SUDO systemctl stop "$UNIT" 2>/dev/null || true
  $SUDO rm -rf "$UNIT_F" "${UNIT_F}.d" "$BASE"
  $SUDO systemctl daemon-reload
  $SUDO systemctl reset-failed "$UNIT" 2>/dev/null || true
  id appsvc >/dev/null 2>&1 && $SUDO userdel appsvc 2>/dev/null || true
  getent group appsvc >/dev/null && $SUDO groupdel appsvc 2>/dev/null || true
  getent group retailportal-app >/dev/null && $SUDO groupdel retailportal-app 2>/dev/null || true
  rm -f "$STATE_F"
  [ "${1:-}" = "quiet" ] || echo "${C_GREEN}D2-1 reset complete (unit, files, appsvc account and group removed).${C_OFF}"
}

do_start() {
  require_sudo; ensure_dirs
  step "Preparing NET-D2-201 ..."
  do_reset quiet
  command -v dotnet >/dev/null || die "dotnet not found - run the setup script first"
  command -v openssl >/dev/null || die "openssl not found - run the setup script first"

  step "Creating service account 'appsvc' and publishing the site ..."
  $SUDO useradd --system --user-group --no-create-home --shell /usr/sbin/nologin appsvc
  $SUDO mkdir -p "$APP/certs"
  $SUDO chown -R "$(id -un)" "$BASE"
  dotnet publish "$SRC" -c Release -o "$APP" --nologo -v q >/dev/null || die "dotnet publish failed"
  openssl req -x509 -newkey rsa:2048 -nodes -keyout "$APP/certs/portal.key" -out "$APP/certs/portal.pem" -days 365 -subj "/CN=localhost" >/dev/null 2>&1
  # hardened tree: owned by appsvc, nobody else may read (like the locked-down NTFS folder on Windows)
  $SUDO chown -R appsvc:appsvc "$BASE"
  $SUDO find "$BASE" -type d -exec chmod 750 {} \;
  $SUDO find "$BASE" -type f -exec chmod 640 {} \;

  $SUDO tee "$UNIT_F" >/dev/null <<'EOF'
[Unit]
Description=Retail Portal (Kestrel)
After=network.target

[Service]
WorkingDirectory=/opt/retailportal/app
ExecStart=/usr/bin/dotnet /opt/retailportal/app/RetailPortal.dll
User=appsvc
Group=appsvc
Restart=on-failure
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF
  $SUDO systemctl daemon-reload
  $SUDO systemctl start "$UNIT"

  step "Baseline check: the site must work BEFORE the rotation ..."
  wait_until 40 site_up || die "baseline site did not come up (journalctl -u $UNIT)"
  info "HTTP 8080 = 200 (healthy baseline)"

  step "Identity & Security Ops 'rotate' the service account: the account is deleted and rebuilt later (the unit is NOT told) ..."
  $SUDO systemctl stop "$UNIT"
  $SUDO userdel appsvc 2>/dev/null || true
  $SUDO systemctl start "$UNIT" 2>/dev/null || true    # fails: 217/USER
  sleep 8                                               # let Restart=on-failure burn through its start limit

  printf '{"startedUtc": "%s"}\n' "$(date -u +%FT%TZ)" > "$STATE_F"
  echo
  echo "${C_YELLOW}TICKET NET-D2-201  [P2: site is completely down]${C_OFF}"
  echo "  After the scheduled enterprise account rotation the Retail website is unreachable."
  echo "  (On Windows this surfaces as HTTP 503; on Ubuntu there is no WAS to answer, so you see 'connection refused'.)"
  echo "  Starting the service by hand does not help."
  echo
  echo "${C_CYAN}NEXT:${C_OFF} curl -i http://localhost:8080/   then follow 02_Participant_Guide.md section D2-1."
}

do_check() {
  [ -f "$STATE_F" ] || { echo "${C_YELLOW}Lab not started. Run: ./lab.sh start${C_OFF}"; exit 3; }
  CFG="$(systemctl cat "$UNIT" 2>/dev/null)"

  c1="$(http_status http://localhost:8080/)"; c2="$(http_status https://localhost:8443/ -k)"
  [ "$c1" = "200" ] && record PASS "HTTP  http://localhost:8080/  returns 200" || record FAIL "HTTP  http://localhost:8080/  returns 200" "got ${c1:-000}"
  [ "$c2" = "200" ] && record PASS "HTTPS https://localhost:8443/ returns 200" || record FAIL "HTTPS https://localhost:8443/ returns 200" "got ${c2:-000}"

  chk "Service retailportal is active (running)" "systemctl status retailportal" systemctl is-active --quiet "$UNIT"
  echo "$CFG" | grep -qE '^DynamicUser=(yes|true|1)' && record PASS "Unit uses DynamicUser=yes (virtual identity)" || record FAIL "Unit uses DynamicUser=yes (virtual identity)" "add DynamicUser=yes"
  echo "$CFG" | grep -qE '^(User|Group)=appsvc' && record FAIL "Old User=/Group= appsvc lines removed" "remove User=appsvc and Group=appsvc" || record PASS "Old User=/Group= appsvc lines removed"
  echo "$CFG" | grep -qE '^SupplementaryGroups=.*retailportal-app' && record PASS "Unit grants the app group (SupplementaryGroups=retailportal-app)" || record FAIL "Unit grants the app group (SupplementaryGroups=retailportal-app)"
  perms="$($SUDO stat -c '%G %A' "$APP/RetailPortal.dll" 2>/dev/null)"
  case "$perms" in "retailportal-app -rw-r"*) record PASS "App files are group-readable by retailportal-app" ;; *) record FAIL "App files are group-readable by retailportal-app" "RetailPortal.dll is: $perms" ;; esac

  echo "$CFG" | grep -qE '^RuntimeMaxSec=(86400|1d|24h)' && record PASS "Recycle analogue: RuntimeMaxSec=86400 (24 h)" || record FAIL "Recycle analogue: RuntimeMaxSec=86400 (24 h)" "add RuntimeMaxSec=86400"
  if echo "$CFG" | grep -qE '^StartLimitBurst=5' && echo "$CFG" | grep -qE '^StartLimitIntervalSec=(300|5min|5m)'; then record PASS "Rapid-fail analogue: StartLimitBurst=5 / StartLimitIntervalSec=300"; else record FAIL "Rapid-fail analogue: StartLimitBurst=5 / StartLimitIntervalSec=300" "these two belong in the [Unit] section"; fi
  echo "$CFG" | grep -qE '^MemoryMax=' && record PASS "Memory limit analogue: MemoryMax set (hardening, optional)" || record WARN "Memory limit analogue: MemoryMax set (hardening, optional)" "e.g. MemoryMax=1G"

  who="$(http_body http://localhost:8080/whoami)"
  case "$who" in *'"user":"appsvc"'*) record FAIL "Process no longer runs as the deleted 'appsvc'" "$who" ;; *'"user":'*) record PASS "Process runs as a dynamic user ($who)" ;; *) record FAIL "Process identity readable via /whoami" "$who" ;; esac

  grep -q '217' "$EVID/was-events.txt" 2>/dev/null && record PASS "Evidence: was-events.txt shows the 217/USER failure" || record FAIL "Evidence: was-events.txt shows the 217/USER failure" "journalctl -u retailportal --no-pager > $EVID/was-events.txt  (capture it BEFORE you fix)"
  grep -q 'retailportal-app' "$EVID/acl.txt" 2>/dev/null && record PASS "Evidence: acl.txt shows the retailportal-app group" || record FAIL "Evidence: acl.txt shows the retailportal-app group" "ls -l $APP > $EVID/acl.txt ; systemctl cat retailportal >> $EVID/acl.txt"
  if grep -q 'active (running)' "$EVID/pool-state.txt" 2>/dev/null && grep -q '200' "$EVID/pool-state.txt"; then record PASS "Evidence: pool-state.txt shows active (running) and 200"; else record FAIL "Evidence: pool-state.txt shows active (running) and 200"; fi

  finish_checks "NET-D2-201"
}

case "${1:-help}" in
  start) do_start ;;
  check) do_check ;;
  reset) do_reset ;;
  *) echo "Usage: ./lab.sh start | check | reset" ;;
esac
