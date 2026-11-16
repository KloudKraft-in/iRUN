#!/usr/bin/env bash
# TEL-D4-401 harness:  lab.sh start | status | check | reset
L=/opt/labs/D4-1; P=http://localhost:9090
q(){ curl -s "$P/api/v1/query" --data-urlencode "query=$1"; }
case "$1" in
  start)  systemctl start shopnow-d4 shopnow-d4-load; docker start d4-prometheus >/dev/null; echo "ShopNow-Production traffic ON";;
  status) systemctl --no-pager status shopnow-d4 shopnow-d4-load | grep -E '●|Active'
          docker ps --format '{{.Names}}\t{{.Status}}' | grep d4-
          echo "--- Prometheus top 5 p95 by handler (since start):"
          q 'topk(5, histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[1d])) by (le, handler)))' \
            | python3 -c 'import sys,json;[print("%6.2fs  %s" % (float(r["value"][1]), r["metric"]["handler"])) for r in sorted(json.load(sys.stdin)["data"]["result"],key=lambda r:-float(r["value"][1]))]';;
  check)  ok=0; fail=0; pass(){ echo "PASS  $1"; ok=$((ok+1)); }; bad(){ echo "FAIL  $1"; fail=$((fail+1)); }
          top=$(q 'topk(1, histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[1d])) by (le, handler)))' \
                | python3 -c 'import sys,json;r=json.load(sys.stdin)["data"]["result"][0];print(r["metric"]["handler"],r["value"][1])')
          set -- $top
          [ "$1" = "CheckoutController#processPayment" ] && pass "PromQL top transaction = $1" || bad "PromQL top transaction = $1"
          python3 -c "import sys;sys.exit(0 if 3.5<=float('$2')<=5 else 1)" && pass "PromQL p95 = $(printf %.2f $2)s (expected ~4.2s)" || bad "PromQL p95 = $2"
          A=$L/answers.md
          if [ -f $A ]; then pass "answer card $A exists"
            grep -qi 'percentile(duration, *95)' $A && grep -qi 'FACET name' $A && grep -q "ShopNow-Production" $A && pass "NRQL ranking query" || bad "NRQL ranking query"
            grep -qi 'TIMESERIES' $A && pass "NRQL TIMESERIES query" || bad "NRQL TIMESERIES query"
            grep -qi 'FROM TransactionError' $A && grep -qi 'FACET error.class' $A && pass "NRQL error-impact query" || bad "NRQL error-impact query"
            grep -q 'histogram_quantile' $A && grep -q 'by (le, handler)' $A && pass "PromQL cross-check query" || bad "PromQL cross-check query"
            grep -q 'CheckoutController#processPayment' $A && pass "slowest transaction named" || bad "slowest transaction not named"
          else bad "answer card $A missing"; fi
          echo "----"; echo "RESULT: $ok passed, $fail failed"; [ $fail -eq 0 ];;
  reset)  systemctl stop shopnow-d4-load shopnow-d4; rm -f $L/answers.md; echo "stopped; answer card removed";;
  *) echo "usage: $0 start|status|check|reset";;
esac
