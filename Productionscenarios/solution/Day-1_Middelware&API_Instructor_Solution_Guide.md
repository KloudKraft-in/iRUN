# Day 1: Instructor Solution & Mentor Reference Guide
## Middleware Fundamentals, Web Servers & API Gateway (Confidential)

> **Instructor Note:** Do not distribute this guide to participants. It contains exact root causes, one-line patches, grading rubrics, and reference terminal commands.

---

## Ticket MIA-D1-101: Tomcat Port Collision Recovery (CO-01)
* **Root Cause:** Connector port set to 8082 in `server.xml`. Rogue legacy daemon occupying port 8082 caused `java.net.BindException: Address already in use: 8082`.
* **Diagnostic Command:** `grep -in 'bindexception' starter/logs/catalina.out` & `netstat -ano | findstr 8082` (or `ss -tulpn | grep 8082`).
* **Resolution Steps:**
  1. `cp starter/conf/server.xml starter/conf/server.xml.bak`
  2. Edit `starter/conf/server.xml` and change port to `8080`.
  3. Start catalog app on 8080: `python3 starter/mock_services/catalog_app.py 8080 &`
  4. Test: `curl -I http://localhost:8080/catalog`
* **Grading Rubric:** Backup created (20%), identified BindException (20%), retained daemon on 8082 (20%), catalog healthy on 8080 (20%), evidence filled (20%).

---

## Ticket MIA-D1-102: Nginx Reverse Proxy 502 Upstream Repair (CO-02)
* **Root Cause:** `proxy_pass` set to dead port `127.0.0.1:9090`, generating `111: Connection refused`. Backend is on `8080`.
* **Diagnostic Command:** `cat starter/logs/error.log` & `ss -tulpn | grep 8080`.
* **Resolution Steps:**
  1. `cp starter/conf.d/retail_promo.conf starter/conf.d/retail_promo.conf.bak`
  2. Point `proxy_pass` to `http://127.0.0.1:8080;`.
  3. Add forwarding headers: `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`.
* **Grading Rubric:** Error log analyzed (25%), backend identified on 8080 (25%), forwarding headers present (25%), evidence filled (25%).

---

## Ticket MIA-D1-103: Kong Gateway Routing & Security Enforcement (CO-03)
* **Root Cause:** Route path configured as `/v1/inventory` instead of `/api/v1/inventory`. Missing `key-auth` and `rate-limiting` plugins.
* **Resolution Commands:**
  ```bash
  curl -X PATCH http://localhost:8001/routes/inventory-route -d "paths[]=/api/v1/inventory" -d "strip_path=false"
  curl -X POST http://localhost:8001/services/inventory-service/plugins -d "name=key-auth"
  curl -X POST http://localhost:8001/consumers -d "username=partner-logistics"
  curl -X POST http://localhost:8001/consumers/partner-logistics/key-auth -d "key=LogisticsSecretKey2026"
  curl -X POST http://localhost:8001/services/inventory-service/plugins -d "name=rate-limiting" -d "config.minute=5" -d "config.policy=local"
  ```
* **Grading Rubric:** Route path repaired (25%), key-auth enforced (25%), rate-limiting enforced (25%), status code matrix completed (25%).
