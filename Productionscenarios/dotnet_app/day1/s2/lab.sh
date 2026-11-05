#!/usr/bin/env bash
# =============================================================================
# lab.sh - NET-D1-102 harness - "Site Shows 502 After Switching to a Reverse Proxy" (Ubuntu)
# Ubuntu analogue of IIS + ANCM Out-of-Process:  nginx (proxy)  ->  Kestrel (dotnet, run by systemd)
#   ./lab.sh start | check | reset
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
. "$LAB_DIR/../common/lab-common.sh"

SRC="$LAB_DIR/CustomerPortal"
SITE_DIR="/opt/customerportal"
LOG_DIR="/var/log/customerportal"
UNIT="customerportal"
UNIT_F="/etc/systemd/system/${UNIT}.service"
NGX_F="/etc/nginx/sites-available/customerportal"
NGX_L="/etc/nginx/sites-enabled/customerportal"
EVID="$LAB_DIR/evidence"
STATE_F="$STATE_DIR/D1-2.json"

do_reset() {
  require_sudo; ensure_dirs
  $SUDO systemctl stop "$UNIT" 2>/dev/null || true
  $SUDO rm -f "$UNIT_F" "$NGX_L" "$NGX_F"
  $SUDO rm -rf "$UNIT_F.d" "$SITE_DIR" "$LOG_DIR"
  $SUDO systemctl daemon-reload
  $SUDO systemctl reset-failed "$UNIT" 2>/dev/null || true
  command -v nginx >/dev/null && $SUDO nginx -t >/dev/null 2>&1 && $SUDO systemctl reload nginx 2>/dev/null || true
  pkill -f "CustomerPortal.dll" 2>/dev/null || true
  rm -f "$STATE_F"
  [ "${1:-}" = "quiet" ] || echo "${C_GREEN}D1-2 reset complete (unit, nginx site and files removed).${C_OFF}"
}

do_start() {
  require_sudo; ensure_dirs
  step "Preparing NET-D1-102 ..."
  do_reset quiet
  command -v dotnet >/dev/null || die "dotnet not found - run the setup script first"
  command -v nginx  >/dev/null || die "nginx not found - run the setup script first"

  step "Publishing CustomerPortal ..."
  $SUDO mkdir -p "$SITE_DIR" "$LOG_DIR"
  $SUDO chown "$(id -un)" "$SITE_DIR"
  dotnet publish "$SRC" -c Release -o "$SITE_DIR" --nologo -v q >/dev/null || die "dotnet publish failed"
  $SUDO chown -R root:root "$SITE_DIR"; $SUDO chmod -R a+rX "$SITE_DIR"
  $SUDO chown www-data:www-data "$LOG_DIR"           # the service user must be able to write its stdout log here

  # the regression: someone put a wrong DLL name into ExecStart, and stdout/stderr are discarded
  $SUDO tee "$UNIT_F" >/dev/null <<'EOF'
[Unit]
Description=Retail Customer Portal (Kestrel)
After=network.target

[Service]
WorkingDirectory=/opt/customerportal
ExecStart=/usr/bin/dotnet /opt/customerportal/CustomerPortalMisspelled.dll
Environment=ASPNETCORE_URLS=http://127.0.0.1:5000
Environment=DOTNET_ENVIRONMENT=Production
User=www-data
Restart=no
StandardOutput=null
StandardError=null
SyslogIdentifier=customerportal

[Install]
WantedBy=multi-user.target
EOF

  $SUDO tee "$NGX_F" >/dev/null <<'EOF'
server {
    listen 8080;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
  $SUDO ln -sf "$NGX_F" "$NGX_L"
  $SUDO nginx -t >/dev/null 2>&1 || die "nginx configuration test failed"
  $SUDO systemctl enable --now nginx >/dev/null 2>&1; $SUDO systemctl reload nginx
  $SUDO systemctl daemon-reload
  $SUDO systemctl start "$UNIT" 2>/dev/null || true      # fails on purpose

  printf '{"startedUtc": "%s"}\n' "$(date -u +%FT%TZ)" > "$STATE_F"
  curl -s -o /dev/null --max-time 10 http://localhost:8080/ || true   # prime one failing request (nginx error.log)

  echo
  echo "${C_YELLOW}TICKET NET-D1-102  [P2: customers see the outage]${C_OFF}"
  echo "  The portal was moved behind a reverse proxy (nginx -> Kestrel run by systemd)."
  echo "  Every request now returns '502 Bad Gateway'. Reloading nginx did not help."
  echo
  echo "${C_CYAN}NEXT:${C_OFF} curl -i http://localhost:8080/   then follow 02_Participant_Guide.md section D1-2."
}

do_check() {
  [ -f "$STATE_F" ] || { echo "${C_YELLOW}Lab not started. Run: ./lab.sh start${C_OFF}"; exit 3; }

  code="$(http_status http://localhost:8080/)"
  [ "$code" = "200" ] && record PASS "http://localhost:8080/ returns 200" || record FAIL "http://localhost:8080/ returns 200" "got HTTP ${code:-000}"

  chk "nginx is active" "systemctl status nginx" systemctl is-active --quiet nginx
  chk "customerportal.service is active (running)" "systemctl status customerportal" systemctl is-active --quiet "$UNIT"

  dllpath="$(systemctl cat "$UNIT" 2>/dev/null | grep -E '^ExecStart=' | tail -1 | sed -E 's/^ExecStart=//' | awk '{print $2}')"
  if [ -n "$dllpath" ] && [ -f "$dllpath" ]; then record PASS "ExecStart points at a DLL that exists"; else record FAIL "ExecStart points at a DLL that exists" "ExecStart DLL: '${dllpath:-?}'"; fi

  who="$(http_body http://localhost:8080/whoami)"
  echo "$who" | grep -q '"processName":"dotnet"' && record PASS "Requests are answered by the dotnet process behind nginx" || record FAIL "Requests are answered by the dotnet process behind nginx" "$who"

  [ -s "$EVID/eventlog-export.txt" ] && [ "$(wc -c < "$EVID/eventlog-export.txt")" -gt 50 ] && record PASS "Evidence: eventlog-export.txt present and non-empty" || record FAIL "Evidence: eventlog-export.txt present and non-empty" "save: journalctl -u customerportal --no-pager > $EVID/eventlog-export.txt (captured while it was failing)"
  [ -s "$EVID/customerportal.service" ] && record PASS "Evidence: corrected customerportal.service copy present" || record FAIL "Evidence: corrected customerportal.service copy present" "cp $UNIT_F $EVID/"
  filled "$EVID/process-comparison.md" && record PASS "Evidence: process-comparison.md completed (no <<FILL left)" || record FAIL "Evidence: process-comparison.md completed (no <<FILL left)"

  finish_checks "NET-D1-102"
}

case "${1:-help}" in
  start) do_start ;;
  check) do_check ;;
  reset) do_reset ;;
  *) echo "Usage: ./lab.sh start | check | reset" ;;
esac
