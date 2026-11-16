# Reading Telemetry & Observability - Participant Lab Guide: Day 4

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines
### New Relic, Grafana, Loki & Prometheus

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

1. Navigate to the scenario directory under `reading_telemetry/day4/<scenario_id>`.
2. Review the scenario overview and expected failure in `starter/README_START_HERE.txt`.
3. Open your terminal and initialize the incident:
   ```sh
   # Ubuntu / Linux:
   cd reading_telemetry/day4/<scenario_id>
   ./validation_script.sh start

   # Windows PowerShell:
   cd reading_telemetry\day4\<scenario_id>
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

## 3. Day 4: New Relic, Grafana, Loki & Prometheus

### Scenario TEL-D4-401: Slow-Transaction Report for the Ops Review

- **Ticket ID:** `TEL-D4-401` | **Category:** Performance Analytics | **Suggested Time:** 60 mins  
- **Starter Artifacts Location:** `reading_telemetry/day4/s1/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day4/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day4/s1
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day4\s1
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Performance Analytics. The engineering team reported Operations review requires a p95 transaction latency ranking for ShopNow-Production. Default APM overviews do not isolate top-5 slowest transactions.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Vendor SaaS (New Relic NRQL) & Prometheus).
3. **Observed Error:** Operations review requires a p95 transaction latency ranking for ShopNow-Production. Default APM overviews do not isolate top-5 slowest transactions.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** In New Relic Query Builder, formulate query: SELECT percentile(duration, 95) AS 'P95', average(duration), max(duration) FROM Transaction WHERE appName = 'ShopNow-Production' FACET name LIMIT 5 SINCE 1 day ago.
- **Action:** Isolate top slowest transaction 'processPayment' averaging ~4.2s p95.
- **Action:** Cross-check using Prometheus PromQL: topk(5, histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[1d])) by (le, handler))).
- **Action:** Record NRQL queries and Prometheus validation output in starter/evidence/evidence_D4_1.md.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day4/s1/starter/`.
2. Construct and verify the diagnostic queries on Vendor SaaS (New Relic NRQL) & Prometheus.
3. Populate all required fields in `starter/evidence/evidence_D4_1.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D4-402: Error Panel Shows Zero During an Outage

- **Ticket ID:** `TEL-D4-402` | **Category:** LogQL & Dashboard Debugging | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day4/s2/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day4/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day4/s2
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day4\s2
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in LogQL & Dashboard Debugging. The engineering team reported During an ongoing payment outage, the Grafana Error Rate panel displays 0 errors. SREs have zero visibility into failure rates.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Grafana & Loki)).
3. **Observed Error:** During an ongoing payment outage, the Grafana Error Rate panel displays 0 errors. SREs have zero visibility into failure rates.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Inspect the existing broken query: sum(count_over_time({app="payment-service"} |= "error" [1m])).
- **Action:** Identify why it returns 0: logs output JSON with uppercase 'level': 'ERROR', and string grep is case-sensitive and misses structured fields.
- **Action:** Refactor query using JSON parser and rate calculation: sum(rate({app="payment-service"} | json | level = "ERROR" [5m])).
- **Action:** Set panel thresholds (Warning > 1, Critical > 5) and export updated panel configuration.
- **Action:** Record findings and fixed query in starter/evidence/evidence_D4_2.json.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day4/s2/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Grafana & Loki).
3. Populate all required fields in `starter/evidence/evidence_D4_2.json`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D4-403: Latency Percentile and Service Variable Are Wrong

- **Ticket ID:** `TEL-D4-403` | **Category:** PromQL & Dashboard Templating | **Suggested Time:** 90 mins  
- **Starter Artifacts Location:** `reading_telemetry/day4/s3/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day4/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day4/s3
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day4\s3
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in PromQL & Dashboard Templating. The engineering team reported SRE dashboard latency percentiles show flat lines measuring cumulative stats since server reboot, and selecting a service in the variable dropdown causes panels to show 'No Data'.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Grafana & Prometheus)).
3. **Observed Error:** SRE dashboard latency percentiles show flat lines measuring cumulative stats since server reboot, and selecting a service in the variable dropdown causes panels to show 'No Data'.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Fix PromQL histogram_quantile by wrapping bucket counts in rate(): histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{service=~"$service"}[5m])) by (le, service)).
- **Action:** Inspect the Grafana dashboard service template variable regex: /^(order|payment|inventory|notification).*$/.
- **Action:** Fix capturing group defect: replace with non-capturing group /^(?:order|payment|inventory|notification).*$/ so Grafana passes the full service name.
- **Action:** Complete starter/evidence/evidence_D4_3.json and run the validation script.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day4/s3/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Grafana & Prometheus).
3. Populate all required fields in `starter/evidence/evidence_D4_3.json`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---
