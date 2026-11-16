#!/usr/bin/env bash
# TEL-D2-203 provider setup: order-service -> Prometheus/Grafana, Elasticsearch/Kibana, New Relic
# Usage:  sudo NEW_RELIC_LICENSE_KEY=<ingest license key> bash setup_orders.sh
set -euo pipefail
: "${NEW_RELIC_LICENSE_KEY:?set NEW_RELIC_LICENSE_KEY (New Relic -> API keys -> INGEST - LICENSE)}"
KIT="$(cd "$(dirname "$0")" && pwd)"

echo ">>> [1/6] Elasticsearch auth"
ES_PASS="${ES_PASS:-}"
if [ -z "$ES_PASS" ]; then
  ES_PASS=$(docker inspect obs-lab-elasticsearch --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | sed -n 's/^ELASTIC_PASSWORD=//p' | head -1 || true)
fi
code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:9200 || true)
if [ "$code" = "200" ]; then ES_PASS=""; echo "ES: no auth"
elif [ -n "$ES_PASS" ] && [ "$(curl -s -o /dev/null -w '%{http_code}' -u "elastic:$ES_PASS" http://localhost:9200)" = "200" ]; then echo "ES: auth ok (elastic user)"
else echo "!! Elasticsearch on :9200 needs a password. Re-run with ES_PASS=<elastic password>"; exit 1; fi

echo ">>> [2/6] postgres orders_db"
apt-get install -y postgresql python3-venv curl >/dev/null
systemctl enable --now postgresql
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='app'" | grep -q 1 || sudo -u postgres psql -c "CREATE USER app WITH PASSWORD 'app';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='orders_db'" | grep -q 1 || sudo -u postgres psql -c "CREATE DATABASE orders_db OWNER app;"
PGPASSWORD=app psql -h localhost -U app -d orders_db -c "CREATE TABLE IF NOT EXISTS orders(id int primary key, status text, updated_at timestamptz); INSERT INTO orders SELECT g,'NEW',now() FROM generate_series(1,1000) g ON CONFLICT DO NOTHING;" >/dev/null

echo ">>> [3/6] order-service app"
mkdir -p /opt/orders /etc/orders
[ -d /opt/orders/venv ] || python3 -m venv /opt/orders/venv
/opt/orders/venv/bin/pip install -q flask gunicorn psycopg2-binary requests prometheus_client newrelic
cp "$KIT/app.py" /opt/orders/app.py
umask 077
cat > /etc/orders/env <<EOF
NEW_RELIC_LICENSE_KEY=$NEW_RELIC_LICENSE_KEY
NEW_RELIC_APP_NAME=order-service
NEW_RELIC_DISTRIBUTED_TRACING_ENABLED=true
NEW_RELIC_TRANSACTION_TRACER_TRANSACTION_THRESHOLD=1.0
ES_URL=http://localhost:9200
ES_USER=elastic
ES_PASS=$ES_PASS
EOF
umask 022
cat > /etc/systemd/system/order-service.service <<'EOF'
[Unit]
Description=order-service (TEL-D2-203)
After=network.target postgresql.service
[Service]
EnvironmentFile=/etc/orders/env
ExecStart=/opt/orders/venv/bin/newrelic-admin run-program /opt/orders/venv/bin/gunicorn -w 1 --threads 32 -b 0.0.0.0:8086 --chdir /opt/orders app:app
Restart=always
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/order-load.service <<'EOF'
[Unit]
Description=order-service traffic (2 req/s)
After=order-service.service
[Service]
ExecStart=/bin/bash -c 'while true; do curl -s -o /dev/null -m 20 -X POST http://localhost:8086/api/checkout & sleep 0.5; done'
Restart=always
[Install]
WantedBy=multi-user.target
EOF

echo ">>> [4/6] Prometheus + Grafana (docker, host network)"
mkdir -p /opt/obs3/grafana/provisioning/{datasources,dashboards} /opt/obs3/grafana/dashboards
cat > /opt/obs3/prometheus.yml <<'EOF'
global: {scrape_interval: 5s}
scrape_configs:
  - job_name: order-service
    static_configs: [{targets: ['localhost:8086']}]
EOF
cat > /opt/obs3/grafana/provisioning/datasources/prom.yml <<'EOF'
apiVersion: 1
datasources:
  - {name: Prometheus, uid: prom, type: prometheus, access: proxy, url: http://localhost:9090, isDefault: true}
EOF
cat > /opt/obs3/grafana/provisioning/dashboards/files.yml <<'EOF'
apiVersion: 1
providers:
  - {name: files, type: file, options: {path: /var/lib/grafana/dashboards}}
EOF
cat > /opt/obs3/grafana/dashboards/red-checkout.json <<'EOF'
{"uid":"red-checkout","title":"RED - Checkout","time":{"from":"now-1h","to":"now"},"refresh":"10s","schemaVersion":39,
 "panels":[
  {"id":1,"type":"timeseries","title":"Checkout request rate (req/s)","gridPos":{"x":0,"y":0,"w":12,"h":8},
   "datasource":{"type":"prometheus","uid":"prom"},
   "targets":[{"refId":"A","expr":"sum(rate(checkout_requests_total{service=\"order-service\"}[1m]))","legendFormat":"req/s"}]},
  {"id":2,"type":"timeseries","title":"Checkout latency p95 (order-service)","gridPos":{"x":12,"y":0,"w":12,"h":8},
   "datasource":{"type":"prometheus","uid":"prom"},
   "fieldConfig":{"defaults":{"unit":"s","thresholds":{"mode":"absolute","steps":[{"color":"green","value":null},{"color":"red","value":5}]},"custom":{"thresholdsStyle":{"mode":"line"}}}},
   "targets":[{"refId":"A","expr":"histogram_quantile(0.95, sum(rate(checkout_request_duration_seconds_bucket{service=\"order-service\"}[1m])) by (le))","legendFormat":"p95"}]},
  {"id":3,"type":"timeseries","title":"Checkout errors (HTTP 503 / s)","gridPos":{"x":0,"y":8,"w":24,"h":8},
   "datasource":{"type":"prometheus","uid":"prom"},
   "targets":[{"refId":"A","expr":"sum(rate(checkout_requests_total{service=\"order-service\",status=\"503\"}[1m]))","legendFormat":"503/s"}]}
 ]}
EOF
docker rm -f obs3-prometheus obs3-grafana >/dev/null 2>&1 || true
docker run -d --name obs3-prometheus --restart unless-stopped --network host \
  -v /opt/obs3/prometheus.yml:/etc/prometheus/prometheus.yml:ro prom/prometheus:latest >/dev/null
docker run -d --name obs3-grafana --restart unless-stopped --network host \
  -e GF_SECURITY_ADMIN_PASSWORD=Admin@123 \
  -v /opt/obs3/grafana/provisioning:/etc/grafana/provisioning:ro \
  -v /opt/obs3/grafana/dashboards:/var/lib/grafana/dashboards:ro grafana/grafana:latest >/dev/null

echo ">>> [5/6] start order-service"
systemctl daemon-reload
systemctl enable --now order-service
sleep 5
systemctl enable --now order-load

echo ">>> [6/6] Kibana data view ecommerce-logs-*"
sleep 20
KAUTH=(); [ -n "$ES_PASS" ] && KAUTH=(-u "elastic:$ES_PASS")
curl -s "${KAUTH[@]}" -X POST http://localhost:5601/api/data_views/data_view -H 'kbn-xsrf: true' -H 'Content-Type: application/json' \
  -d '{"data_view":{"title":"ecommerce-logs-*","name":"ecommerce-logs-*","timeFieldName":"@timestamp"}}' | head -c 200; echo
echo
echo "DONE.  Grafana http://localhost:3000 (admin/Admin@123) · Kibana http://localhost:5601 · New Relic APM: order-service"
echo "Next: sudo bash orders_ctl.sh status ; wait ~10 min ; sudo bash orders_ctl.sh inject"
