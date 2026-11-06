# Day 1: Participant Incident Handbook
## Middleware Fundamentals, Web Servers & API Gateway

> **Your Role:** You are the on-call platform operations engineer at Apex Cloud Retail. Three high-severity incident tickets have been routed to your on-call queue. Your objective is to navigate to each scenario directory, reproduce the outage, investigate why it occurred using command-line diagnostic tools, resolve the issue, record your evidence, and verify your fix with the automated validation harness.

---

### Master Setup: Fetch Template Details
Before starting any ticket, ensure you are in the scenario directory:

- **Local Working Directory:** `middleware_and_apiintegration/day1/` (Windows: `middleware_and_apiintegration\day1\`)

---

## Ticket 1: MIA-D1-101 — "Tomcat Won't Come Back After a Port Change!"
* **Priority:** P2 (Application is Down)
* **Estimated Time:** 45–60 minutes
* **Scenario Path:** `middleware_and_apiintegration/day1/s1/`
* **Starter Artifacts Location:** `middleware_and_apiintegration/day1/s1/starter/`

### Setup: Initialize the Incident
On your local lab environment, open your terminal and navigate to:
```bash
# Ubuntu / Linux:
cd middleware_and_apiintegration/day1/s1
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day1\s1
.\validation_script.ps1 start
```

### The Story (In Plain English)
During last night's maintenance window, an administrator changed the HTTP connector port in Apache Tomcat's `server.xml` to **port 8082**. Following a reboot, Tomcat refused to start up. The retail store catalog application is completely offline, preventing store cash registers from looking up merchandise prices.

### What You See When You Start
1. Run `.alidation_script.ps1 start` (Ubuntu: `./validation_script.sh start`) to stage the scenario and start the competing process.
2. Check Tomcat's startup log at `starter/logs/catalina.out`.
3. It fails with:
   ```text
   SEVERE [main] org.apache.catalina.util.LifecycleBase.handleSubClassException Failed to initialize component [Connector[HTTP/1.1-8082]]
   Caused by: java.net.BindException: Address already in use: 8082
   ```

### Your Investigation Clues
* **Who is listening on port 8082?**
  Use network diagnostic tools to find the conflicting daemon:
  - **Linux:** `sudo ss -tulpn | grep 8082` (or `lsof -i :8082`)
  - **Windows:** `netstat -ano | findstr 8082`
  *Crucial Rule:* Do **NOT** kill that process! It is a critical legacy synchronization daemon.
* **Why did Tomcat try port 8082?**
  Inspect `starter/conf/server.xml`. Locate the `<Connector port="8082" ... />` directive.
* **Production Best Practice:** Always make a backup copy before editing! Run:
  `cp starter/conf/server.xml starter/conf/server.xml.bak` (Windows: `Copy-Item starter\conf\server.xml starter\conf\server.xml.bak`).

### Your Goal
1. Edit `starter/conf/server.xml` and change the Connector port back to the non-conflicting standard port **8080**.
2. Launch the mock catalog service (simulating Tomcat startup) on port 8080:
   - Linux: `python3 starter/mock_services/catalog_app.py 8080 &`
   - Windows: `Start-Process python -ArgumentList "starter/mock_services/catalog_app.py", "8080" -WindowStyle Hidden`
3. Verify `curl -I http://localhost:8080/catalog` returns `HTTP/1.1 200 OK`.
4. Fill in `starter/evidence/evidence_D1_1.json` with the PID, conflicting port, root cause, and HTTP status code.
5. Run the validation harness:
   - Linux: `./validation_script.sh`
   - Windows: `.\validation_script.ps1`

---

## Ticket 2: MIA-D1-102 — "New Site Behind Nginx Returns 502 Bad Gateway!"
* **Priority:** P2 (Customer Outage)
* **Estimated Time:** 45–60 minutes
* **Scenario Path:** `middleware_and_apiintegration/day1/s2/`
* **Starter Artifacts Location:** `middleware_and_apiintegration/day1/s2/starter/`

### Setup: Initialize the Incident
```bash
# Ubuntu / Linux:
cd middleware_and_apiintegration/day1/s2
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day1\s2
.\validation_script.ps1 start
```

### The Story (In Plain English)
The marketing team launched a nationwide promotional campaign with a custom URL `/promo`. However, every customer attempting to access the site receives an immediate **HTTP 502 Bad Gateway** error. Web traffic is routed through an Nginx reverse proxy.

### What You See When You Start
1. Run `.alidation_script.ps1 start` (Ubuntu: `./validation_script.sh start`).
2. Inspect Nginx error logs at `starter/logs/error.log`.
3. You observe:
   ```text
   connect() failed (111: Connection refused) while connecting to upstream: "http://127.0.0.1:9090/promo"
   ```

### Your Investigation Clues
* **What does 502 Bad Gateway mean?**
  Nginx acts as a reverse proxy. When a client visits `/promo`, Nginx forwards the request upstream. A 502 error means the upstream server refused the connection or is completely dead.
* **Where is the promotional backend actually running?**
  Run socket tools (`ss -tulpn` or `netstat -ano`) to check port listeners. Notice that the promotional microservice is actually listening on port **8080**, NOT port **9090**!
* **What is missing in `starter/conf.d/retail_promo.conf`?**
  The `proxy_pass` points to `9090`. In addition, standard proxy client IP headers (`X-Real-IP`, `X-Forwarded-For`) were omitted.

### Your Goal
1. Update `starter/conf.d/retail_promo.conf` so `proxy_pass` targets `http://127.0.0.1:8080`.
2. Include the required forwarding headers:
   ```nginx
   proxy_set_header Host $host;
   proxy_set_header X-Real-IP $remote_addr;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header X-Forwarded-Proto $scheme;
   ```
3. Test that `curl -i http://127.0.0.1:8080/promo` returns `HTTP 200 OK`.
4. Complete the analysis in `starter/evidence/evidence_D1_2.md`.
5. Run the validation harness:
   - Linux: `./validation_script.sh`
   - Windows: `.\validation_script.ps1`

---

## Ticket 3: MIA-D1-103 — "Partner Logistics API Returns 404 & Lacks Protection!"
* **Priority:** P3 (Pre-Production Go-Live Blocker)
* **Estimated Time:** 45–60 minutes
* **Scenario Path:** `middleware_and_apiintegration/day1/s3/`
* **Starter Artifacts Location:** `middleware_and_apiintegration/day1/s3/starter/`

### Setup: Initialize the Incident
```bash
# Ubuntu / Linux:
cd middleware_and_apiintegration/day1/s3
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day1\s3
.\validation_script.ps1 start
```

### The Story (In Plain English)
A third-party regional logistics partner is attempting to test our inventory endpoint ahead of a Friday release. When they send requests to `http://localhost:8000/api/v1/inventory`, Kong API Gateway turns them away with `HTTP 404 Not Found` (`{"message":"no Route matched with those values"}`). Furthermore, security audit flagged that the route lacks API key authentication and has no rate limiting.

### What You See When You Start
1. Run `.alidation_script.ps1 start` (Ubuntu: `./validation_script.sh start`).
2. Test request: `curl -i http://localhost:8000/api/v1/inventory`.
3. Kong returns: `HTTP 404 Not Found` with message `no Route matched with those values`.

### Your Investigation Clues
* **Why did Kong return 404?**
  Query Kong's Admin API: `curl -s http://localhost:8001/routes`.
  Notice that the registered path is `['/v1/inventory']`, but incoming clients request `['/api/v1/inventory']`!
* **Securing the Endpoint:**
  Kong Gateway uses plugins. Enable the `key-auth` plugin on `inventory-service`, create consumer `partner-logistics`, and generate key `LogisticsSecretKey2026`.
* **Rate Limiting:**
  Enable the `rate-limiting` plugin with a limit of `5` requests per minute.

### Your Goal
1. Update Kong Gateway route path to `/api/v1/inventory`:
   ```bash
   curl -X PATCH http://localhost:8001/routes/inventory-route -d "paths[]=/api/v1/inventory" -d "strip_path=false"
   ```
2. Enable `key-auth` plugin on the service, create consumer `partner-logistics`, and assign key `LogisticsSecretKey2026`.
3. Attach `rate-limiting` plugin (5 req/min, local policy).
4. Verify HTTP error classification:
   - No Key -> `401 Unauthorized`
   - Invalid Key -> `403 Forbidden`
   - Valid Key -> `200 OK`
   - 6th Call within a minute -> `429 Too Many Requests`
5. Complete the matrix in `starter/evidence/evidence_D1_3.md`.
6. Run `./validation_script.sh` (or `.\validation_script.ps1`).
