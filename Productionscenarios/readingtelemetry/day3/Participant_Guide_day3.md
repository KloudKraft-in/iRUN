# Reading Telemetry & Observability - Participant Lab Guide: Day 3

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines
### Splunk, Dynatrace & Datadog Query Languages

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

1. Navigate to the scenario directory under `reading_telemetry/day3/<scenario_id>`.
2. Review the scenario overview and expected failure in `starter/README_START_HERE.txt`.
3. Open your terminal and initialize the incident:
   ```sh
   # Ubuntu / Linux:
   cd reading_telemetry/day3/<scenario_id>
   ./validation_script.sh start

   # Windows PowerShell:
   cd reading_telemetry\day3\<scenario_id>
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

## 3. Day 3: Splunk, Dynatrace & Datadog Query Languages

### Scenario TEL-D3-301: Error Spike on One Host After a Release

- **Ticket ID:** `TEL-D3-301` | **Category:** Log Analytics & Advanced SPL | **Suggested Time:** 90 mins  
- **Starter Artifacts Location:** `reading_telemetry/day3/s1/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day3/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day3/s1
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day3\s1
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Log Analytics & Advanced SPL. The engineering team reported Post-deployment error rate surges to 8.4%. Standard log searches fail to extract unstructured error codes from application logs on host web-prod-04.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Splunk Free)).
3. **Observed Error:** Post-deployment error rate surges to 8.4%. Standard log searches fail to extract unstructured error codes from application logs on host web-prod-04.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Execute host breakdown search in Splunk: (index=retail_web OR index=retail_checkout) earliest=-4h | stats count by host, sourcetype | sort -count.
- **Action:** Isolate culprit host web-prod-04 producing 92% of errors.
- **Action:** Extract error codes with regex: rex field=_raw "status_code=(?<err_code>ERR-[0-9]{4})".
- **Action:** Generate 15m timechart: timechart span=15m count by err_code.
- **Action:** Group user sessions: index=retail_checkout earliest=-4h | transaction session_id maxspan=30m | where duration > 10 | table session_id, duration, eventcount.
- **Action:** Complete starter/evidence/evidence_D3_1.md and validate.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day3/s1/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Splunk Free).
3. Populate all required fields in `starter/evidence/evidence_D3_1.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D3-302: Which App Is Failing? Ask Grail

- **Ticket ID:** `TEL-D3-302` | **Category:** Log & Metric Analytics | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day3/s2/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day3/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day3/s2
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day3\s2
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Log & Metric Analytics. The engineering team reported Multiple microservices log failures simultaneously across Kubernetes clusters. Traditional search fails to summarize error types by service entity.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Vendor SaaS (Dynatrace Grail DQL)).
3. **Observed Error:** Multiple microservices log failures simultaneously across Kubernetes clusters. Traditional search fails to summarize error types by service entity.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Open Dynatrace Notebooks to execute Dynatrace Query Language (DQL).
- **Action:** Write Grail pipeline: fetch logs, from:now()-2h | filter status == "ERROR" | summarize ErrorCount = count(), by: {dt.entity.service, error.type} | sort ErrorCount desc.
- **Action:** Identify top failing service inventory-worker experiencing DeadlockException.
- **Action:** Verify count parity in Splunk: index=retail_inventory status="ERROR" error_type="DeadlockException" earliest=-2h | stats count.
- **Action:** Record findings and verified count in starter/evidence/evidence_D3_2.md.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day3/s2/starter/`.
2. Construct and verify the diagnostic queries on Vendor SaaS (Dynatrace Grail DQL).
3. Populate all required fields in `starter/evidence/evidence_D3_2.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D3-303: The p95 Latency Monitor That Never Fires

- **Ticket ID:** `TEL-D3-303` | **Category:** Alert Configuration | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day3/s3/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day3/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day3/s3
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day3\s3
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Alert Configuration. The engineering team reported Critical checkout latency surges past 4 seconds during a promotion, yet the Datadog alert monitor remains completely green and silent.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Vendor SaaS (Datadog Monitors)).
3. **Observed Error:** Critical checkout latency surges past 4 seconds during a promotion, yet the Datadog alert monitor remains completely green and silent.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Inspect the existing monitor query: avg(last_5m):avg:shopnow.checkout.duration{env:staging} > 2.0.
- **Action:** Identify two fatal defects: (1) average latency dilutes tail spikes, (2) query monitors env:staging instead of env:prod.
- **Action:** Rewrite query for 95th percentile on production: p95(last_5m):p95:shopnow.checkout.duration{env:prod} by {service} > 2.5.
- **Action:** Construct composite monitor combining latency (A) AND log error rate (B) using formula 'A && B'.
- **Action:** Complete starter/evidence/evidence_D3_3.json and execute validation.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day3/s3/starter/`.
2. Construct and verify the diagnostic queries on Vendor SaaS (Datadog Monitors).
3. Populate all required fields in `starter/evidence/evidence_D3_3.json`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---
