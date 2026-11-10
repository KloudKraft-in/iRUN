# Middleware & API Integration - Participant Lab Guide: Day 1

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines
### Middleware Fundamentals, Web Servers & API Gateway

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
| **Python Runtime** | Python 3.8+ | `python --version` or `python3 --version` | Mock services, validation harnesses, client simulations |
| **Network Tools** | curl, ss / netstat, lsof | `curl --version` | API testing, HTTP REST inspection, port verification |
| **Apache Tomcat** | Tomcat 10.1 (Jakarta EE 10) | `catalina.sh version` or inspecting `server.xml` | Web application server configuration & connector bindings |
| **Nginx Web Server** | Nginx 1.18+ | `nginx -v` | Reverse proxy, upstream routing, client IP header preservation |
| **Kong API Gateway** | Kong Gateway 3.x (Admin/Proxy) | `curl http://localhost:8001/status` | Declarative routing, API key security, rate limiting |
| **Version Control** | Git 2.30+ | `git --version` | Source control, starter artifact retrieval |

### Port Allocation & Reservation

Ensure the following ports are unoccupied before launching exercises:

- `8000`: Kong API Gateway Proxy Port (Day 1 Scenario 3)  
- `8001`: Kong API Gateway Admin API Port (Day 1 Scenario 3)  
- `8080`: Primary Catalog Service (Day 1 Scenario 1) / Promotional Backend (Day 1 Scenario 2)  
- `8081`: Inventory Backend Service (Day 1 Scenario 3)  
- `8082`: Conflicting Legacy Synchronization Daemon (Day 1 Scenario 1)  
- `9090`: Unreachable / Dead Port in broken Nginx proxy config (Day 1 Scenario 2)

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
   - Navigate to the designated scenario folder (`middleware_and_apiintegration/day1/s1`, `s2`, or `s3`).  
   - Launch **Visual Studio Code** and select **File -> Open Folder...** pointing to the scenario root.  
2. **Execute Initial Validation Script / Stage Scenario**:  
   - In the integrated terminal, execute the scenario staging command (`./validation_script.sh start` on Linux or `.\validation_script.ps1 start` on Windows).  
3. **The Expected Failure Principle**:  
   - **Crucial Note:** Every scenario is intentionally provided in a broken, misconfigured, or incomplete starter state.  
   - You **MUST** run the initial test and observe the **Expected Failure** before altering any code or configuration!  
   - Examples of expected failures include: *Port collision (8082 already bound by legacy daemon)*, *HTTP 502 Bad Gateway (upstream pointing to dead port 9090)*, or *HTTP 404 Not Found & missing security (Kong route mismatch)*.  
4. **Troubleshooting & Investigation**:  
   - Read the console logs, exception stack traces, and HTTP error codes.  
   - Consult the **Step-by-Step Investigation Guidelines** in this guide.  
5. **Implement the Solution (Solve)**:  
   - Apply the required configuration edits, headers, or API updates based on the guidelines.  
6. **Re-Test & Self-Validate**:  
   - Re-run the validation script (`./validation_script.sh check` or `.\validation_script.ps1 check`) to confirm all checks pass.  
   - Record your findings and diagnostic outputs in the scenario evidence file.

---

## 3. Day 1: Middleware Fundamentals, Web Servers & API Gateway

### Scenario MIA-D1-101: Tomcat Port Collision Recovery

- **Ticket ID:** `MIA-D1-101` | **Category:** Middleware Operations & Web Servers | **Suggested Time:** 45–60 mins  
- **Starter Artifacts Location:** `middleware_and_apiintegration/day1/s1/starter/`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/middleware_and_apiintegration/day1/s1` to fetch boilerplate code

#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd middleware_and_apiintegration/day1/s1
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day1\s1
.\validation_script.ps1 start
```

#### The Story

During last night's maintenance window, an administrator changed the HTTP connector port in Apache Tomcat's `server.xml` to **port 8082**. Following a reboot, Tomcat refused to start up. The retail store catalog application is completely offline, preventing store cash registers from looking up merchandise prices.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Check Tomcat's startup log at `starter/logs/catalina.out`.
3. **Observed Error:** Tomcat fails to bind and crashes with:

```text
SEVERE [main] org.apache.catalina.util.LifecycleBase.handleSubClassException Failed to initialize component [Connector[HTTP/1.1-8082]]
Caused by: java.net.BindException: Address already in use: 8082
    at java.base/sun.nio.ch.Net.bind0(Native Method)
    at org.apache.tomcat.util.net.NioEndpoint.initServerSocket(NioEndpoint.java:229)
    at org.apache.tomcat.util.net.NioEndpoint.bind(NioEndpoint.java:204)
```

*Why this fails:* Port 8082 is already occupied by a critical legacy synchronization daemon. Tomcat's HTTP connector was pointed directly at this occupied port.

#### B. Step-by-Step Investigation Guidelines

- **Identify the competing process:** Use network socket diagnostic tools to find what is listening on port 8082:
  - Linux: `sudo ss -tulpn | grep 8082` or `lsof -i :8082`
  - Windows: `netstat -ano | findstr 8082`
  - *Crucial Rule:* Do **NOT** kill that process! It is a critical legacy synchronization daemon.
- **Inspect Tomcat configuration:** Inspect `starter/conf/server.xml` around line 11. Locate the `<Connector port="8082" ... />` directive.
- **Production Best Practice:** Always make a backup copy before editing! Run:
  - Linux: `cp starter/conf/server.xml starter/conf/server.xml.bak`
  - Windows: `Copy-Item starter\conf\server.xml starter\conf\server.xml.bak`

#### C. Action Items to Solve

1. Create a backup file `starter/conf/server.xml.bak`.  
2. Edit `starter/conf/server.xml` and change the Connector port back to the non-conflicting standard port **8080**:
   ```xml
   <Connector port="8080" protocol="HTTP/1.1"
              connectionTimeout="20000"
              redirectPort="8443" />
   ```
3. Launch the mock catalog service (simulating Tomcat startup) on port 8080:  
   - Linux: `python3 starter/mock_services/catalog_app.py 8080 &`  
   - Windows: `Start-Process python -ArgumentList "starter/mock_services/catalog_app.py", "8080" -WindowStyle Hidden`  
4. Verify that `curl -I http://localhost:8080/catalog` returns `HTTP/1.1 200 OK`.  
5. Fill in `starter/evidence/evidence_D1_1.json` with the PID, conflicting port, root cause, and HTTP status code.  
6. Run the validation harness:  
   - Linux: `./validation_script.sh` (or `./validation_script.sh check`)  
   - Windows: `.\validation_script.ps1` (or `.\validation_script.ps1 check`)

---

### Scenario MIA-D1-102: Nginx Reverse Proxy 502 Upstream Repair

- **Ticket ID:** `MIA-D1-102` | **Category:** Reverse Proxy & Upstream Routing | **Suggested Time:** 45–60 mins  
- **Starter Artifacts Location:** `middleware_and_apiintegration/day1/s2/starter/`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/middleware_and_apiintegration/day1/s2` to fetch boilerplate code

#### Setup: Initialize the Incident

```sh
# Ubuntu / Linux:
cd middleware_and_apiintegration/day1/s2
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day1\s2
.\validation_script.ps1 start
```

#### The Story

The marketing team launched a nationwide promotional campaign with a custom URL `/promo`. However, every customer attempting to access the site receives an immediate **HTTP 502 Bad Gateway** error. Web traffic is routed through an Nginx reverse proxy.

#### A. Expected Failure (Reproduction Steps)

1. Run the scenario staging script:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Inspect Nginx error logs at `starter/logs/error.log`.
3. **Observed Error:** Nginx logs upstream connection refusal:

```text
2026/10/28 11:30:02 [error] 14220#14220: *1 connect() failed (111: Connection refused) while connecting to upstream, client: 127.0.0.1, server: promo.retail.internal, request: "GET /promo HTTP/1.1", upstream: "http://127.0.0.1:9090/promo", host: "localhost"
```

*Why this fails:* Nginx is configured to forward `/promo` requests to upstream `http://127.0.0.1:9090`. No service is running on port 9090. The promotional backend is actually running on port 8080.

#### B. Step-by-Step Investigation Guidelines

- **Understand 502 Bad Gateway:** Nginx acts as a reverse proxy. When a client visits `/promo`, Nginx forwards the request upstream. A 502 error indicates that the upstream server actively refused the connection or is offline.
- **Locate the backend microservice:** Check active listeners using:
  - Linux: `ss -tulpn | grep 8080`
  - Windows: `netstat -ano | findstr 8080`
  - Notice that the promotional microservice is listening on port **8080**, NOT **9090**!
- **Inspect `starter/conf.d/retail_promo.conf`:**
  - Notice `proxy_pass http://127.0.0.1:9090;`.
  - Notice that standard client IP forwarding headers (`X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`) are missing.

#### C. Action Items to Solve

1. Create a backup file: `cp starter/conf.d/retail_promo.conf starter/conf.d/retail_promo.conf.bak`.  
2. Update `starter/conf.d/retail_promo.conf` so `proxy_pass` targets `http://127.0.0.1:8080`.  
3. Include the required forwarding headers in the location block:
   ```nginx
   proxy_set_header Host $host;
   proxy_set_header X-Real-IP $remote_addr;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header X-Forwarded-Proto $scheme;
   ```
4. Test that `curl -i http://127.0.0.1:8080/promo` returns `HTTP 200 OK`.  
5. Complete the analysis in `starter/evidence/evidence_D1_2.md`.  
6. Run the validation harness:  
   - Linux: `./validation_script.sh check`  
   - Windows: `.\validation_script.ps1 check`

---

### Scenario MIA-D1-103: Kong Gateway Routing & Security Enforcement

- **Ticket ID:** `MIA-D1-103` | **Category:** API Gateway Routing & Security Policy | **Suggested Time:** 45–60 mins  
- **Starter Artifacts Location:** `middleware_and_apiintegration/day1/s3/starter/`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/middleware_and_apiintegration/day1/s3` to fetch boilerplate code

#### Setup: Initialize the Incident

```sh
# Ubuntu / Linux:
cd middleware_and_apiintegration/day1/s3
./validation_script.sh start

# Windows PowerShell:
cd middleware_and_apiintegration\day1\s3
.\validation_script.ps1 start
```

#### The Story

A third-party regional logistics partner is attempting to test our inventory endpoint ahead of a Friday release. When they send requests to `http://localhost:8000/api/v1/inventory`, Kong API Gateway turns them away with `HTTP 404 Not Found` (`{"message":"no Route matched with those values"}`). Furthermore, security audit flagged that the route lacks API key authentication and has no rate limiting.

#### A. Expected Failure (Reproduction Steps)

1. Run the scenario staging script:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Test request:
   ```sh
   curl -i http://localhost:8000/api/v1/inventory
   ```
3. **Observed Error:** Kong returns `HTTP 404 Not Found`:
   ```json
   {"message":"no Route matched with those values"}
   ```

*Why this fails:* In Kong's route configuration, the route path was registered as `/v1/inventory` instead of `/api/v1/inventory`. In addition, no security or throttling policies have been attached to the service.

#### B. Step-by-Step Investigation Guidelines

- **Query Kong Admin API:** Inspect registered routes:
  ```sh
  curl -s http://localhost:8001/routes
  ```
  Notice that the registered path array is `["/v1/inventory"]`, but clients request `/api/v1/inventory`.
- **Examine Security Policy:** Query enabled plugins:
  ```sh
  curl -s http://localhost:8001/plugins
  ```
  Neither `key-auth` nor `rate-limiting` is configured.
- **Identify Target Credentials:**
  - Consumer username: `partner-logistics`
  - API Key: `LogisticsSecretKey2026`
  - Rate Limit: 5 requests per minute (local policy)

#### C. Action Items to Solve

1. Update Kong Gateway route path to `/api/v1/inventory`:
   ```sh
   curl -X PATCH http://localhost:8001/routes/inventory-route -d "paths[]=/api/v1/inventory" -d "strip_path=false"
   ```
2. Enable `key-auth` plugin on `inventory-service`:
   ```sh
   curl -X POST http://localhost:8001/services/inventory-service/plugins -d "name=key-auth"
   ```
3. Create consumer `partner-logistics` and assign API key `LogisticsSecretKey2026`:
   ```sh
   curl -X POST http://localhost:8001/consumers -d "username=partner-logistics"
   curl -X POST http://localhost:8001/consumers/partner-logistics/key-auth -d "key=LogisticsSecretKey2026"
   ```
4. Attach `rate-limiting` plugin (5 requests per minute, local policy):
   ```sh
   curl -X POST http://localhost:8001/services/inventory-service/plugins -d "name=rate-limiting" -d "config.minute=5" -d "config.policy=local"
   ```
5. Verify HTTP error classification:  
   - No Key -> `401 Unauthorized`  
   - Invalid Key -> `403 Forbidden`  
   - Valid Key -> `200 OK`  
   - 6th Call within a minute -> `429 Too Many Requests`  
6. Complete the test matrix in `starter/evidence/evidence_D1_3.md`.  
7. Run the validation harness:  
   - Linux: `./validation_script.sh check`  
   - Windows: `.\validation_script.ps1 check`
