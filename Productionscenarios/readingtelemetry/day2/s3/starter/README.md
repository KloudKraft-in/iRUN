# TEL-D2-203&nbsp;

One Ubuntu 22.04 VM with Docker, plus a free New Relic account.

```
order-service (Flask, New Relic Python agent) ──▶ PostgreSQL orders_db
   ├─ /metrics ──▶ Prometheus (:9090) ──▶ Grafana (:3000) dashboard "RED - Checkout" (uid red-checkout, panel 2 = p95)
   ├─ JSON logs ─▶ Elasticsearch (:9200) index ecommerce-logs-YYYY.MM.DD ──▶ Kibana (:5601) data view ecommerce-logs-*
   └─ APM ──────▶ New Relic: app order-service, transaction CheckoutController#processOrder
```

Fault (`orders_ctl.sh inject`): every checkout does 0.6 s app work \+ `SELECT pg_sleep(7.6)` (simulated table-lock wait) while holding 1 of 5 pooled connections → pool exhaustion → `Database connection timeout … after 5000ms` errors (HTTP 503).

## Files

| File | Purpose |
| :---- | :---- |
| `app.py` | order-service source |
| `setup_orders.sh` | Postgres orders\_db, app \+ systemd units, Prometheus \+ Grafana containers, Kibana data view |
| `orders_ctl.sh` | `start` · `inject` · `reset` · `status` · `stop` |

Provider setup

Prereq: Elasticsearch \+ Kibana 8.x already on :9200/:5601 (here: the `obs-lab-*` containers). If ES has a password, add `ES_PASS=...`.

```sh
sudo NEW_RELIC_LICENSE_KEY=<INGEST - LICENSE key> bash setup_orders.sh
sudo bash orders_ctl.sh status        # baseline: test call ~0.05 s
# wait ~10 min
sudo bash orders_ctl.sh inject        # note the UTC time printed
# leave 20-30 min, capture evidence, then
sudo bash orders_ctl.sh reset
```

## Participant walkthrough (ticket steps 1–5)

1. **Grafana** `http://localhost:3000` (admin/Admin@123) → *RED \- Checkout* → panel *Checkout latency p95* → ⋮ → View (URL gets `viewPanel=panel-2`) → set time to the incident window → copy URL.  
2. **Kibana** `http://localhost:5601` → Discover → data view `ecommerce-logs-*` → KQL `service.name: "order-service" and log.level: "ERROR"` → add `message` column → note top messages → Share → Copy link.  
3. **New Relic** → APM & Services → order-service → Transactions → `CheckoutController#processOrder` → slowest trace → *Trace details* (Postgres select ≈ 7.6 s) and *Database queries* (`SELECT pg_sleep(?)`).  
4. Write the escalation note (Severity, Executive Summary, Causal Hypothesis, 3 deep links) → `/opt/labs/D2-3/escalation.md`.  
5. `bash check_escalation.sh /opt/labs/D2-3/escalation.md`

## Reference run (2026-11-12)

| Item | Value |
| :---- | :---- |
| Incident window | 10:58:21 → 12:31:28 UTC |
| Grafana | p95 0.05 s → **14.2 s** (threshold 5 s) |
| Kibana | 906 ERROR docs (first 12 min): `Database connection timeout: could not acquire connection from pool 'orders_db' after 5000ms (pool size 5, all connections busy)` |
| New Relic | `CheckoutController#processOrder` avg 7.47 s, p95 13.2 s; slowest trace 13.23 s → **Postgres select 7.62 s**, query `SELECT pg_sleep(?)` |

&nbsp;