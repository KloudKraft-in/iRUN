import json, logging, random, os, itertools, threading
from datetime import datetime, timezone
import psycopg2
from flask import Flask, jsonify, request
from ddtrace import tracer

app = Flask(__name__)
HOST = "prod-worker-02"
log = logging.getLogger("checkout"); log.setLevel(logging.INFO)
h = logging.FileHandler("/var/log/checkout/checkout.json"); h.setFormatter(logging.Formatter("%(message)s")); log.addHandler(h)
_counter = itertools.count(90001); _lock = threading.Lock()

def jlog(level, msg, **kw):
    rec = {"timestamp": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
           "level": level, "host": HOST, "service": "checkout-api", "message": msg, **kw}
    span = tracer.current_span()
    if span:
        span.set_tag("transaction_id", kw.get("transaction_id"))
        rec["dd.trace_id"] = str(span.trace_id & 0xFFFFFFFFFFFFFFFF)
        rec["dd.span_id"] = str(span.span_id)
    log.info(json.dumps(rec))

@app.post("/checkout")
def checkout():
    # optional overrides used by the "seed" command to reproduce TXN-88129-CORR
    txn = request.args.get("txn")
    if txn is None:
        with _lock: txn = next(_counter)
    order = request.args.get("order")
    items = list(order) if order else ["A", "B"]
    if not order and os.path.exists("/etc/checkout/fault"): random.shuffle(items)
    hold = float(request.args.get("hold", "0.2"))
    tid = f"TXN-{txn}-CORR"
    conn = psycopg2.connect(host="localhost", dbname="orders", user="app", password="app")
    try:
        cur = conn.cursor()
        cur.execute("UPDATE inventory SET qty=qty-1 WHERE id=%s", (items[0],))
        cur.execute("SELECT pg_sleep(%s)", (hold,))
        cur.execute("UPDATE inventory SET qty=qty-1 WHERE id=%s", (items[1],))
        conn.commit()
        jlog("INFO", f"Order committed: Transaction ID {txn}", transaction_id=tid)
        return jsonify(transaction_id=tid, status="ok")
    except psycopg2.errors.DeadlockDetected as e:
        conn.rollback()
        jlog("ERROR", f"Deadlock victim: Transaction ID {txn}", transaction_id=tid,
             error_code="DB_DEADLOCK_40P01", error_msg=str(e).splitlines()[0], db="sql-orders")
        return jsonify(transaction_id=tid, error="deadlock"), 500
    finally:
        conn.close()
