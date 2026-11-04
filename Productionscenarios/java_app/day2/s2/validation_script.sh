#!/usr/bin/env bash
echo "1. Checking Public /actuator/health (Should be HTTP 200 without auth)..."
curl -s -i http://localhost:8081/actuator/health | grep "200" || { echo "[FAIL] Public health failed"; exit 1; }
echo ""
echo "2. Checking Secured /actuator/env without auth (Should be HTTP 401 Unauthorized)..."
curl -s -i http://localhost:8081/actuator/env | grep "401" || { echo "[FAIL] Expected 401 Unauthorized"; exit 1; }
echo ""
echo "3. Checking Secured /actuator/env with admin credentials (Should be HTTP 200)..."
curl -s -u admin:admin123 -i http://localhost:8081/actuator/env | grep "200" || { echo "[FAIL] Authenticated access failed"; exit 1; }
echo ""
echo "[PASS] JAVA-D2-102 Actuator & Security validation succeeded!"
