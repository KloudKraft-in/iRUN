#!/usr/bin/env bash
# TEL-D2-203 check script: validates the escalation note and that the three evidence sources are reachable.
F="${1:-/opt/labs/D2-3/escalation.md}"; ok=0; fail=0
pass(){ echo "PASS  $1"; ok=$((ok+1)); }; bad(){ echo "FAIL  $1"; fail=$((fail+1)); }
[ -f "$F" ] && pass "escalation note exists ($F)" || { bad "missing $F"; exit 1; }
for s in "Incident Severity" "Executive Summary" "Causal Hypothesis"; do grep -qi "$s" "$F" && pass "section: $s" || bad "section: $s"; done
grep -Eq 'localhost:3000/d/[^ ]*viewPanel=' "$F" && pass "Grafana panel deep link (viewPanel)" || bad "Grafana panel deep link with viewPanel"
grep -Eq 'service\.name:.*order-service' "$F" && grep -Eiq 'log\.level:.*ERROR' "$F" && pass "Kibana KQL query" || bad "Kibana KQL query"
grep -Eq '5601/app/(r/s/|discover)' "$F" && pass "Kibana saved/share link" || bad "Kibana link"
grep -q 'one.newrelic.com' "$F" && grep -q 'CheckoutController#processOrder' "$F" && pass "New Relic transaction link" || bad "New Relic link"
grep -Eiq 'pg_sleep' "$F" && pass "slow query identified (pg_sleep)" || bad "slow query not identified"
curl -sf -o /dev/null http://localhost:3000/api/dashboards/uid/red-checkout -u admin:Admin@123 && pass "Grafana dashboard red-checkout reachable" || bad "Grafana dashboard not reachable"
n=$(curl -s 'http://localhost:9200/ecommerce-logs-*/_count' -H 'Content-Type: application/json' -d '{"query":{"bool":{"filter":[{"term":{"service.name.keyword":"order-service"}},{"term":{"log.level.keyword":"ERROR"}}]}}}' | grep -o '"count":[0-9]*' | cut -d: -f2)
[ "${n:-0}" -gt 0 ] && pass "Kibana/ES has $n order-service ERROR docs" || bad "no ERROR docs in ecommerce-logs-*"
echo "----"; echo "RESULT: $ok passed, $fail failed"; [ $fail -eq 0 ]
