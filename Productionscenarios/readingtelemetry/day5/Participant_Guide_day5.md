# Reading Telemetry & Observability - Participant Lab Guide: Day 5

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines
### Azure, Cloud Platforms & Operational Dashboards

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

1. Navigate to the scenario directory under `reading_telemetry/day5/<scenario_id>`.
2. Review the scenario overview and expected failure in `starter/README_START_HERE.txt`.
3. Open your terminal and initialize the incident:
   ```sh
   # Ubuntu / Linux:
   cd reading_telemetry/day5/<scenario_id>
   ./validation_script.sh start

   # Windows PowerShell:
   cd reading_telemetry\day5\<scenario_id>
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

## 3. Day 5: Azure, Cloud Platforms & Operational Dashboards

### Scenario TEL-D5-501: Top Failing Dependency in Application Insights

- **Ticket ID:** `TEL-D5-501` | **Category:** Cloud Dependency Analysis | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day5/s1/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day5/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day5/s1
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day5\s1
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Cloud Dependency Analysis. The engineering team reported Downstream third-party dependency failures cause checkout degradation. Engineers cannot determine which vendor is failing or correlate errors to application exceptions.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Cloud (Azure Application Insights KQL)).
3. **Observed Error:** Downstream third-party dependency failures cause checkout degradation. Engineers cannot determine which vendor is failing or correlate errors to application exceptions.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Open Azure Log Analytics / Application Insights KQL console.
- **Action:** Summarize failed calls: dependencies | where timestamp > ago(4h) | summarize TotalCalls = count(), FailedCalls = countif(success == false) by target | extend FailureRate = round(100.0 * FailedCalls / TotalCalls, 2) | sort by FailedCalls desc.
- **Action:** Identify failing target 'api.external-fraud.io' throwing 504 timeouts (42.4% failure rate).
- **Action:** Join dependencies with exceptions: dependencies | where timestamp > ago(4h) and success == false and target == "api.external-fraud.io" | join kind=inner (exceptions | where timestamp > ago(4h)) on operation_Id | project timestamp, operation_Id, target, resultCode, innermostMessage.
- **Action:** Record KQL queries and exception findings in starter/evidence/evidence_D5_1.md.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day5/s1/starter/`.
2. Construct and verify the diagnostic queries on Cloud (Azure Application Insights KQL).
3. Populate all required fields in `starter/evidence/evidence_D5_1.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D5-502: Lambda Timeouts: Logs Insights Meets X-Ray

- **Ticket ID:** `TEL-D5-502` | **Category:** Serverless Tracing & Logs | **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `reading_telemetry/day5/s2/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day5/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day5/s2
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day5\s2
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Serverless Tracing & Logs. The engineering team reported Order invoice generation Lambdas terminate abruptly with 'Task timed out after 30.00 seconds'. CloudWatch logs show timeouts but do not reveal the stalled downstream call.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Cloud (AWS CloudWatch & X-Ray)).
3. **Observed Error:** Order invoice generation Lambdas terminate abruptly with 'Task timed out after 30.00 seconds'. CloudWatch logs show timeouts but do not reveal the stalled downstream call.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Execute CloudWatch Logs Insights query: fields @timestamp, @message, @duration | filter @message like /Task timed out/ | limit 20.
- **Action:** Extract X-Ray trace ID and navigate to AWS X-Ray service map / trace waterfall.
- **Action:** Analyze subsegment durations: locate subsegment 'S3:PutObject' to bucket 'shopnow-invoices-archive' taking 29.8s before aborting.
- **Action:** Identify root cause: S3 bucket access stalling due to missing S3 VPC Gateway Endpoint in private subnet.
- **Action:** Complete starter/evidence/evidence_D5_2.md and validate.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day5/s2/starter/`.
2. Construct and verify the diagnostic queries on Cloud (AWS CloudWatch & X-Ray).
3. Populate all required fields in `starter/evidence/evidence_D5_2.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---

### Scenario TEL-D5-503: Pager Fatigue: Tune the Alerts and Rebuild the Dashboard

- **Ticket ID:** `TEL-D5-503` | **Category:** Alert Governance & Dashboard Design | **Suggested Time:** 90 mins  
- **Starter Artifacts Location:** `reading_telemetry/day5/s3/starter/`  

#### Setup: Scenario Workspace Location
- Local Workspace Directory: `reading_telemetry/day5/<scenario>/starter/`
#### Setup: Initialize the Incident

On your local lab environment, open your terminal and navigate to:

```sh
# Ubuntu / Linux:
cd reading_telemetry/day5/s3
./validation_script.sh start

# Windows PowerShell:
cd reading_telemetry\day5\s3
.\validation_script.ps1 start
```

#### The Story

During recent production operations on the ShopNow microservices architecture, operations identified an anomaly in Alert Governance & Dashboard Design. The engineering team reported On-call engineers receive 80+ alerts per week due to transient 1-second CPU spikes and un-thresholded error fluctuations. Critical incidents get ignored due to alarm fatigue.. You are assigned to investigate the root cause, identify the defect, and implement telemetry remediation.

#### A. Expected Failure (Reproduction Steps)

1. Run the initial start command:
   - Linux: `./validation_script.sh start`
   - Windows: `.\validation_script.ps1 start`
2. Connect to the designated platform (Self-Hosted (Prometheus Alertmanager & Grafana)).
3. **Observed Error:** On-call engineers receive 80+ alerts per week due to transient 1-second CPU spikes and un-thresholded error fluctuations. Critical incidents get ignored due to alarm fatigue.

*Why this fails:* The current observability configuration, metric query, or instrumentation pipeline contains logical defects that obscure or distort the true state of the service.

#### B. Step-by-Step Investigation Guidelines

- **Action:** Inspect un-tuned Prometheus alert rules: notice absence of 'for' duration delays and runbook links.
- **Action:** Tune alert rules: add 'for: 10m' to HostHighCPUSustained (>85%) and 'for: 3m' to HighErrorRate (>5%).
- **Action:** Add annotations with runbook_url links and appropriate severity labels (warning vs critical).
- **Action:** Restructure Grafana dashboard into Tier-1 (Executive health: Is business ok? < 5s) and Tier-2 (Engineering drill-downs).
- **Action:** Document tuned YAML configuration in starter/evidence/evidence_D5_3.md and run validation.

#### C. Action Items to Solve

1. Inspect the configuration and starter files in `reading_telemetry/day5/s3/starter/`.
2. Construct and verify the diagnostic queries on Self-Hosted (Prometheus Alertmanager & Grafana).
3. Populate all required fields in `starter/evidence/evidence_D5_3.md`.
4. Run the validation harness to verify compliance:
   - Linux: `./validation_script.sh check`
   - Windows: `.\validation_script.ps1 check`

---
