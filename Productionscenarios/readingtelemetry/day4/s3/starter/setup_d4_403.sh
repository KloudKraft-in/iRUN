#!/usr/bin/env bash
# TEL-D4-403 provider setup: reuses D4-1 simulator + Prometheus (:9090) and D4-2 Grafana (:3000)
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"; L=/opt/labs/D4-3
mkdir -p $L; cp "$KIT/dashboard_sre_broken.json" "$KIT/lab.sh" $L/; chmod +x $L/lab.sh
systemctl is-active --quiet shopnow-d4 || { echo "!! run TEL-D4-401 setup first (shopnow-d4 simulator)"; exit 1; }
docker ps --format '{{.Names}}' | grep -q d4-grafana || { echo "!! run TEL-D4-402 setup first (d4-grafana)"; exit 1; }
echo "services in Prometheus: $(curl -s localhost:9090/api/v1/label/service/values)"
bash $L/lab.sh import
echo "DONE. Next (participant): cd $L && sudo ./lab.sh start"
