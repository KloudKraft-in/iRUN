#!/usr/bin/env bash
# load-test.sh - synthetic checkout traffic for NET-D2-203 (Ubuntu twin of load-test.ps1)
# Usage: ./load-test.sh [-r REQUESTS] [-c CONCURRENCY] [-u BASE_URL] [-j]
#   -j  print one JSON line (used by `lab.sh check`)
# Capped at 500 requests / 100 workers so the VM cannot freeze.  Exit 0 = zero failures.
REQ=500; CONC=50; BASE="http://localhost:5100"; JSON=0
while getopts "r:c:u:j" o; do case "$o" in r) REQ="$OPTARG";; c) CONC="$OPTARG";; u) BASE="$OPTARG";; j) JSON=1;; esac; done
[ "$REQ" -gt 500 ] && { echo "WARNING: Requests capped at 500 (VM safety)." >&2; REQ=500; }
[ "$CONC" -gt 100 ] && { echo "WARNING: Concurrency capped at 100 (VM safety)." >&2; CONC=100; }
[ "$CONC" -lt 1 ] && CONC=1
BASE="${BASE%/}"
OUT="$(mktemp)"; trap 'rm -f "$OUT"' EXIT

[ "$JSON" -eq 0 ] && echo "Sending $REQ POST requests to $BASE/api/payments with $CONC concurrent workers ..."
START="$(date +%s.%N)"
seq 1 "$REQ" | xargs -P "$CONC" -I{} sh -c \
  'curl -s -o /dev/null -w "%{http_code} %{time_total}\n" --max-time 60 -X POST -H "Content-Type: application/json" -d "{\"orderId\":$(( {} % 200 + 1 )),\"amount\":19.50}" "$0/api/payments"' "$BASE" >> "$OUT"
END="$(date +%s.%N)"

OK="$(awk '$1==200{n++} END{print n+0}' "$OUT")"
FAILED=$((REQ - OK))
AVG="$(awk '{s+=$2*1000; n++} END{ if(n) printf "%d", s/n; else print 0 }' "$OUT")"
P95="$(cut -d' ' -f2 "$OUT" | sort -n | awk '{a[NR]=$1*1000} END{ if(NR){i=int(NR*0.95); if(i<1)i=1; printf "%d", a[i]} else print 0 }')"
MAX="$(cut -d' ' -f2 "$OUT" | sort -n | awk '{a[NR]=$1*1000} END{ if(NR) printf "%d", a[NR]; else print 0 }')"

if [ "$JSON" -eq 1 ]; then
  printf '{"requests":%s,"success":%s,"failed":%s,"avgMs":%s,"p95Ms":%s,"maxMs":%s}\n' "$REQ" "$OK" "$FAILED" "$AVG" "$P95" "$MAX"
else
  BYSTATUS="$(awk '{c[$1]++} END{for(k in c) printf "HTTP %s: %d   ", k, c[k]}' "$OUT")"
  echo
  printf 'Requests: %s   Concurrency: %s   Elapsed: %.1f s\n' "$REQ" "$CONC" "$(awk -v s="$START" -v e="$END" 'BEGIN{printf "%.1f", e-s}')"
  echo "Success (HTTP 200): $OK"
  echo "Failed: $FAILED   ($BYSTATUS)"
  echo "Latency ms: avg $AVG   p95 $P95   max $MAX"
  if [ "$FAILED" -eq 0 ]; then echo "RESULT: PASS (0 failures)"; else echo "RESULT: FAIL ($FAILED failures - check logs/app.err.log for 'Timeout expired')"; fi
fi
[ "$FAILED" -eq 0 ]
