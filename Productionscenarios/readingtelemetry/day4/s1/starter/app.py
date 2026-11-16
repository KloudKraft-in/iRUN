# ShopNow-Production simulator (TEL-D4-401): New Relic APM + Prometheus metrics
import random, time
import newrelic.agent
from flask import Flask, jsonify, Response
from prometheus_client import Histogram, Counter, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)
BUCKETS = (.05, .1, .25, .5, .75, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 7.5, 10)
LAT = Histogram("http_request_duration_seconds", "HTTP request latency", ["service", "handler", "method"], buckets=BUCKETS)
REQ = Counter("http_requests_total", "HTTP requests", ["service", "handler", "method", "status"])

class PaymentGatewayTimeoutError(Exception): pass
class InventoryReservationError(Exception): pass
class SmtpRelayError(Exception): pass

# name: (service, latency sampler, error rate, exception)
def mix(fast, slow, p_slow):          # bimodal latency: (lo,hi) fast band, (lo,hi) slow tail
    return lambda: random.uniform(*slow) if random.random() < p_slow else random.uniform(*fast)
TX = {
  "CheckoutController#processPayment":       ("payment-service",      mix((0.6, 2.8), (3.9, 4.5), 0.10), 0.06, PaymentGatewayTimeoutError),
  "OrderController#createOrder":             ("order-service",        mix((0.3, 1.4), (1.9, 2.3), 0.10), 0.02, InventoryReservationError),
  "InventoryController#reserveStock":        ("inventory-api",        mix((0.1, 0.8), (1.0, 1.4), 0.10), 0.03, InventoryReservationError),
  "NotificationController#sendConfirmation": ("notification-service", mix((0.05, 0.5), (0.7, 0.9), 0.10), 0.01, SmtpRelayError),
  "PaymentController#refund":                ("payment-service",      mix((0.05, 0.3), (0.45, 0.6), 0.10), 0.00, None),
  "OrderController#getOrderStatus":          ("order-service",        mix((0.01, 0.15), (0.2, 0.3), 0.10), 0.00, None),
}

def handle(name):
    service, sampler, err_rate, exc = TX[name]
    newrelic.agent.set_transaction_name(name)
    newrelic.agent.add_custom_attribute("service", service)
    t0 = time.time(); status = "200"
    try:
        time.sleep(sampler())
        if exc and random.random() < err_rate:
            status = "500"
            try:
                raise exc(f"{name} failed")
            except Exception:
                newrelic.agent.notice_error()       # -> TransactionError event, error.class = module:ClassName
            return jsonify(error=exc.__name__), 500
        return jsonify(tx=name, status="ok")
    finally:
        LAT.labels(service, name, "POST").observe(time.time() - t0)
        REQ.labels(service, name, "POST", status).inc()

@app.post("/tx/<path:name>")
def tx(name):
    return handle(name)

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)
