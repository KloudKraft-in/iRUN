TEL-D5-502: Lambda Timeouts: Logs Insights Meets X-Ray
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. OBSERVED FAILURE:
     Order invoice generation Lambdas terminate abruptly with 'Task timed out after 30.00 seconds'. CloudWatch logs show timeouts but do not reveal the stalled downstream call.
   Why this fails: The initial telemetry configuration or instrumentation contains
   defects, masking anomalies or missing critical alert thresholds.

YOUR MISSION (Guidelines & Solve):
1. Execute CloudWatch Logs Insights query: fields @timestamp, @message, @duration | filter @message like /Task timed out/ | limit 20.
2. Extract X-Ray trace ID and navigate to AWS X-Ray service map / trace waterfall.
3. Analyze subsegment durations: locate subsegment 'S3:PutObject' to bucket 'shopnow-invoices-archive' taking 29.8s before aborting.
4. Identify root cause: S3 bucket access stalling due to missing S3 VPC Gateway Endpoint in private subnet.
5. Complete starter/evidence/evidence_D5_2.md and validate.

SUBMISSION & EVIDENCE:
1. Fill in starter/evidence/evidence_D5_2.md
2. Run validation check:
     .\validation_script.ps1 check   (Ubuntu: ./validation_script.sh check)
===============================================================================
