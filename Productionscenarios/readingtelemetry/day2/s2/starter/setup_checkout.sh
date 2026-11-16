#!/usr/bin/env bash
# TEL-D2-202 provider setup: builds checkout-api (Flask + ddtrace) backed by Postgres "sql-orders".
# Run from the kit folder:  sudo bash setup_checkout.sh
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"

echo ">>> [1/4] packages"
apt-get update -y || true
apt-get install -y postgresql python3-venv python3-pip stress-ng curl

echo ">>> [2/4] postgres (shows in Datadog as sql-orders)"
systemctl enable --now postgresql
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='app'" | grep -q 1 || sudo -u postgres psql -c "CREATE USER app WITH PASSWORD 'app';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='orders'" | grep -q 1 || sudo -u postgres psql -c "CREATE DATABASE orders OWNER app;"
PGPASSWORD=app psql -h localhost -U app -d orders -c "CREATE TABLE IF NOT EXISTS inventory(id text primary key, qty int); INSERT INTO inventory VALUES ('A',1000000),('B',1000000) ON CONFLICT DO NOTHING;"

echo ">>> [3/4] app"
mkdir -p /opt/checkout /var/log/checkout /etc/checkout
chmod 755 /var/log/checkout
[ -d /opt/checkout/venv ] || python3 -m venv /opt/checkout/venv
/opt/checkout/venv/bin/pip install -q flask gunicorn psycopg2-binary ddtrace
cp "$KIT/app.py" /opt/checkout/app.py

echo ">>> [4/4] systemd units"
cat > /etc/systemd/system/checkout-api.service <<'EOF'
[Unit]
Description=checkout-api
After=network.target postgresql.service
[Service]
Environment=DD_SERVICE=checkout-api
Environment=DD_ENV=prod
Environment=DD_VERSION=1.0
Environment=DD_SERVICE_MAPPING=postgres:sql-orders
Environment=DD_LOGS_INJECTION=true
ExecStart=/opt/checkout/venv/bin/ddtrace-run /opt/checkout/venv/bin/gunicorn -w 1 --threads 16 -b 0.0.0.0:8085 --chdir /opt/checkout app:app
Restart=always
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/checkout-load.service <<'EOF'
[Unit]
Description=checkout traffic (3 req/s)
After=checkout-api.service
[Service]
ExecStart=/bin/bash -c 'while true; do curl -s -o /dev/null -X POST http://localhost:8085/checkout & sleep 0.33; done'
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable checkout-api checkout-load
echo "DONE. Next: configure_datadog.sh, configure_splunk.sh, then: sudo bash checkout_ctl.sh start"
