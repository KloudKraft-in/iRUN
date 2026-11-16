# TEL-D4-402 kit — Payment Error Volume panel (Loki + Grafana)
Built because no Loki/Promtail/Grafana stack, payment log source, dashboard or lab.sh was provided.

| File | Purpose |
|---|---|
| payment_logger.py | Writes JSON logs to /var/log/payment/payment.log; when /etc/labs/d4-2/fault exists emits ~1.5 ERROR/s "Gateway timeout" (level "ERROR", never lowercase "error") |
| dashboard_broken.json | "Payment Dashboard" (uid payment-dashboard) with the broken panel `sum(count_over_time({app="payment-service"} |= "error" [1m]))` |
| setup_d4_402.sh | Loki 2.9.8 (:3100), Promtail 2.9.8 (label app=payment-service), Grafana 10.4.2 `d4-grafana` (:3000, admin/Admin@123) with Loki + Prometheus datasources; stops old obs3-grafana |
| lab.sh | import / start (outage) / status / check / reset |
| answers.md | RCA + fixed query + thresholds |

Run: `sudo bash setup_d4_402.sh; cd /opt/labs/D4-2 && sudo ./lab.sh start`, fix panel in Grafana, Save, `sudo ./lab.sh check`.
