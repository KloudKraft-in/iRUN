#!/usr/bin/env bash
# Creates the 3 Datadog monitors for TEL-D2-202 via the Datadog API (same result as the UI steps in README).
# Needs an API key AND an Application key from YOUR org (Organization Settings -> API Keys / Application Keys).
# Usage:  DD_API_KEY=... DD_APP_KEY=... DD_SITE=datadoghq.com bash create_monitors.sh
set -euo pipefail
: "${DD_API_KEY:?}"; : "${DD_APP_KEY:?}"; DD_SITE="${DD_SITE:-datadoghq.com}"
python3 - <<'EOF'
import json, os, urllib.request
site, h = os.environ.get("DD_SITE", "datadoghq.com"), {
  "DD-API-KEY": os.environ["DD_API_KEY"], "DD-APPLICATION-KEY": os.environ["DD_APP_KEY"],
  "Content-Type": "application/json"}
def create(body):
    r = urllib.request.Request(f"https://api.{site}/api/v1/monitor", json.dumps(body).encode(), h, method="POST")
    m = json.load(urllib.request.urlopen(r)); print("created", m["id"], m["name"]); return m["id"]

cpu = create({"name": "High CPU on checkout-worker", "type": "metric alert",
  "query": "avg(last_5m):avg:system.cpu.user{host:prod-worker-02} > 80",
  "message": "{{#is_alert}}CPU on {{host.name}} is {{value}}% (threshold 80%). Host prod-worker-02 (checkout-worker) is saturated.{{/is_alert}}\n{{#is_recovery}}CPU back to normal.{{/is_recovery}}",
  "options": {"thresholds": {"critical": 80, "warning": 70}}, "tags": ["lab:tel-d2-202"]})

err = create({"name": "checkout-api Error Rate > 5%", "type": "query alert",
  "query": "sum(last_5m):( sum:trace.flask.request.errors{env:prod,service:checkout-api}.as_count() / sum:trace.flask.request.hits{env:prod,service:checkout-api}.as_count() ) > 0.05",
  "message": "{{#is_alert}}checkout-api error rate is {{value}} (threshold 5%) on prod-worker-02.{{/is_alert}}\n{{#is_recovery}}checkout-api error rate back to normal.{{/is_recovery}}",
  "options": {"thresholds": {"critical": 0.05, "warning": 0.03}}, "tags": ["lab:tel-d2-202", "service:checkout-api"]})

create({"name": "[CRITICAL] High CPU on checkout-worker AND Error Rate > 5%", "type": "composite",
  "query": f"{cpu} && {err}",
  "message": "{{#is_alert}}[CRITICAL] High CPU on checkout-worker (prod-worker-02) AND checkout-api error rate > 5%. Investigate APM service map (checkout-api -> sql-orders) and Splunk index=retail_prod.{{/is_alert}}\n{{#is_recovery}}Composite recovered.{{/is_recovery}}",
  "tags": ["lab:tel-d2-202"]})
EOF
