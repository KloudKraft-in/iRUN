#!/usr/bin/env bash
# sudo bash orders_ctl.sh start | inject | reset | status | stop
case "$1" in
  start)  systemctl start postgresql order-service; sleep 4; systemctl start order-load
          docker start obs3-prometheus obs3-grafana >/dev/null; echo "order-service + traffic on";;
  inject) touch /etc/orders/fault; echo "FAULT ON: $(date -u +%H:%M:%S) UTC - checkout ~8.2s (7.6s pg_sleep in orders_db), pool exhaustion errors";;
  reset)  rm -f /etc/orders/fault; echo "FAULT OFF: $(date -u +%H:%M:%S) UTC";;
  status) systemctl --no-pager status order-service order-load | grep -E '●|Active'
          docker ps --format '{{.Names}}\t{{.Status}}' | grep -E 'obs3|obs-lab'
          [ -f /etc/orders/fault ] && echo "FAULT: ON" || echo "FAULT: OFF"
          echo "--- test call:"; curl -s -m 20 -w '  (%{time_total}s)\n' -X POST http://localhost:8086/api/checkout
          echo "--- p95 latency now (s):"; curl -s 'http://localhost:9090/api/v1/query' --data-urlencode \
            'query=histogram_quantile(0.95, sum(rate(checkout_request_duration_seconds_bucket[1m])) by (le))' | grep -o '"value":\[[^]]*\]';;
  stop)   systemctl stop order-load order-service;;
  *) echo "usage: $0 start|inject|reset|status|stop";;
esac
