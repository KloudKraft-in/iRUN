TEL-D5-503: Pager Fatigue: Tune the Alerts and Rebuild the Dashboard
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     On-call engineers receive 80+ alerts per week due to transient 1-second CPU spikes and un-thresholded error fluctuations. Critical incidents get ignored due to alarm fatigue.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Inspect un-tuned Prometheus alert rules: notice absence of 'for' duration delays and runbook links.
2. Tune alert rules: add 'for: 10m' to HostHighCPUSustained (>85%) and 'for: 3m' to HighErrorRate (>5%).
3. Add annotations with runbook_url links and appropriate severity labels (warning vs critical).
4. Restructure Grafana dashboard into Tier-1 (Executive health: Is business ok? < 5s) and Tier-2 (Engineering drill-downs).
5. Document tuned YAML configuration in starter/evidence/evidence_D5_3.md and run validation.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D5_3.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
