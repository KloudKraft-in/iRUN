#!/bin/bash
set -e
echo "==========================================================="
echo " Validating JAVA-D2-103: Startup Diagnostics & HikariCP   "
echo "==========================================================="

echo -e "\n[Check] Testing HikariCP Pool Diagnostics on http://localhost:8081/api/pool/status..."
STATUS=$(curl -s --connect-timeout 5 http://localhost:8081/api/pool/status || true)

if [ -z "$STATUS" ]; then
    echo "  [FAIL] Unable to connect to Pool Diagnostics on port 8081."
    exit 1
fi

echo "  -> Pool Status: $STATUS"
echo "==========================================================="
echo " [PASS] JAVA-D2-103 HikariCP Diagnostics Succeeded!       "
echo "==========================================================="
