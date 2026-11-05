#!/bin/bash
set -e
echo "==========================================================="
echo " Validating JAVA-D2-102: Actuator & Endpoint Security      "
echo "==========================================================="

echo -e "\n[Check 1/3] Testing Public /actuator/health..."
CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/actuator/health || true)
if [ "$CODE" != "200" ]; then
    echo "  [FAIL] /actuator/health returned status $CODE (expected 200)."
    exit 1
fi
echo "  -> Public health returned HTTP 200 OK."

echo -e "\n[Check 2/3] Testing Unauthenticated /actuator/env (Must return 401)..."
CODE_ENV=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8081/actuator/env || true)
if [ "$CODE_ENV" != "401" ]; then
    echo "  [FAIL] /actuator/env returned status $CODE_ENV (expected 401 Unauthorized)."
    exit 1
fi
echo "  -> Correctly blocked with HTTP 401 Unauthorized."

echo -e "\n[Check 3/3] Testing Authenticated /actuator/env..."
AUTH_CODE=$(curl -s -u admin:admin123 -o /dev/null -w "%{http_code}" http://localhost:8081/actuator/env || true)
if [ "$AUTH_CODE" != "200" ]; then
    echo "  [FAIL] Authenticated request returned status $AUTH_CODE (expected 200)."
    exit 1
fi
echo "  -> Authenticated /actuator/env successfully returned HTTP 200 OK."

echo "==========================================================="
echo " [PASS] JAVA-D2-102 Actuator & Security Validation Succeeded! "
echo "==========================================================="
