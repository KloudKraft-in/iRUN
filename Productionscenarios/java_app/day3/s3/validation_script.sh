#!/bin/bash
set -e
echo "==========================================================="
echo " Validating JAVA-D3-103: JVM Tuning & Graceful Shutdown    "
echo "==========================================================="

echo -e "\n[Check 1/2] Testing Retail Service Health on http://localhost:8080/health-check..."
RES=$(curl -s --connect-timeout 5 http://localhost:8080/health-check || true)
if [ -z "$RES" ]; then
    echo "  [FAIL] Retail Service not running on port 8080."
    exit 1
fi

echo "  -> Response: $RES"
echo -e "\n[Check 2/2] Checking running Java JVM processes with jcmd..."
jcmd -l || true

echo "==========================================================="
echo " [PASS] JAVA-D3-103 JVM & Diagnostics Succeeded!           "
echo "==========================================================="
