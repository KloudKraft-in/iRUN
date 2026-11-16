import os, time, json, random, threading, queue
from datetime import datetime, timezone
import newrelic.agent
import psycopg2, psycopg2.pool, requests, urllib3
from flask import Flask, jsonify, Response
from prometheus_client import Histogram, Counter, generate_latest, CONTENT_TYPE_LATEST
urllib3.disable_warnings()

app = Flask(__name__)
POOL_SIZE = 5
FAULT = "/etc/orders/fault"
pool = psycopg2.pool.ThreadedConnectionPool(1, POOL_SIZE, host="localhost", dbname="orders_db", user="app", password="app")
slots = threading.BoundedSemaphore(POOL_SIZE)
LAT = Histogram("checkout_request_duration_seconds", "Checkout latency", ["service", "endpoint"],
                buckets=(.05, .1, .25, .5, 1, 2, 3, 5, 8, 10, 15))
REQ = Counter("checkout_requests_total", "Checkout requests", ["service", "endpoint", "status"])

ES = os.environ.get("ES_URL", "http://localhost:9200")
AUTH = (os.environ.get("ES_USER", "elastic"), os.environ["ES_PASS"]) if os.environ.get("ES_PASS") else None
q = queue.Queue()

def shipper():
    while True:
        batch = [q.get()]
        time.sleep(1)
        while not q.empty() and len(batch) < 500:
            batch.append(q.get())
        body = ""
        for d in batch:
            idx = "ecommerce-logs-" + d["@timestamp"][:10].replace("-", ".")
            body += json.dumps({"index": {"_index": idx}}) + "\n" + json.dumps(d) + "\n"
        try:
            requests.post(ES + "/_bulk", data=body, headers={"Content-Type": "application/x-ndjson"},
                          auth=AUTH, timeout=10, verify=False)
        except Exception as e:
            print("ES ship failed:", e, flush=True)
threading.Thread(target=shipper, daemon=True).start()

def elog(level, msg, **kw):
    d = {"@timestamp": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
         "log": {"level": level}, "service": {"name": "order-service"}, "host": {"name": "prod-worker-02"},
         "message": msg, **kw}
    q.put(d)

@app.post("/api/checkout")
def process_order():
    newrelic.agent.set_transaction_name("CheckoutController#processOrder")
    t0 = time.time(); oid = f"ORD-{random.randint(100000, 999999)}"; status = "200"
    try:
        if not slots.acquire(timeout=5):
            status = "503"
            elog("ERROR", f"Database connection timeout: could not acquire connection from pool 'orders_db' after 5000ms "
                          f"(pool size {POOL_SIZE}, all connections busy)",
                 order={"id": oid}, error={"type": "ConnectionPoolTimeout"}, db={"name": "orders_db"})
            return jsonify(error="db connection timeout"), 503
        try:
            conn = pool.getconn()
            try:
                cur = conn.cursor()
                fault = os.path.exists(FAULT)
                time.sleep(0.6 if fault else 0.02)            # application work
                if fault:
                    cur.execute("SELECT pg_sleep(7.6)")       # simulated table-lock wait in orders_db
                cur.execute("UPDATE orders SET status='PAID', updated_at=now() WHERE id=%s", (random.randint(1, 1000),))
                conn.commit()
            finally:
                pool.putconn(conn)
        finally:
            slots.release()
        elog("INFO", f"Order {oid} processed", order={"id": oid})
        return jsonify(order=oid, status="ok")
    finally:
        LAT.labels("order-service", "/api/checkout").observe(time.time() - t0)
        REQ.labels("order-service", "/api/checkout", status).inc()

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)
