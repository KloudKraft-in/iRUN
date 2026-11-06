# Day 2: Instructor Solution & Mentor Reference Guide
## Messaging Systems, Security & Middleware Troubleshooting (Confidential)

> **Instructor Note:** Do not distribute this guide to participants. It contains exact root causes, one-line patches, grading rubrics, and reference terminal commands.

---

## Ticket MIA-D2-201: Message Broker DLQ Flood Recovery (CO-04)
* **Root Cause:** A batch of 10 malformed messages pushed into `orders_queue` had missing required fields (`order_id: null` or negative amounts). Naive consumer crashed, issuing `basic_reject(requeue=False)` which diverted legitimate orders into the DLQ alongside poison pills.
* **Resolution Steps:**
  1. Add defensive checks: `if not order_id or total_amount <= 0: quarantine_to_dlq() else: process_order()`.
  2. Replay messages from DLQ.
* **Target Output:** 50 processed orders in `processed_orders.json`, 10 quarantined poison pills in `orders_dlq.json`, primary queue at 0.
* **Grading Rubric:** Identified poison pill structure (25%), defensive validation implemented (25%), queue targets reached (25%), evidence filled (25%).

---

## Ticket MIA-D2-202: JWT Audience & SSL Certificate Repair (CO-05)
* **Root Cause:**
  - JWT: IdP token issued with `"aud": "retail-web-client"`, but Kong enforced `aud = mobile-app-v2`.
  - SSL: Certificate on port 8443 expired (`verify error:num=10:certificate has expired`).
* **Resolution Steps:**
  1. Update `gateway_auth_config.json`: set `"allowed_audiences": ["retail-web-client", "mobile-app-v2"]` with `clock_skew=60`.
  2. In `certs/cert_metadata.json`, update `active` certificate to renewed bundle (set status to `VALID`).
* **Grading Rubric:** Audience mismatch identified (25%), gateway config patched (25%), SSL certificate renewed (25%), evidence filled (25%).

---

## Ticket MIA-D2-203: Distributed Timeout Hierarchy & Escalation Report (CO-06)
* **Root Cause:** Inverted timeout hierarchy: Kong Gateway `read_timeout` was 3.0s, while backend payment processing took 5.2s. Kong disconnected client with 504 while backend completed charge (ghost transactions).
* **Golden Rule:** Client (30s) > Kong (15s) > Nginx (12s) > Backend (10s).
* **Resolution Steps:**
  1. In `conf/kong_service.json`, set `read_timeout: 15000` (15s).
  2. In `conf/checkout_nginx.conf`, set `proxy_read_timeout 12s;`.
  3. Complete RCA table in `starter/evidence/evidence_D2_3.md`.
* **Grading Rubric:** Inverted timeout identified (25%), Kong timeout updated (25%), Nginx timeout updated (25%), RCA evidence table completed (25%).
