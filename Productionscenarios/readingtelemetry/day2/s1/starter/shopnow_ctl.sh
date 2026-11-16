#!/usr/bin/env bash
# sudo bash shopnow_ctl.sh start | inject | reset | status | stop
case "$1" in
  start)  systemctl enable --now stripe-mock PaymentService CheckoutService
          sleep 25; systemctl enable --now shopnow-load; echo "Traffic running (2 req/s)";;
  inject) curl -s "http://localhost:8090/admin/fault?percent=${2:-60}"; echo
          echo "Fault ON: ~${2:-60}% of StripeGatewayConnector.authorize() calls will time out at 5000ms";;
  reset)  curl -s "http://localhost:8090/admin/fault?percent=0"; echo; echo "Fault OFF";;
  status) systemctl --no-pager -l status stripe-mock PaymentService CheckoutService shopnow-load | grep -E '●|Active'
          echo "--- test call:"; curl -s -X POST "http://localhost:8081/checkout?orderId=TEST&amount=1"; echo;;
  stop)   systemctl stop shopnow-load CheckoutService PaymentService stripe-mock;;
  *) echo "usage: $0 start|inject [pct]|reset|status|stop";;
esac
