MIA-D1-103: Kong Gateway Route 404 & Security Policy Enforcement
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Send test request to gateway:
     curl -i http://localhost:8000/api/v1/inventory
3. OBSERVED FAILURE:
     HTTP/1.1 404 Not Found  {"message":"no Route matched with those values"}
   Why this fails: Kong route path was registered as '/v1/inventory' instead of
   '/api/v1/inventory'. In addition, no authentication or rate limiting plugins are active.

YOUR MISSION (Guidelines & Solve):
1. Query routes via Kong Admin API:
     curl -s http://localhost:8001/routes
2. Update the route path:
     curl -X PATCH http://localhost:8001/routes/inventory-route -d "paths[]=/api/v1/inventory" -d "strip_path=false"
3. Protect with key-auth plugin:
     curl -X POST http://localhost:8001/services/inventory-service/plugins -d "name=key-auth"
     curl -X POST http://localhost:8001/consumers -d "username=partner-logistics"
     curl -X POST http://localhost:8001/consumers/partner-logistics/key-auth -d "key=LogisticsSecretKey2026"
4. Enable rate limiting (5 req/min):
     curl -X POST http://localhost:8001/services/inventory-service/plugins -d "name=rate-limiting" -d "config.minute=5" -d "config.policy=local"
5. Fill in starter/evidence/evidence_D1_3.md.
6. Run validation:
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================
