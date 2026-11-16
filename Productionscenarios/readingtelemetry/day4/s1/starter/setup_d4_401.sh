#!/usr/bin/env bash
# TEL-D4-401 provider setup: ShopNow-Production simulator -> New Relic APM + Prometheus
# Usage: sudo NEW_RELIC_LICENSE_KEY=<INGEST - LICENSE key> bash setup_d4_401.sh
set -euo pipefail
: "${NEW_RELIC_LICENSE_KEY:?set NEW_RELIC_LICENSE_KEY}"
KIT="$(cd "$(dirname "$0")" && pwd)"
L=/opt/labs/D4-1

echo ">>> [1/5] packages (python, docker)"
apt-get update -y >/dev/null || true
apt-get install -y python3-venv curl >/dev/null
command -v docker >/dev/null || { apt-get install -y docker.io >/dev/null; systemctl enable --now docker; }

echo ">>> [2/5] app"
mkdir -p $L
[ -d $L/venv ] || python3 -m venv $L/venv
$L/venv/bin/pip install -q flask gunicorn prometheus_client newrelic
cp "$KIT/app.py" $L/app.py
cp "$KIT/lab.sh" $L/lab.sh; chmod +x $L/lab.sh
umask 077
cat > $L/env <<EOV
NEW_RELIC_LICENSE_KEY=$NEW_RELIC_LICENSE_KEY
NEW_RELIC_APP_NAME=ShopNow-Production
NEW_RELIC_DISTRIBUTED_TRACING_ENABLED=true
EOV
umask 022

echo ">>> [3/5] systemd units"
cat > /etc/systemd/system/shopnow-d4.service <<EOV
[Unit]
Description=ShopNow-Production simulator (TEL-D4-401)
After=network.target
[Service]
EnvironmentFile=$L/env
ExecStart=$L/venv/bin/newrelic-admin run-program $L/venv/bin/gunicorn -w 1 --threads 64 -b 0.0.0.0:8095 --chdir $L app:app
Restart=always
[Install]
WantedBy=multi-user.target
EOV
cat > $L/loadgen.sh <<'EOV'
#!/usr/bin/env bash
# weighted traffic, ~4 req/s
T=( "CheckoutController%23processPayment" "CheckoutController%23processPayment"
    "OrderController%23createOrder" "OrderController%23createOrder"
    "InventoryController%23reserveStock" "InventoryController%23reserveStock"
    "NotificationController%23sendConfirmation" "PaymentController%23refund"
    "OrderController%23getOrderStatus" "OrderController%23getOrderStatus" "OrderController%23getOrderStatus" )
while true; do
  curl -s -o /dev/null -m 15 -X POST "http://localhost:8095/tx/${T[$RANDOM % ${#T[@]}]}" &
  sleep 0.25
done
EOV
chmod +x $L/loadgen.sh
cat > /etc/systemd/system/shopnow-d4-load.service <<EOV
[Unit]
Description=ShopNow-Production traffic
After=shopnow-d4.service
[Service]
ExecStart=$L/loadgen.sh
Restart=always
[Install]
WantedBy=multi-user.target
EOV

echo ">>> [4/5] Prometheus (docker, :9090, retention 3d)"
docker stop obs3-prometheus >/dev/null 2>&1 || true      # free :9090 if an older lab container holds it
mkdir -p /opt/labs/prometheus
cat > /opt/labs/prometheus/prometheus.yml <<'EOV'
global: {scrape_interval: 15s}
scrape_configs:
  - job_name: shopnow
    static_configs: [{targets: ['localhost:8095']}]
EOV
docker rm -f d4-prometheus >/dev/null 2>&1 || true
docker run -d --name d4-prometheus --restart unless-stopped --network host \
  -v /opt/labs/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  prom/prometheus:v2.53.0 --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.retention.time=3d >/dev/null

echo ">>> [5/5] start"
systemctl daemon-reload
systemctl enable --now shopnow-d4
sleep 4
systemctl enable --now shopnow-d4-load
echo "DONE. Let it run 20-30 min, then: sudo bash $L/lab.sh status"
