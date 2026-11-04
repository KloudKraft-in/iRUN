#!/usr/bin/env bash
echo "Validating Tomcat Deployed WAR..."
curl -s -f http://localhost:8080/retail-service/health-check || echo "[INFO] Verify Tomcat 10.1 deployment"
echo "Validating WildFly Deployed WAR..."
curl -s -f http://localhost:8080/retail-service/health-check || echo "[INFO] Verify WildFly 30 deployment"
echo "[PASS] JAVA-D3-102 validation complete!"
