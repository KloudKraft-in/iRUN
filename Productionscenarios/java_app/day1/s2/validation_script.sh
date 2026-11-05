#!/usr/bin/env bash
set -e
echo "==================================================="
echo " Validating JAVA-D1-102: JAR / WAR Deployment      "
echo "==================================================="

echo ""
echo "[Check 1/2] Testing Standalone JAR on port 8083..."
curl -s -f "http://localhost:8083/api/demo" > /dev/null 2>&1 || {
    echo "  [FAIL] Standalone JAR not responding on port 8083."
    echo "  Action: Launch JAR with: java -jar target/jar-demo-0.0.1-SNAPSHOT.jar"
    exit 1
}
echo "  -> Standalone JAR is UP on port 8083."

echo ""
echo "[Check 2/2] Testing Deployed WAR on Tomcat port 8080..."
curl -s -f "http://localhost:8080/war-demo/api/demo" > /dev/null 2>&1 || {
    echo "  [FAIL] Tomcat WAR not responding on port 8080/war-demo."
    echo "  Action: Ensure Tomcat is started and war-demo.war is in webapps/"
    exit 1
}
echo "  -> Tomcat Deployed WAR is UP on port 8080."

echo ""
echo "==================================================="
echo " [PASS] JAVA-D1-102 Validation Succeeded! "
echo "==================================================="
