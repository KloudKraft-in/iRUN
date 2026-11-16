#!/usr/bin/env bash
# TEL-D4-403 harness:  lab.sh start | check | reset | status | import
L=/opt/labs/D4-3; GF=http://localhost:3000; AUTH="-u admin:Admin@123"; P=http://localhost:9090
import(){ python3 - "$L/dashboard_sre_broken.json" <<'PY' | curl -s $AUTH -X POST "$GF/api/dashboards/db" -H 'Content-Type: application/json' -d @- ; echo
import json,sys; print(json.dumps({"dashboard":json.load(open(sys.argv[1])),"overwrite":True,"folderId":0}))
PY
}
case "$1" in
  import) import;;
  start)  systemctl start shopnow-d4 shopnow-d4-load; docker start d4-prometheus d4-grafana >/dev/null
          import >/dev/null
          echo "SRE dashboard deployed (broken p95 query + truncating service regex) $(date -u +%H:%M:%S) UTC"
          echo "Open http://localhost:3000 -> Dashboards -> ShopNow SRE Dashboard";;
  status) systemctl --no-pager status shopnow-d4 shopnow-d4-load | grep -E '●|Active'
          docker ps --format '{{.Names}}\t{{.Status}}' | grep -E 'd4-(prometheus|grafana)'
          echo "--- services in Prometheus:"; curl -s "$P/api/v1/label/service/values" | python3 -c 'import sys,json;print(" ".join(json.load(sys.stdin)["data"]))';;
  check)  curl -s $AUTH "$GF/api/dashboards/uid/shopnow-sre" > /tmp/d4-3.json
          python3 - /tmp/d4-3.json "$P" <<'PY'
import json,sys,re,urllib.request,urllib.parse
d=json.load(open(sys.argv[1]))["dashboard"]; P=sys.argv[2]; res=[]
def chk(ok,msg): res.append(("PASS" if ok else "FAIL")+"  "+msg)
def prom(q):
    return json.load(urllib.request.urlopen(P+"/api/v1/query?"+urllib.parse.urlencode({"query":q}),timeout=10))["data"]["result"]
panels={p.get("title"):p for p in d.get("panels",[])}
lat=panels.get("P95 Latency"); err=panels.get("Service Error Rate")
le=lat["targets"][0]["expr"] if lat else ""; ee=err["targets"][0]["expr"] if err else ""
n=lambda s: s.replace(" ","").replace("'",'"')
print("      latency: "+le); print("      error  : "+ee)
chk("rate(http_request_duration_seconds_bucket" in n(le), "p95: rate() over bucket counters")
chk("sum(" in n(le) and re.search(r'by\(le(,|\))', n(le)) is not None, "p95: sum ... by (le, ...) preserves buckets")
chk('service=~"$service"' in n(le), "p95: filtered by $service")
chk("rate(http_requests_total" in n(ee) and 'status=~"5.."' in n(ee) and "/" in ee and "*100" in n(ee), "error rate: 5xx rate / total rate * 100")
chk('service=~"$service"' in n(ee), "error rate: filtered by $service")
v=[x for x in d.get("templating",{}).get("list",[]) if x.get("name")=="service"]
rx=v[0].get("regex","") if v else None; print("      variable regex: %r"%rx)
try: names=json.load(urllib.request.urlopen(P+"/api/v1/label/service/values",timeout=10))["data"]
except Exception: names=[]
pat=rx.strip("/") if rx else ""
shown=[]
for s in names:
    m=re.search(pat,s) if pat else None
    if not pat: shown.append(s)
    elif m: shown.append(m.group(1) if m.groups() and m.group(1) is not None else s)  # Grafana uses capture group as value
chk(v and all(s in shown for s in ["order-service","payment-service","inventory-api","notification-service"]), "variable shows all 4 services: %s"%shown)
try:
    r=prom(le.replace("$service",".*"))
    svc=sorted({x["metric"].get("service","?") for x in r})
    chk("rate(" in le and len(r)>0 and all(0<float(x["value"][1])<15 for x in r if x["value"][1]!="NaN"), "repaired p95 evaluates to sane values (%d series, services %s)"%(len(r),svc))
except Exception as ex: chk(False,"p95 query failed: %s"%ex)
print("\n".join(res)); f=sum(x.startswith("FAIL") for x in res)
print("----\nRESULT: %d passed, %d failed"%(len(res)-f,f)); sys.exit(1 if f else 0)
PY
          ;;
  reset)  import >/dev/null; echo "broken SRE dashboard restored";;
  *) echo "usage: $0 start|status|check|reset|import";;
esac
