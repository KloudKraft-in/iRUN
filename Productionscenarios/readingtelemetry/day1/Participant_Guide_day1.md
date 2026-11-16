# Reading Telemetry & Observability - Participant Lab Guide: Day 1

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines
### Observability Foundations & Incident Triage

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

1. Navigate to the scenario directory under `reading_telemetry/day1/<scenario_id>`.
2. Review the scenario overview and expected failure in `starter/README_START_HERE.txt`.
3. Open your terminal and initialize the incident:
   ```sh
   # Ubuntu / Linux:
   cd reading_telemetry/day1/<scenario_id>
   ./validation_script.sh start

   # Windows PowerShell:
   cd reading_telemetry\day1\<scenario_id>
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

## 3. Day 1: Observability Foundations & Incident Triage

### Scenario TEL-D1-101: Checkout Is Slow but the Dashboard Looks Green

- **Ticket ID:** `TEL-D1-101` | **Category:** Dashboard Troubleshooting | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day1/s1/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day1/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day1/s1
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day1\s1
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Dashboard Troubleshooting. The engineering team reported Grafana RED dashboard shows green status and average latency of ~185ms, while customers report 4.5s+ checkout timeouts. The panel query uses 'avg(payment_duration_seconds)' which flattens the bimodal distribution.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Prometheus & Grafana)).
3. **Observed Error:** Grafana RED dashboard shows green status and average latency of ~185ms, while customers report 4.5s+ checkout timeouts. The panel query uses 'avg(payment_duration_seconds)' which flattens the bimodal distribution.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Open the Grafana RED Dashboard (http://localhost:3000) with credentials admin/admin.
- **Action:** Inspect the 'Payment Duration' panel query: notice it averages outliers instead of computing percentiles.
- **Action:** Replace arithmetic mean with p95 histogram quantile: histogram_quantile(0.95, sum(rate(payment_duration_seconds_bucket[5m])) by (le)) * 1000.
- **Action:** Add the missing RED 'Errors' panel calculating 5xx request percentage: sum(rate(http_requests_total{service="checkout-service", status=~"5.."}[5m])) / sum(rate(http_requests_total{service="checkout-service"}[5m])) * 100.
- **Action:** Complete starter/evidence/evidence_D1_1.json and run the validation harness.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day1/s1/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Prometheus & Grafana).
3. Populate all required fields in `starter/evidence/evidence_D1_1.json`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D1-102: Orders Fail for One Product: Follow the Trace

- **Ticket ID:** `TEL-D1-102` | **Category:** Distributed Tracing | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day1/s2/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day1/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day1/s2
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day1\s2
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Distributed Tracing. The engineering team reported Orders for promotional SKU 'PROD-7729' fail intermittently with generic 500 error screens. Aggregate service metrics report healthy throughput, masking isolated transaction failures.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Jaeger & Loki)).
3. **Observed Error:** Orders for promotional SKU 'PROD-7729' fail intermittently with generic 500 error screens. Aggregate service metrics report healthy throughput, masking isolated transaction failures.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Open Jaeger UI (http://localhost:16686) or Grafana Explore.
- **Action:** Filter traces for service 'checkout-service' with tag 'http.status_code=500'.
- **Action:** Locate failing trace '4bf92f3577b34da6a3ce929d0e0e4736' and examine the span waterfall.
- **Action:** Identify slowest failing span 'inventory.reserveStock' taking ~430ms with error=true.
- **Action:** Query Loki logs with LogQL: {app="inventory-service"} |= "4bf92f3577b34da6a3ce929d0e0e4736".
- **Action:** Extract the StockReservationException and document the audit lock root cause in starter/evidence/evidence_D1_2.md.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day1/s2/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Jaeger & Loki).
3. Populate all required fields in `starter/evidence/evidence_D1_2.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D1-103: Six Alerts at Shift Start, One Real Problem

- **Ticket ID:** `TEL-D1-103` | **Category:** Alert Triage | **Suggested Time:** 60 mins  
- **Starter Artifacts Location:** `reading_telemetry/day1/s3/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day1/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day1/s3
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day1\s3
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Alert Triage. The engineering team reported Six simultaneous alerts fire in Alertmanager (CheckoutSlow, PaymentTimeout, ProfileQueryDegraded, OrderHistory504, DiskIOWaitHigh, DatabaseQueueSaturation), creating cognitive overload.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Alertmanager & USE Methodology)).
3. **Observed Error:** Six simultaneous alerts fire in Alertmanager (CheckoutSlow, PaymentTimeout, ProfileQueryDegraded, OrderHistory504, DiskIOWaitHigh, DatabaseQueueSaturation), creating cognitive overload.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Access Alertmanager (http://localhost:9093) and Prometheus Alerts (http://localhost:9090/alerts).
- **Action:** Classify alerts into Symptomatic Application Alerts vs Infrastructure Causal Alerts using USE methodology.
- **Action:** Analyze database saturation metrics: observe Database Disk Queue Saturation = 38 (normal < 2) and I/O await = 280ms.
- **Action:** Correlate the saturation to unindexed batch analytics query PID 9182 on the primary database.
- **Action:** Formulate mitigation (terminate rogue query, route reporting to read replica) and complete starter/evidence/evidence_D1_3.json.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day1/s3/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Alertmanager & USE Methodology).
3. Populate all required fields in `starter/evidence/evidence_D1_3.json`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---
