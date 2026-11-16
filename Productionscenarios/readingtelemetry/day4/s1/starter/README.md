# TEL-D4-401 kit — Slow-Transaction Report (New Relic + Prometheus)
Built because the provided files only contained the NRQL text: there was no ShopNow app reporting to New Relic, no Prometheus histogram and no lab.sh.

| File | Purpose |
|---|---|
| app.py | Flask "ShopNow-Production" simulator: 6 transactions (processPayment p95 ≈ 4.2 s), TransactionErrors (PaymentGatewayTimeoutError, InventoryReservationError, SmtpRelayError), Prometheus histogram `http_request_duration_seconds_bucket{service,handler,method}` + `http_requests_total{…,status}` on :8095/metrics |
| setup_d4_401.sh | venv /opt/labs/D4-1, systemd `shopnow-d4` (runs under newrelic-admin) + `shopnow-d4-load`, Prometheus `d4-prometheus` (prom/prometheus:v2.53.0, :9090) |
| lab.sh | start / status / check / reset. `check` validates /opt/labs/D4-1/answers.md + live Prometheus ranking |
| answers.md | Reference submission (NRQL, top-5 table, PromQL cross-check, exec summary) |

Run: `export NEW_RELIC_LICENSE_KEY=<ingest key>; sudo -E bash setup_d4_401.sh; cd /opt/labs/D4-1 && sudo ./lab.sh start`. Wait ~10 min for data, do the NRQL steps, write answers.md, `sudo ./lab.sh check`.
