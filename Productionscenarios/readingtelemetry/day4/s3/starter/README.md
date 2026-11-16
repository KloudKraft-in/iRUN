# TEL-D4-403 kit — SRE dashboard p95 + $service variable (Prometheus + Grafana)
Requires D4-1 (shopnow-d4 + d4-prometheus metrics) and D4-2 (d4-grafana) to be set up first.

| File | Purpose |
|---|---|
| dashboard_sre_broken.json | "ShopNow SRE Dashboard" (uid shopnow-sre): broken P95 `histogram_quantile(0.95, http_request_duration_seconds_bucket)`, broken Service Error Rate (raw counter), `$service` regex `/^(order|payment).*$/` |
| setup_d4_403.sh | Copies kit to /opt/labs/D4-3 and imports the dashboard |
| lab.sh | import / start / status / check / reset. Check models Grafana's capture-group behaviour |
| answers.md | Math explanation, corrected queries, variable definition |

Run: `sudo bash setup_d4_403.sh; cd /opt/labs/D4-3 && sudo ./lab.sh start`, fix in Grafana, Save, `sudo ./lab.sh check`.
