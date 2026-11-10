MIA-D1-102: Nginx Reverse Proxy 502 Bad Gateway
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Inspect the Nginx error log:
     cat starter/logs/error.log
3. OBSERVED FAILURE:
     connect() failed (111: Connection refused) while connecting to upstream: "http://127.0.0.1:9090/promo"
   Why this fails: The proxy_pass directive in conf.d/retail_promo.conf forwards traffic
   to port 9090, but no service is listening on port 9090. The promotional backend is actually
   listening on port 8080.

YOUR MISSION (Guidelines & Solve):
1. Locate where the promotional microservice is actually running:
     netstat -ano | findstr 8080   (Ubuntu: ss -tulpn | grep 8080)
2. Back up starter/conf.d/retail_promo.conf to starter/conf.d/retail_promo.conf.bak.
3. Edit starter/conf.d/retail_promo.conf:
   - Change proxy_pass to http://127.0.0.1:8080;
   - Add standard proxy headers (Host, X-Real-IP, X-Forwarded-For, X-Forwarded-Proto).
4. Verify http://127.0.0.1:8080/promo responds with HTTP 200 OK.
5. Record your findings in starter/evidence/evidence_D1_2.md.
6. Run validation:
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================
