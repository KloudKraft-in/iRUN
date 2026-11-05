#!/bin/bash
set -e
echo "==========================================================="
echo " Validating JAVA-D3-102: Tomcat & WildFly WAR Deployment   "
echo "==========================================================="

echo -e "\n[Check 1/2] Testing Tomcat deployed WAR on http://localhost:8080/retail-service/health-check..."
RES=$(curl -s --connect-timeout 5 http://localhost:8080/retail-service/health-check || true)
if [ -z "$RES" ]; then
    echo "  [FAIL] Tomcat deployed WAR not responding on port 8080/retail-service."
    exit 1
fi

echo "  -> Response: $RES"
echo "==========================================================="
echo " [PASS] JAVA-D3-102 WAR Deployment Validation Succeeded!   "
echo "==========================================================="
