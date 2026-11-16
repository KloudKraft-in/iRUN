# payment-service structured JSON log generator (TEL-D4-402)
# normal: ~2 INFO/s ; fault (/etc/labs/d4-2/fault present): + ~1.5 ERROR/s ("Gateway timeout") ≈ 90 errors/min
import json, os, random, time, uuid
from datetime import datetime, timezone
LOG = "/var/log/payment/payment.log"; FAULT = "/etc/labs/d4-2/fault"
os.makedirs(os.path.dirname(LOG), exist_ok=True)
def line(level, msg, **kw):
    d = {"timestamp": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
         "level": level, "service": "payment-service", "msg": msg, "txn": "PAY-" + uuid.uuid4().hex[:8], **kw}
    return json.dumps(d)
with open(LOG, "a", buffering=1) as f:
    while True:
        fault = os.path.exists(FAULT)
        f.write(line("INFO", "Payment authorized", amount=round(random.uniform(5, 400), 2), latency_ms=random.randint(80, 400)) + "\n")
        if random.random() < 0.05:
            f.write(line("WARN", "Retrying gateway call", attempt=2, latency_ms=random.randint(900, 1500)) + "\n")
        if fault:
            for _ in range(2):                                   # 2 tries x 0.375 per 0.5 s cycle = 0.75/cycle
                if random.random() < 0.375:                      # => ~1.5 ERROR/s ≈ 90 errors/min
                    f.write(line("ERROR", "Gateway timeout", gateway="stripe", code="GW_TIMEOUT", latency_ms=5000) + "\n")
        time.sleep(0.5)
