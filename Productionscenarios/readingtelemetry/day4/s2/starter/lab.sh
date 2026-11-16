#!/usr/bin/env bash
# TEL-D4-402 harness:  lab.sh start | check | reset | status | import
L=/opt/labs/D4-2; GF=http://localhost:3000; AUTH="-u admin:Admin@123"; LOKI=http://localhost:3100
import(){ python3 - "$L/dashboard_broken.json" <<'PY' | curl -s $AUTH -X POST "$GF/api/dashboards/db" -H 'Content-Type: application/json' -d @- ; echo
import json,sys; print(json.dumps({"dashboard":json.load(open(sys.argv[1])),"overwrite":True,"folderId":0}))
PY
}
case "$1" in
  import) import;;
  start)  systemctl start payment-logger; docker start d4-loki d4-promtail d4-grafana >/dev/null
          touch /etc/labs/d4-2/fault; import >/dev/null
          echo "OUTAGE STARTED $(date -u +%H:%M:%S) UTC: payment-service emitting ~90 ERROR logs/min ('Gateway timeout')"
          echo "Open http://localhost:3000 -> Dashboards -> Payment Dashboard";;
  status) systemctl --no-pager status payment-logger | grep -E '●|Active'
          docker ps --format '{{.Names}}\t{{.Status}}' | grep -E 'd4-'
          [ -f /etc/labs/d4-2/fault ] && echo "OUTAGE: ON" || echo "OUTAGE: OFF"
          echo "--- last 2 log lines:"; tail -n 2 /var/log/payment/payment.log;;
  check)  ok=0; fail=0; pass(){ echo "PASS  $1"; ok=$((ok+1)); }; bad(){ echo "FAIL  $1"; fail=$((fail+1)); }
          curl -s $AUTH "$GF/api/dashboards/uid/payment-dashboard" > /tmp/d4-2.json
          python3 - /tmp/d4-2.json "$LOKI" <<'PY'
import json,sys,urllib.request,urllib.parse,re
d=json.load(open(sys.argv[1]))["dashboard"]; loki=sys.argv[2]
p=[x for x in d["panels"] if x.get("title")=="Payment Error Volume"]
res=[]
def chk(ok,msg): res.append(("PASS" if ok else "FAIL")+"  "+msg)
chk(bool(p),"panel 'Payment Error Volume' present")
if p:
    p=p[0]; e=p["targets"][0]["expr"]; print("      expr: "+e)
    chk('|= "error"' not in e and "|= 'error'" not in e, "naive |= \"error\" line filter removed")
    chk("| json" in e, "json parser stage used")
    chk('level="ERROR"' in e.replace(" ","") or 'level=~"(?i)error"' in e.replace(" ",""), "level = \"ERROR\" label filter")
    chk("rate(" in e or "count_over_time(" in e, "metric function rate()/count_over_time()")
    steps=p.get("fieldConfig",{}).get("defaults",{}).get("thresholds",{}).get("steps",[])
    vals=sorted([s.get("value") for s in steps if s.get("value") is not None])
    cols=[s.get("color") for s in sorted(steps,key=lambda s:-1 if s.get("value") is None else s["value"])]
    print("      thresholds: "+str([(s.get('color'),s.get('value')) for s in steps]))
    chk(vals==[5,20] and cols and cols[0]=="green" and cols[-1]=="red", "thresholds Green<5, Yellow>=5, Red>=20")
    q=urllib.parse.urlencode({"query":e})
    try:
        r=json.load(urllib.request.urlopen(loki+"/loki/api/v1/query?"+q,timeout=10))["data"]["result"]
        v=float(r[0]["value"][1]) if r else 0
        chk(v>0, "repaired query returns live errors now (value=%.2f)"%v)
    except Exception as ex: chk(False,"Loki query failed: %s"%ex)
print("\n".join(res)); f=sum(r.startswith("FAIL") for r in res)
print("----\nRESULT: %d passed, %d failed"%(len(res)-f,f)); sys.exit(1 if f else 0)
PY
          ;;
  reset)  rm -f /etc/labs/d4-2/fault; import >/dev/null; echo "outage stopped; broken dashboard restored";;
  *) echo "usage: $0 start|status|check|reset|import";;
esac
