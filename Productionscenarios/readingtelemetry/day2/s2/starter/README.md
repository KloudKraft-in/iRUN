# TEL-D2-202 — Datadog Monitor Fires: Confirm It in Splunk (lab kit)

Reproduces the scenario end-to-end on one Ubuntu 22.04 VM (≥ 4 GB RAM):

```
checkout-api (Flask, ddtrace)  ──postgres.query──▶  sql-orders (PostgreSQL)
        │ JSON log /var/log/checkout/checkout.json
        ├──▶ Datadog Agent (host prod-worker-02: metrics, APM, logs)
        └──▶ Splunk Enterprise (index=retail_prod, sourcetype=checkout:json)
```

Fault \= real PostgreSQL deadlocks (opposite lock order) \+ CPU \~95% (stress-ng). `seed` forces transaction **88129** to be a deadlock victim → `TXN-88129-CORR`.

## Files

| File | Purpose |
| :---- | :---- |
| `setup_checkout.sh` | installs Postgres, Python app, systemd units (`checkout-api`, `checkout-load`) |
| `app.py` | checkout-api source (logs `transaction_id`, `error_code`, `error_msg`, `dd.trace_id`) |
| `checkout_ctl.sh` | `start` · `inject` · `seed` · `status` · `reset` · `stop` |
| `configure_datadog.sh` | points the Agent at your org, hostname `prod-worker-02`, APM \+ log collection |
| `configure_splunk.sh` | `props.conf`, index `retail_prod`, file monitor |
| `create_monitors.sh` | creates the 3 monitors via API (alternative to the UI steps below) |
| `d2_2_splunk_search.spl` | official Splunk search |

## Provider setup (once)

```sh
sudo bash setup_checkout.sh
sudo DD_API_KEY=<org api key> DD_SITE=datadoghq.com bash configure_datadog.sh
sudo SPLUNK_PASS='<admin pw>' bash configure_splunk.sh
sudo bash checkout_ctl.sh start          # wait ~10 min: prod-worker-02 + checkout-api/sql-orders appear in Datadog
DD_API_KEY=... DD_APP_KEY=... bash create_monitors.sh   # or create them in the UI:
```

UI equivalent:

1. **Metric** monitor `avg:system.cpu.user{host:prod-worker-02}` \> 80 (warn 70), last 5 min → *High CPU on checkout-worker*  
2. **APM → APM Metrics**: Error Rate, service `checkout-api`, operation `flask.request`, resource `*`, sum, last 5 min, \> 0.05 (warn 0.03) → *checkout-api Error Rate \> 5%*  
3. **Composite**: a \= \#1, b \= \#2, trigger `a && b` → *\[CRITICAL\] High CPU on checkout-worker AND Error Rate \> 5%* (check that a and b are **two different** monitors)

## Fire the incident

```sh
sudo bash checkout_ctl.sh inject     # deadlocks + CPU 95% for 3h
sleep 30
sudo bash checkout_ctl.sh seed       # prints the TXN-88129-CORR deadlock line (note its timestamp)
```

Composite goes ALERT in \~5–10 min. Reset afterwards: `sudo bash checkout_ctl.sh reset`.

## Participant walkthrough (ticket steps 1–8)

1. Datadog **Monitors → Triggered** → composite in ALERT  
2. Open it → host `prod-worker-02`, service `checkout-api`  
3. **Software Catalog → Map** (env prod) → `checkout-api → sql-orders`  
4. **Logs**: `service:checkout-api @transaction_id:TXN-88129-CORR` → open log → *Trace* tab → failing span `postgres.query` on **sql-orders** (`UPDATE inventory SET qty = qty ? WHERE id = ?`, Error detected)  
5. Splunk `http://localhost:8000` (SSH tunnel)  
6. Run `d2_2_splunk_search.spl` (Last 60 min)  
7. Expand the event: `transaction_id`, `timestamp`, `dd.trace_id`, `error_code` identical to the Datadog log  
8. Document: Composite → host/service → Service Map → errored span → Datadog log → Splunk raw event

## Reference run (2026-11-12)

| Item | Value |
| :---- | :---- |
| Monitor | `[CRITICAL] High CPU on checkout-worker AND Error Rate > 5%` (ALERT) |
| Failing span | `postgres.query` · service `sql-orders` · `UPDATE inventory SET qty = qty ? WHERE id = ?` |
| Transaction | `TXN-88129-CORR` ("Deadlock victim: Transaction ID 88129") |
| Timestamp | `2026-11-12T09:17:58.527Z` (same in Datadog & Splunk) |
| Trace ID | `11759565762071994081` (same in Datadog & Splunk `dd.trace_id`) |
| Error | `DB_DEADLOCK_40P01` / `deadlock detected` |

## Gotchas seen while building this

- Agent API key from a **different org** → monitors show NO DATA, Host List empty. Use a key from the org you browse.  
- Composite accidentally built as CPU `&&` CPU → never reflects errors. Check the two IDs in its query.  
- Error-rate monitor pointed at old service `checkout` → must be `checkout-api`.  
- Datadog search: `"TXN-88129-CORR"` free-text doesn't match (it's an attribute) → use `@transaction_id:TXN-88129-CORR`.  
- Splunk doesn't auto-start after VM reboot: `sudo /opt/splunk/bin/splunk start --run-as-root`.  
- Each `seed` run writes another TXN-88129-CORR event; use the latest one.