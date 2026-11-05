#!/usr/bin/env bash
# =============================================================================
# Validation & Harness Script for NET-D1-102 (Ubuntu / Linux)
#   ./validation_script.sh          validate solution
#   ./validation_script.sh start    initialize incident
#   ./validation_script.sh check    validate solution
#   ./validation_script.sh reset    restore pristine baseline
# =============================================================================
set -u
LAB_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
STARTER_DIR="$LAB_DIR/starter"
SRC="$STARTER_DIR/CustomerPortal"
DEPLOY_DIR="/var/www/customerportal"
UNIT="customerportal.service"
UNIT_FILE="/etc/systemd/system/$UNIT"
NGINX_CONF="/etc/nginx/sites-available/customerportal"
NGINX_LINK="/etc/nginx/sites-enabled/customerportal"
STATE_DIR="${TMPDIR:-/tmp}/lab-state"
STATE_F="$STATE_DIR/D1-2.json"
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

http_status() { curl -s -o /dev/null -w "%{http_code}" --max-time "${2:-5}" "$1" 2>/dev/null || echo "000"; }
http_body() { curl -s --max-time "${2:-5}" "$1" 2>/dev/null || true; }

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
  $SUDO rm -f "$UNIT_FILE" "$NGINX_CONF" "$NGINX_LINK"
  $SUDO systemctl daemon-reload 2>/dev/null || true
  $SUDO systemctl reload nginx 2>/dev/null || true
  $SUDO rm -rf "$DEPLOY_DIR"
  rm -f "$STATE_F"
  [ "${1:-}" = "quiet" ] || echo "${C_GREEN}D1-2 reset complete (systemd unit, nginx config and published files removed).${C_OFF}"
}

do_start() {
  ensure_dirs
  step "Preparing NET-D1-102 ..."
  do_reset quiet
  command -v dotnet >/dev/null || { echo "dotnet not found - install .NET SDK first"; exit 2; }
  command -v nginx >/dev/null || { echo "nginx not found - install nginx first"; exit 2; }

  step "Publishing CustomerPortal ..."
  $SUDO mkdir -p "$DEPLOY_DIR"
  $SUDO dotnet publish "$SRC" -c Release -o "$DEPLOY_DIR" --nologo -v q >/dev/null || { echo "dotnet publish failed"; exit 2; }
  $SUDO chown -R www-data:www-data "$DEPLOY_DIR"

  $SUDO bash -c "cat > '$UNIT_FILE'" <<EOF
[Unit]
Description=Retail Customer Portal (.NET)
After=network.target

[Service]
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/dotnet $DEPLOY_DIR/CustomerPortalMisspelled.dll
Restart=always
RestartSec=3
KillSignal=SIGINT
SyslogIdentifier=customerportal
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=ASPNETCORE_URLS=http://127.0.0.1:5001

[Install]
WantedBy=multi-user.target
EOF

  $SUDO systemctl daemon-reload
  $SUDO systemctl start "$UNIT" 2>/dev/null || true

  $SUDO bash -c "cat > '$NGINX_CONF'" <<'EOF'
server {
    listen 8080 default_server;
    server_name _;
    location / {
        proxy_pass         http://127.0.0.1:5001;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
EOF
  $SUDO ln -sf "$NGINX_CONF" "$NGINX_LINK"
  $SUDO systemctl reload nginx

  printf '{"startedUtc": "%s"}\n' "$(date -u +%FT%TZ)" > "$STATE_F"
  sleep 2
  curl -s -i "http://localhost:8080/" >/dev/null 2>&1 || true

  echo
  echo "${C_YELLOW}TICKET NET-D1-102  [P2: customers see the outage]${C_OFF}"
  echo "  Customer Portal returns HTTP 502 Bad Gateway behind nginx."
  echo "  The Kestrel service failed to start."
  echo
  echo "${C_CYAN}NEXT: curl.exe -i http://localhost:8080/ then follow Participant_Guide_day1.md Ticket 2.${C_OFF}"
}

do_check() {
  echo "==================================================="
  echo " Validating NET-D1-102: IIS / Reverse Proxy ANCM   "
  echo "==================================================="

  code="$(http_status http://localhost:8080/ 15)"
  [ "$code" = "200" ] && record PASS "http://localhost:8080/ returns 200" || record FAIL "http://localhost:8080/ returns 200" "got HTTP ${code:-000}"

  who="$(http_body http://localhost:8080/whoami 10)"
  echo "$who" | grep -q '"processName"' && record PASS "Endpoint /whoami responds with valid JSON" || record FAIL "Endpoint /whoami responds with valid JSON"

  [ -f "$EVID/customerportal.service" ] || [ -f "$EVID/web.config" ] && record PASS "Corrected config/unit file present in evidence" || record FAIL "Corrected config/unit file present in evidence"

  finish_checks "NET-D1-102"
}

case "${1:-check}" in
  start) do_start ;;
  check) do_check ;;
  reset) do_reset ;;
  *) do_check ;;
esac

