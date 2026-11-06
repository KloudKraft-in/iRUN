# Day 2: Participant Incident Handbook
## Messaging Systems, Security & Middleware Troubleshooting

> **Your Role:** You are on duty during high-volume enterprise retail operations. A cascade of asynchronous messaging failures, mobile client authentication lockouts, and intermittent payment timeouts have surfaced across the platform. Your goal is to fetch the starter code, reproduce the failures, implement defensive patterns, and verify stability.

---

### Master Setup: Fetch Template Details
- **Local Working Directory:** `middleware_and_apiintegration/day2/` (Windows: `middleware_and_apiintegration\day2\`)

---

## Ticket 1: MIA-D2-201 — "Order Events Flooding the Dead-Letter Queue!"
* **Priority:** P2 (Revenue Impacting - Orders Stalled)
* **Estimated Time:** 60–75 minutes
* **Scenario Path:** `middleware_and_apiintegration/day2/s1/`
* **Starter Artifacts Location:** `middleware_and_apiintegration/day2/s1/starter/`

### Setup: Initialize the Incident
```bash
# Ubuntu / Linux:
cd middleware_and_apiintegration/day2/s1
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day2\s1
.\validation_script.ps1 start
```

###Sceanrio
At 08:45 AM, an alert triggered in the operations center: 60 customer orders were suddenly diverted into the Dead Letter Queue (`orders_dlq.json`). Order processing has ground to a halt. If we simply re-run the consumer, it crashes again because 10 malformed "poison pill" messages are hiding inside the queue.

### What You See When You Start
1. Run `.alidation_script.ps1 start` (Ubuntu: `./validation_script.sh start`).
2. Inspect `starter/orders_dlq.json`. You find 60 messages: 50 are valid orders, but 10 have `"order_id": null` or negative amounts.
3. Running the naive consumer crashes with unhandled exceptions.

### Your Investigation Clues
* **What caused the DLQ flood?**
  A producer submitted 10 malformed JSON records. The existing consumer lacked schema validation, threw an unhandled exception, and rejected the messages with `requeue=False`. The unhandled crashes also stalled downstream processing.
* **Defensive Consumer Programming:**
  A production consumer must **never** crash on invalid data. It must detect invalid schema (`order_id` is null or `total_amount <= 0`), log a critical warning, and quarantine the message permanently without affecting valid orders.

### Your Goal
1. Update consumer logic to validate `order_id` and `total_amount`.
2. Process all 50 legitimate orders into `starter/processed_orders.json`.
3. Permanently isolate the 10 poison pills in `starter/orders_dlq.json`.
4. Empty the primary queue `starter/orders_queue.json` (0 pending).
5. Record your counts and schema rules in `starter/evidence/evidence_D2_1.json`.
6. Run `./validation_script.sh` (or `.\validation_script.ps1`).

---

## Ticket 2: MIA-D2-202 — "Mobile Clients Locked Out with 401 & SSL Handshake Failure!"
* **Priority:** P2 (Mobile Outage)
* **Estimated Time:** 60–75 minutes
* **Scenario Path:** `middleware_and_apiintegration/day2/s2/`
* **Starter Artifacts Location:** `middleware_and_apiintegration/day2/s2/starter/`

### Setup: Initialize the Incident
```bash
# Ubuntu / Linux:
cd middleware_and_apiintegration/day2/s2
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day2\s2
.\validation_script.ps1 start
```

### The Story (In Plain English)
Following an update to our Identity Provider (IdP), mobile users report that login requests return `HTTP 401 Unauthorized`. In addition, direct secure checkout requests to `https://localhost:8443` fail immediately with SSL/TLS handshake failures.

### What You See When You Start
1. Run `.alidation_script.ps1 start` (Ubuntu: `./validation_script.sh start`).
2. Run `python starter/client_simulator.py`. Notice the decoded JWT has `"aud": "retail-web-client"`.
3. Inspect `starter/gateway_auth_config.json`: The gateway only allows `"aud": "mobile-app-v2"`.
4. Check `starter/certs/cert_metadata.json`: The active certificate expired yesterday at midnight!

### Your Investigation Clues
* **JWT Audience Validation:**
  The Identity Provider stamps tokens with an `aud` (audience) claim. When an API Gateway verifies a JWT, it compares the token's `aud` against its whitelist. If they do not match, it returns 401.
* **SSL Certificate Expiration:**
  When a leaf certificate expires, clients reject the TLS handshake (`verify error:num=10:certificate has expired`).

### Your Goal
1. Update `starter/gateway_auth_config.json` to allow both `"retail-web-client"` and `"mobile-app-v2"` with 60s clock skew.
2. Activate the renewed certificate bundle in `starter/certs/cert_metadata.json` (set status to `VALID`).
3. Complete the findings in `starter/evidence/evidence_D2_2.md`.
4. Run `./validation_script.sh` (or `.\validation_script.ps1`).

---

## Ticket 3: MIA-D2-203 — "Intermittent 504 on Checkout & Ghost Orders!"
* **Priority:** P2 (Revenue Impacting - Ghost Order Risk)
* **Estimated Time:** 60–75 minutes
* **Scenario Path:** `middleware_and_apiintegration/day2/s3/`
* **Starter Artifacts Location:** `middleware_and_apiintegration/day2/s3/starter/`

### Setup: Initialize the Incident
```bash
# Ubuntu / Linux:
cd middleware_and_apiintegration/day2/s3
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day2\s3
.\validation_script.ps1 start
```

### The Story (In Plain English)
During high-traffic periods, customers clicking "Place Order" intermittently receive `HTTP 504 Gateway Timeout`. Believing the order failed, customers click "Place Order" again, resulting in double credit card charges. Shockingly, our database shows that the first transaction actually succeeded!

### What You See When You Start
1. Run `.alidation_script.ps1 start` (Ubuntu: `./validation_script.sh start`).
2. Inspect `starter/logs/multi_hop_trace.log` following correlation ID `req-check-99412`:
   - Kong Gateway cut the connection at **3.0s** with **504**.
   - Backend payment processing finished at **5.2s** with **200 OK**.
   - Nginx logged **499** because Kong closed the connection before the backend finished!

### Your Investigation Clues
* **The Golden Rule of Timeout Hierarchies:**
  Client Timeout (30s) > Gateway Timeout (15s) > Web Server Timeout (12s) > Backend SLA (10s).
  *If the outer gateway times out before the backend finishes, ghost transactions are born!*

### Your Goal
1. Realign the timeout hierarchy:
   - In `starter/conf/kong_service.json`, increase `read_timeout` to `15000` (15s).
   - In `starter/conf/checkout_nginx.conf`, set `proxy_read_timeout 12s;`.
2. Complete the formal Incident Escalation & RCA Report in `starter/evidence/evidence_D2_3.md`.
3. Run `./validation_script.sh` (or `.\validation_script.ps1`).
