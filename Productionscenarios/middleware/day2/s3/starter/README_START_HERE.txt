MIA-D2-203: Distributed Timeout Hierarchy & Escalation Report
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Trace the multi-hop log file:
     cat starter/logs/multi_hop_trace.log
3. OBSERVED FAILURE:
     Kong read_timeout (3.0s) triggers HTTP 504 while backend takes 5.2s.
     Payment completes (200 OK), but customer receives 504 and re-clicks pay (Ghost order).

YOUR MISSION (Guidelines & Solve):
1. Realign timeout hierarchy:
     - starter/conf/kong_service.json -> read_timeout: 15000 (15s)
     - starter/conf/checkout_nginx.conf -> proxy_read_timeout 12s;
2. Complete the incident RCA report in starter/evidence/evidence_D2_3.md.
3. Run validation:
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================
