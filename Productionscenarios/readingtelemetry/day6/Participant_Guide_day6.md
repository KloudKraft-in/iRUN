# Reading Telemetry & Observability - Participant Lab Guide: Day 6

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines
### End-to-End Observability Operations & Incident Investigation

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

1. Navigate to the scenario directory under `reading_telemetry/day6/<scenario_id>`.
2. Review the scenario overview and expected failure in `starter/README_START_HERE.txt`.
3. Open your terminal and initialize the incident:
   ```sh
   # Ubuntu / Linux:
   cd reading_telemetry/day6/<scenario_id>
   ./validation_script.sh start

   # Windows PowerShell:
   cd reading_telemetry\day6\<scenario_id>
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

## 3. Day 6: End-to-End Observability Operations & Incident Investigation

### Scenario TEL-D6-601: Metric Anomaly to Root Cause in One Platform

- **Ticket ID:** `TEL-D6-601` | **Category:** Cross-Telemetry RCA | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day6/s1/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day6/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day6/s1
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day6\s1
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Cross-Telemetry RCA. The engineering team reported At 09:12 UTC, checkout conversion drops by 35%. Engineers must correlate metric anomaly to application logs and distributed traces without tool switching.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Grafana Stack - Tempo/Loki/Prometheus)).
3. **Observed Error:** At 09:12 UTC, checkout conversion drops by 35%. Engineers must correlate metric anomaly to application logs and distributed traces without tool switching.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** In Grafana Explore, detect metric anomaly on checkout throughput starting at 09:12 UTC.
- **Action:** Split view into Loki logs: query {service="checkout-api"} | json | status="ERROR".
- **Action:** Extract correlated Trace ID '6a71e29f8c12' directly from the log line.
- **Action:** Jump directly to Tempo trace waterfall for Trace ID 6a71e29f8c12.
- **Action:** Isolate root cause span and complete starter/evidence/evidence_D6_1.md.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day6/s1/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Grafana Stack - Tempo/Loki/Prometheus).
3. Populate all required fields in `starter/evidence/evidence_D6_1.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D6-602: Error Budget Burn and a Cardinality Bill

- **Ticket ID:** `TEL-D6-602` | **Category:** SLO Governance & Cardinality | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day6/s2/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day6/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day6/s2
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day6\s2
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in SLO Governance & Cardinality. The engineering team reported A sudden release introduces high-cardinality labels, causing Prometheus TSDB series count to explode and depleting the 30-day error budget in under 2 hours.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Prometheus & OpenTelemetry)).
3. **Observed Error:** A sudden release introduces high-cardinality labels, causing Prometheus TSDB series count to explode and depleting the 30-day error budget in under 2 hours.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Calculate 1h SLO burn rate: sum(rate(http_requests_total{status!~"5.."}[1h])) / sum(rate(http_requests_total[1h])) * 100.
- **Action:** Inspect Prometheus TSDB status API (/api/v1/status/tsdb) to find metric explosion.
- **Action:** Identify offending high-cardinality label 'user_id' attached to http_requests_total.
- **Action:** Configure metric_relabel_configs with action: labeldrop and regex: 'user_id' in Prometheus configuration.
- **Action:** Document error budget burn rate and relabelling YAML in starter/evidence/evidence_D6_2.md.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day6/s2/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Prometheus & OpenTelemetry).
3. Populate all required fields in `starter/evidence/evidence_D6_2.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D6-603: Integrated Production Incident Workshop

- **Ticket ID:** `TEL-D6-603` | **Category:** Capstone War-Room | **Suggested Time:** 150 mins  
- **Starter Artifacts Location:** `reading_telemetry/day6/s3/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day6/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day6/s3
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day6\s3
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Capstone War-Room. The engineering team reported Major production outage impacts all tiers of the ShopNow enterprise. Incident commander requires verified query evidence across all 7 observability platforms.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Hybrid (All 7 Observability Platforms)).
3. **Observed Error:** Major production outage impacts all tiers of the ShopNow enterprise. Incident commander requires verified query evidence across all 7 observability platforms.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Execute Splunk (SPL): index=retail_checkout status=500 | stats count by error_code, host.
- **Action:** Execute Dynatrace (DQL): fetch logs | filter error.code == "INV_LOCK_TIMEOUT" | summarize count() by dt.entity.service.
- **Action:** Execute New Relic (NRQL): SELECT average(duration), max(duration) FROM Transaction WHERE appName='Inventory' FACET name SINCE 1 hour ago.
- **Action:** Execute Loki (LogQL): {app="payment-service"} | json | status="ERROR".
- **Action:** Execute Azure (KQL): dependencies | where success == false | summarize count() by target.
- **Action:** Execute Prometheus (PromQL): histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)).
- **Action:** Execute Datadog: p95(last_5m):p95:shopnow.checkout.duration{env:prod} by {service} > 2.5.
- **Action:** Compile post-mortem RCA with 5 Whys in starter/evidence/evidence_D6_3.md.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day6/s3/starter/`.
2. Construct and verify the diagnostic queries on Hybrid (All 7 Observability Platforms).
3. Populate all required fields in `starter/evidence/evidence_D6_3.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---
