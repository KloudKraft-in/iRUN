# Reading Telemetry & Observability - Participant Lab Guide: Day 2

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines
### Enterprise Observability Platforms & Tool Navigation

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
| **Python Runtime** | Python 3.8+ | `python --version` or `python3 --version` | Telemetry simulators, mock microservices, harnesses |
| **Network Tools** | curl, ss / netstat, jq | `curl --version` | REST API querying, metrics endpoints, port inspection |
| **Docker & Compose** | Docker 24.x+, Compose v2 | `docker compose version` | Self-hosted observability stack (Prometheus, Grafana, Loki) |
| **Prometheus** | v2.45+ | `curl http://localhost:9090/-/ready` | Time-series metrics collection & PromQL queries |
| **Grafana** | v10.x+ | `curl http://localhost:3000/api/health` | Unified dashboards, panels, and data source exploration |
| **Version Control** | Git 2.30+ | `git --version` | Starter artifact retrieval and lab versioning |

### Port Allocation & Reservation

Ensure the following ports are unoccupied before launching exercises:

- `3000`: Grafana UI Server
- `9090`: Prometheus TSDB & Query Engine
- `9093`: Alertmanager Routing Engine
- `16686`: Jaeger UI / Trace Collector
- `3100`: Grafana Loki Log Ingestion
- `8000`: Splunk Enterprise Web UI
- `8080–8083`: ShopNow Microservices (Frontend, Checkout, Payment, Inventory)

---

## 2. Common Instructions for Trainers and Participants

### Standard Lab Workflow

1. Navigate to the scenario directory under `reading_telemetry/day2/<scenario_id>`.
2. Review the scenario overview and expected failure in `starter/README_START_HERE.txt`.
3. Open your terminal and initialize the incident:
   ```sh
   # Ubuntu / Linux:
   cd reading_telemetry/day2/<scenario_id>
   ./validation_script.sh start

   # Windows PowerShell:
   cd reading_telemetry\day2\<scenario_id>
   .\validation_script.ps1 start
   ```
4. Inspect the telemetry data across the designated observability platform.
5. Identify the failure mechanism and implement the fix or complete the evidence record in `starter/evidence/`.
6. Validate your solution using the local test harness:
   ```sh
   # Ubuntu / Linux:
   ./validation_script.sh check

   # Windows PowerShell:
   .\validation_script.ps1 check
   ```
7. Once verified, reset the scenario if needed: `./validation_script.sh reset`

---

## 3. Day 2: Enterprise Observability Platforms & Tool Navigation

### Scenario TEL-D2-201: Davis Opened a Problem: Find the Root Cause

- **Ticket ID:** `TEL-D2-201` | **Category:** Platform Triage | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day2/s1/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day2/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day2/s1
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day2\s1
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Platform Triage. The engineering team reported Dynatrace Davis AI engine automatically opened Problem P-24101 indicating payment degradation. Navigating complex UI menus makes finding the root cause code span difficult.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Vendor SaaS (Dynatrace)).
3. **Observed Error:** Dynatrace Davis AI engine automatically opened Problem P-24101 indicating payment degradation. Navigating complex UI menus makes finding the root cause code span difficult.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Open Dynatrace Problem card P-24101 and review Smartscape topology.
- **Action:** Follow transaction flow from frontend -> checkout -> PaymentService on prod-host-03.
- **Action:** Open PurePaths filtered by failed requests.
- **Action:** Isolate failing method: StripeGatewayConnector.authorize() throwing SocketTimeoutException (5000ms).
- **Action:** Complete starter/evidence/evidence_D2_1.md and verify with the validation harness.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day2/s1/starter/`.
2. Construct and verify the diagnostic queries on Vendor SaaS (Dynatrace).
3. Populate all required fields in `starter/evidence/evidence_D2_1.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D2-202: Datadog Monitor Fires: Confirm It in Splunk

- **Ticket ID:** `TEL-D2-202` | **Category:** Alert Investigation | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day2/s2/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day2/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day2/s2
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day2\s2
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Alert Investigation. The engineering team reported Datadog composite monitor triggers alert: CPU > 80% on prod-worker-02 AND Error Rate > 5%. Raw log evidence must be extracted from Splunk to confirm transaction failure.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (SaaS (Datadog) + Self-Hosted (Splunk Enterprise)).
3. **Observed Error:** Datadog composite monitor triggers alert: CPU > 80% on prod-worker-02 AND Error Rate > 5%. Raw log evidence must be extracted from Splunk to confirm transaction failure.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Review Datadog composite alert metadata and extract transaction correlation ID 'TXN-88129-CORR' at 11:32:14 UTC.
- **Action:** Access Splunk Enterprise (http://localhost:8000).
- **Action:** Construct search query: index=retail_prod host=prod-worker-02 sourcetype="checkout:json" "TXN-88129-CORR".
- **Action:** Confirm the matching error log signature and stack trace.
- **Action:** Complete starter/evidence/evidence_D2_2.md with queries and log evidence.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day2/s2/starter/`.
2. Construct and verify the diagnostic queries on SaaS (Datadog) + Self-Hosted (Splunk Enterprise).
3. Populate all required fields in `starter/evidence/evidence_D2_2.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D2-203: One Incident, Four Tools: Write the Escalation

- **Ticket ID:** `TEL-D2-203` | **Category:** Escalation Engineering | **Suggested Time:** 90 mins  
- **Starter Artifacts Location:** `reading_telemetry/day2/s3/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day2/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day2/s3
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day2\s3
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Escalation Engineering. The engineering team reported Checkout experience is severely degraded across microservices. SREs receive contradictory signals across Grafana, Kibana, New Relic, and cloud consoles.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Grafana & Kibana) + SaaS (New Relic)).
3. **Observed Error:** Checkout experience is severely degraded across microservices. SREs receive contradictory signals across Grafana, Kibana, New Relic, and cloud consoles.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Examine Grafana RED dashboard: locate latency jump on panel 2 (http://localhost:3000/d/red-checkout?viewPanel=2).
- **Action:** Inspect Kibana logs: query service.name:"order-service" AND log.level:ERROR.
- **Action:** Inspect New Relic APM: analyze CheckoutController#processOrder spending 7.6s in PostgreSQL pg_sleep.
- **Action:** Synthesize root cause: database table lock contention in orders_db.
- **Action:** Draft an executive escalation note in starter/evidence/evidence_D2_3.md linking all tools.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day2/s3/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Grafana & Kibana) + SaaS (New Relic).
3. Populate all required fields in `starter/evidence/evidence_D2_3.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---
