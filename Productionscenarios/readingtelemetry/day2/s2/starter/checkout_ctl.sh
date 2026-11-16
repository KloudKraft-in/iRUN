#!/usr/bin/env bash
LOG=/var/log/checkout/checkout.json
case "$1" in
  start)  systemctl start postgresql checkout-api; sleep 5; systemctl start checkout-load; echo "traffic on";;
  inject) touch /etc/checkout/fault
          systemctl stop cpuburn 2>/dev/null
          systemctl reset-failed cpuburn 2>/dev/null
          systemd-run --unit=cpuburn stress-ng --cpu 0 --cpu-load 95 --timeout 180m >/dev/null
          echo "FAULT ON: DB deadlocks + CPU ~95% (3h)";;
  seed)   # reproduce the exact ticket transaction: TXN-88129-CORR as deadlock victim
          for i in $(seq 1 15); do
            curl -s -o /dev/null -X POST "http://localhost:8085/checkout?txn=88129&order=BA&hold=0.2" &
            curl -s -o /dev/null -X POST "http://localhost:8085/checkout?txn=8813$i&order=AB&hold=0.8" &
            wait
            if grep -q 'Deadlock victim: Transaction ID 88129"' $LOG; then
              echo "SEEDED:"; grep 'Transaction ID 88129"' $LOG | grep Deadlock | tail -1; exit 0; fi
          done; echo "seed failed - run again";;
  reset)  rm -f /etc/checkout/fault; systemctl stop cpuburn 2>/dev/null; echo "fault off";;
  status) systemctl --no-pager status checkout-api checkout-load cpuburn 2>/dev/null | grep -E '●|Active'
          [ -f /etc/checkout/fault ] && echo "FAULT: ON" || echo "FAULT: OFF"
          echo "--- last log lines:"; tail -n 2 $LOG
          echo "--- deadlocks so far:"; grep -c Deadlock $LOG;;
  stop)   systemctl stop checkout-load checkout-api;;
  *) echo "usage: $0 start|inject|seed|reset|status|stop";;
esac
