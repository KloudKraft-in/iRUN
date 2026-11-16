TEL-D6-602: Error Budget Burn and a Cardinality Bill
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     A sudden release introduces high-cardinality labels, causing Prometheus TSDB series count to explode and depleting the 30-day error budget in under 2 hours.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Calculate 1h SLO burn rate: sum(rate(http_requests_total{status!~"5.."}[1h])) / sum(rate(http_requests_total[1h])) * 100.
2. Inspect Prometheus TSDB status API (/api/v1/status/tsdb) to find metric explosion.
3. Identify offending high-cardinality label 'user_id' attached to http_requests_total.
4. Configure metric_relabel_configs with action: labeldrop and regex: 'user_id' in Prometheus configuration.
5. Document error budget burn rate and relabelling YAML in starter/evidence/evidence_D6_2.md.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D6_2.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
