#!/usr/bin/env bash
# TEL-D4-402 provider setup: payment-service JSON logs -> Promtail -> Loki 2.9 -> Grafana 10.4 (broken panel)
# Usage: sudo bash setup_d4_402.sh
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"; L=/opt/labs/D4-2; G=/opt/labs/grafana
command -v docker >/dev/null || { apt-get install -y docker.io >/dev/null; systemctl enable --now docker; }

echo ">>> [1/5] payment-service log generator"
mkdir -p $L /etc/labs/d4-2 /var/log/payment
cp "$KIT/payment_logger.py" "$KIT/dashboard_broken.json" "$KIT/lab.sh" $L/; chmod +x $L/lab.sh
cat > /etc/systemd/system/payment-logger.service <<EOV
[Unit]
Description=payment-service JSON log generator (TEL-D4-402)
[Service]
ExecStart=/usr/bin/python3 $L/payment_logger.py
Restart=always
[Install]
WantedBy=multi-user.target
EOV
systemctl daemon-reload; systemctl enable --now payment-logger

echo ">>> [2/5] Loki 2.9 (:3100)"
docker rm -f d4-loki >/dev/null 2>&1 || true
docker run -d --name d4-loki --restart unless-stopped --network host grafana/loki:2.9.8 -config.file=/etc/loki/local-config.yaml >/dev/null

echo ">>> [3/5] Promtail (tails /var/log/payment/*.log, label app=payment-service)"
mkdir -p /opt/labs/promtail
cat > /opt/labs/promtail/config.yml <<'EOV'
server: {http_listen_port: 9080, grpc_listen_port: 0}
positions: {filename: /tmp/positions.yaml}
clients: [{url: 'http://localhost:3100/loki/api/v1/push'}]
scrape_configs:
  - job_name: payment
    static_configs:
      - targets: [localhost]
        labels: {app: payment-service, job: payment, __path__: /var/log/payment/*.log}
EOV
docker rm -f d4-promtail >/dev/null 2>&1 || true
docker run -d --name d4-promtail --restart unless-stopped --network host \
  -v /opt/labs/promtail/config.yml:/etc/promtail/config.yml:ro -v /var/log/payment:/var/log/payment:ro \
  grafana/promtail:2.9.8 -config.file=/etc/promtail/config.yml >/dev/null

echo ">>> [4/5] Grafana 10.4 (:3000) with Loki + Prometheus datasources"
docker stop obs3-grafana >/dev/null 2>&1 || true          # Day-2 Grafana held :3000
docker update --restart=no obs3-grafana >/dev/null 2>&1 || true
mkdir -p $G/provisioning/datasources
cat > $G/provisioning/datasources/ds.yml <<'EOV'
apiVersion: 1
datasources:
  - {name: Loki, uid: loki, type: loki, access: proxy, url: http://localhost:3100}
  - {name: Prometheus, uid: prom, type: prometheus, access: proxy, url: http://localhost:9090, isDefault: true}
EOV
docker rm -f d4-grafana >/dev/null 2>&1 || true
docker run -d --name d4-grafana --restart unless-stopped --network host \
  -e GF_SECURITY_ADMIN_PASSWORD=Admin@123 -v $G/provisioning:/etc/grafana/provisioning:ro \
  grafana/grafana:10.4.2 >/dev/null
for i in $(seq 1 30); do curl -sf localhost:3000/api/health >/dev/null && break; sleep 2; done

echo ">>> [5/5] import broken 'Payment Dashboard'"
bash $L/lab.sh import
echo "DONE. Grafana http://localhost:3000 (admin / Admin@123). Next (participant): cd $L && sudo ./lab.sh start"
