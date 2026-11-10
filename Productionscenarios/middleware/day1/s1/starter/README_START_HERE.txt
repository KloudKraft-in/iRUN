MIA-D1-101: Tomcat Won't Come Back After a Port Change
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Inspect the Tomcat startup log:
     cat starter/logs/catalina.out
3. OBSERVED FAILURE:
     SEVERE: Failed to initialize component [Connector[HTTP/1.1-8082]]
     Caused by: java.net.BindException: Address already in use: 8082
   Why this fails: The HTTP Connector in conf/server.xml was edited to port 8082.
   Port 8082 is actively occupied by a legacy sync daemon. Two processes cannot bind
   the same TCP port simultaneously.

YOUR MISSION (Guidelines & Solve):
1. Identify the process holding port 8082 (netstat -ano on Windows, ss -tulpn on Linux).
   Do NOT terminate this process—it is a critical background daemon.
2. Back up starter/conf/server.xml to starter/conf/server.xml.bak.
3. Edit starter/conf/server.xml and revert port="8082" to port="8080".
4. Start the catalog service:
     Windows: Start-Process python -ArgumentList "starter/mock_services/catalog_app.py", "8080" -WindowStyle Hidden
     Ubuntu:  python3 starter/mock_services/catalog_app.py 8080 &
5. Verify http://localhost:8080/catalog responds with 200 OK.
6. Record your findings in starter/evidence/evidence_D1_1.json.
7. Run validation:
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================
