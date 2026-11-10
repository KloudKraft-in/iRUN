# Middleware & API Integration - Participant Lab Guide: Day 2

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines
### Messaging Systems, Security & Middleware Troubleshooting

---

## 1. Module-Wise Setup Requirements

All lab scenarios are designed to run natively on your training VM or local workstation. Ensure the following tools and prerequisites are in place before starting.

### System Hardware & Operating System

- **Operating System:** Ubuntu 20.04 / 22.04 / 24.04 LTS, Windows 10 / 11, or macOS.  
- **Hardware Allocation:** Minimum 4 vCPU, 8 GB RAM, 25 GB free disk space.  
- **IDE / Editor:** Visual Studio Code (recommended) or any modern text editor.

### Required Software & Toolchain

| Component | Supported Version | Verification Command | Purpose |
| :--- | :--- | :--- | :--- |
| **Python Runtime** | Python 3.8+ | `python --version` or `python3 --version` | Queue consumers, mock gateways, cert generators, client simulators |
| **Network Tools** | curl, ss / netstat, lsof | `curl --version` | API testing, HTTP REST requests, port verification |
| **OpenSSL / PKI** | OpenSSL 1.1.1 or 3.0+ | `openssl version` | TLS/SSL certificate inspection, expiration checks |
| **Nginx Web Server** | Nginx 1.18+ | `nginx -v` | Reverse proxy timeout configuration & upstream buffering |
| **Kong API Gateway** | Kong Gateway 3.x | `curl http://localhost:8001/status` | Microservice timeout policies & routing |
| **Version Control** | Git 2.30+ | `git --version` | Source control, starter artifact retrieval |

### Port Allocation & Reservation

Ensure the following ports are unoccupied before launching exercises:

- `8084`: Checkout Nginx Reverse Proxy (Day 2 Scenario 3)  
- `8085`: Slow Checkout Backend Microservice (Day 2 Scenario 3)  
- `8443`: Secure Authentication & Mock SSL Gateway (Day 2 Scenario 2)  
- `8000`: Kong API Gateway Proxy Port (Day 2 Scenario 3 multi-tier trace)

---

## 2. Common Instructions for Trainers and Participants

### Standard Lab Workflow

Every scenario in this training follows a rigorous **Simulation & Troubleshooting Cycle**:

```
[1. Fetch Template / Clone Repo] ──> [2. Open in VS Code] ──> [3. Stage Incident & Run Validation]
                                                                        │
                                                                        ▼
[6. Verify & Submit Evidence]   <── [5. Apply Solve Steps]  <── [4. Observe Expected Failure]
                                                                    (Check Guidelines)
```

1. **Artifact Distribution & Setup**:  
   - Clone the course repository to your workspace.  
   - Navigate to the designated scenario folder (`middleware_and_apiintegration/day2/s1`, `s2`, or `s3`).  
   - Launch **Visual Studio Code** and select **File -> Open Folder...** pointing to the scenario root.  
2. **Execute Initial Validation Script / Stage Scenario**:  
   - In the integrated terminal, execute the scenario staging command (`./validation_script.sh start` on Linux or `.\validation_script.ps1 start` on Windows).  
3. **The Expected Failure Principle**:  
   - **Crucial Note:** Every scenario is intentionally provided in a broken, misconfigured, or incomplete starter state.  
   - You **MUST** run the initial test and observe the **Expected Failure** before altering any code or configuration!  
   - Examples of expected failures include: *Dead Letter Queue flood & unhandled consumer crash*, *HTTP 401 Unauthorized & SSL handshake failure*, or *HTTP 504 Gateway Timeout causing ghost double-charging*.  
4. **Troubleshooting & Investigation**:  
   - Read the console logs, exception stack traces, and HTTP error codes.  
   - Consult the **Step-by-Step Investigation Guidelines** in this guide.  
5. **Implement the Solution (Solve)**:  
   - Apply defensive consumer checks, token audience policies, TLS certificate renewals, or timeout hierarchy alignments based on the guidelines.  
6. **Re-Test & Self-Validate**:  
   - Re-run the validation script (`./validation_script.sh check` or `.\validation_script.ps1 check`) to confirm all checks pass.  
   - Record your findings and diagnostic outputs in the scenario evidence file.

---

## 3. Day 2: Messaging Systems, Security & Middleware Troubleshooting

### Scenario MIA-D2-201: Message Broker DLQ Flood Recovery

- **Ticket ID:** `MIA-D2-201` | **Category:** Message Broker Operations & Defensive Consumers | **Suggested Time:** 60–75 mins  
- **Starter Artifacts Location:** `middleware_and_apiintegration/day2/s1/starter/`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/middleware_and_apiintegration/day2/s1` to fetch boilerplate code

#### Setup: Initialize the Incident

```sh
# Ubuntu / Linux:
cd middleware_and_apiintegration/day2/s1
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day2\s1
.\validation_script.ps1 start
```

#### The Story

At 08:45 AM, an alert triggered in the operations center: 60 customer orders were suddenly diverted into the Dead Letter Queue (`orders_dlq.json`). Order processing has ground to a halt. If we simply re-run the consumer, it crashes again because 10 malformed "poison pill" messages are hiding inside the queue.

#### A. Expected Failure (Reproduction Steps)

1. Run the scenario staging script:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Inspect `starter/orders_dlq.json`. You find 60 messages: 50 are legitimate customer orders, but 10 contain `"order_id": null` or negative/zero amounts.
3. Attempt to run the naive consumer against the messages:
   ```sh
   python starter/order_consumer.py
   ```
4. **Observed Error:** The consumer throws an unhandled exception on corrupt records:
   ```text
   ValueError: Corrupt payload detected: {'order_id': None, 'customer_id': 'CUST-ERR-2', 'total_amount': -10.0, 'items_count': 0, 'is_poison_pill': True}
   [ERROR] FATAL CONSUMER CRASH -> Rejecting message to DLQ
   ```

*Why this fails:* The legacy consumer lacked defensive schema validation. When malformed payloads arrived, it crashed and issued a blanket `basic_reject(requeue=False)`, which caused valid orders to be dumped into the DLQ alongside the poison pills.

#### B. Step-by-Step Investigation Guidelines

- **Analyze the DLQ payloads:** Open `starter/orders_dlq.json` and examine the structure of both valid orders and poison pills. Notice:
  - Legitimate orders have valid strings like `"order_id": "ORD-2026-1001"` and positive `total_amount > 0`.
  - Poison pills have `order_id == null` or negative/zero `total_amount <= 0`.
- **Understand Defensive Consumer Patterns:**
  - A production consumer must **never** crash on invalid data.
  - It must perform defensive schema checks before processing. If validation fails, it must quarantine the poison pill permanently into the DLQ and proceed with valid records.
- **Inspect `replay_dlq.py`:** Use or complete `replay_dlq.py` to separate and replay legitimate orders while permanently isolating the poison pills.

#### C. Action Items to Solve

1. Update the consumer / replay logic to defensively validate `order_id` (must not be `None` or empty) and `total_amount` (must be `> 0`).  
2. Process all **50 legitimate orders** into `starter/processed_orders.json`.  
3. Permanently isolate the **10 poison pills** in `starter/orders_dlq.json`.  
4. Ensure the primary queue `starter/orders_queue.json` is completely drained (`0` pending records).  
5. Record your counts and schema rules in `starter/evidence/evidence_D2_1.json`.  
6. Run the validation harness:  
   - Linux: `./validation_script.sh check`  
   - Windows: `.\validation_script.ps1 check`

---

### Scenario MIA-D2-202: JWT Audience & SSL Certificate Repair

- **Ticket ID:** `MIA-D2-202` | **Category:** API Security, JWT & PKI Certificate Management | **Suggested Time:** 60–75 mins  
- **Starter Artifacts Location:** `middleware_and_apiintegration/day2/s2/starter/`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/middleware_and_apiintegration/day2/s2` to fetch boilerplate code

#### Setup: Initialize the Incident

```sh
# Ubuntu / Linux:
cd middleware_and_apiintegration/day2/s2
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day2\s2
.\validation_script.ps1 start
```

#### The Story

Following an update to our Identity Provider (IdP), mobile users report that login requests return `HTTP 401 Unauthorized`. In addition, direct secure checkout requests to `https://localhost:8443` fail immediately with SSL/TLS handshake failures.

#### A. Expected Failure (Reproduction Steps)

1. Run the scenario staging script:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Run the client simulator:
   ```sh
   python starter/client_simulator.py
   ```
   Notice that the decoded JWT payload contains `"aud": "retail-web-client"`.
3. Inspect `starter/gateway_auth_config.json`:
   ```json
   {
     "allowed_audiences": ["mobile-app-v2"],
     "clock_skew": 0
   }
   ```
4. Attempt to send an authenticated request with the generated token:
   ```sh
   curl -i -H "Authorization: Bearer <TOKEN>" http://localhost:8443
   ```
5. **Observed Errors:**
   - JWT Audience Mismatch: Gateway rejects token with `HTTP 401 Unauthorized` because `"retail-web-client"` is not in `allowed_audiences`.
   - In `starter/certs/cert_metadata.json`, the active certificate status is `"EXPIRED"` (`not_after` expired yesterday).

*Why this fails:* Two independent security failures occurred simultaneously: the Identity Provider updated token audience claims without gateway configuration alignment, and the gateway's active TLS leaf certificate expired.

#### B. Step-by-Step Investigation Guidelines

- **JWT Audience Validation:** The IdP stamps tokens with an `aud` (audience) claim. When an API Gateway verifies a JWT, it compares the token's `aud` against its whitelist. If they do not match, it returns 401.
- **SSL Certificate Lifecycle:** Inspect `starter/certs/cert_metadata.json`. Notice the `active` block has `"status": "EXPIRED"`, while a `renewed` block with `"status": "VALID"` is available.
- **Clock Skew Tolerances:** Distributed systems require clock skew tolerance (e.g., 60 seconds) to account for slight NTP drift between the authentication server and API gateways.

#### C. Action Items to Solve

1. Update `starter/gateway_auth_config.json` to allow both `"retail-web-client"` and `"mobile-app-v2"` with a 60-second clock skew:
   ```json
   {
     "allowed_audiences": ["retail-web-client", "mobile-app-v2"],
     "clock_skew": 60
   }
   ```
2. Activate the renewed certificate bundle in `starter/certs/cert_metadata.json`: set the `active` certificate status to `"VALID"` with the renewed expiration and serial number.  
3. Complete the findings in `starter/evidence/evidence_D2_2.md`.  
4. Run the validation harness:  
   - Linux: `./validation_script.sh check`  
   - Windows: `.\validation_script.ps1 check`

---

### Scenario MIA-D2-203: Distributed Timeout Hierarchy & Escalation Report

- **Ticket ID:** `MIA-D2-203` | **Category:** Distributed Timeout Hierarchies & Resiliency | **Suggested Time:** 60–75 mins  
- **Starter Artifacts Location:** `middleware_and_apiintegration/day2/s3/starter/`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/middleware_and_apiintegration/day2/s3` to fetch boilerplate code

#### Setup: Initialize the Incident

```sh
# Ubuntu / Linux:
cd middleware_and_apiintegration/day2/s3
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day2\s3
.\validation_script.ps1 start
```

#### The Story

During high-traffic periods, customers clicking "Place Order" intermittently receive `HTTP 504 Gateway Timeout`. Believing the order failed, customers click "Place Order" again, resulting in duplicate credit card charges. Shockingly, our database shows that the first transaction actually succeeded!

#### A. Expected Failure (Reproduction Steps)

1. Run the scenario staging script:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Inspect the multi-tier correlated log file at `starter/logs/multi_hop_trace.log` following correlation ID `req-check-99412`:
3. **Observed Error Trace:**
   - **Hop 1 (Kong Gateway):** Cut the connection at **3.0s** with `HTTP 504 Gateway Timeout`.
   - **Hop 2 (Nginx Reverse Proxy):** Logged `HTTP 499` at **5.2s** because the client (Kong) closed the connection prematurely.
   - **Hop 3 (Payment Engine):** Successfully completed payment at **5.18s** with `HTTP 200 OK` (TXN-884129).

*Why this fails:* The timeout hierarchy is inverted! Kong Gateway's `read_timeout` was configured to 3.0 seconds, while legitimate payment transactions require up to 5.2 seconds. Kong terminated the client request before the downstream payment processing completed, causing ghost transactions.

#### B. Step-by-Step Investigation Guidelines

- **The Golden Rule of Timeout Hierarchies:**
  ```text
  Client Timeout (30s) > Gateway Timeout (15s) > Web Server Timeout (12s) > Backend SLA (10s)
  ```
  *If an outer gateway times out before the inner backend finishes processing, ghost transactions are created!*
- **Inspect Kong configuration:** Inspect `starter/conf/kong_service.json`. Locate `"read_timeout": 3000` (3000ms = 3.0s).
- **Inspect Nginx configuration:** Inspect `starter/conf/checkout_nginx.conf`. Locate `proxy_read_timeout 10s;`.

#### C. Action Items to Solve

1. Realign the timeout hierarchy across tiers:  
   - In `starter/conf/kong_service.json`, increase `read_timeout` to `15000` (15 seconds / 15,000 ms).  
   - In `starter/conf/checkout_nginx.conf`, increase `proxy_read_timeout` to `12s;`.  
2. Complete the formal Incident Escalation & RCA Report in `starter/evidence/evidence_D2_3.md`.  
3. Run the validation harness:  
   - Linux: `./validation_script.sh check`  
   - Windows: `.\validation_script.ps1 check`
