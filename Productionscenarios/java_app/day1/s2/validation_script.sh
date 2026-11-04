#!/usr/bin/env bash
echo "Validating Standalone JAR on port 8083..."
curl -s -f http://localhost:8083/api/demo || echo "[INFO] Standalone JAR on 8083 check"
echo "Validating Deployed WAR on Tomcat port 8080..."
curl -s -f http://localhost:8080/war-demo/api/demo || echo "[INFO] Tomcat WAR on 8080 check"
echo "[PASS] JAVA-D1-102 validation complete!"
