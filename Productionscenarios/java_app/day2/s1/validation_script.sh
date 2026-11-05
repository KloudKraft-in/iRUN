#!/bin/bash
set -e
echo "==================================================="
echo " Validating JAVA-D2-101: Spring Profiles & Binding "
echo "==================================================="

echo -e "\n[Check] Querying Store Info endpoint on http://localhost:8081/api/store-info..."
RES=$(curl -s --connect-timeout 5 "http://localhost:8081/api/store-info" || true)

if [ -z "$RES" ]; then
    echo "  [FAIL] Unable to connect to product-service on port 8081."
    exit 1
fi

echo "  -> Response: $RES"
if [[ "$RES" == *"null"* ]]; then
    echo "  [FAIL] Configuration values contain null or unbound fields."
    exit 1
fi

echo "==================================================="
echo " [PASS] JAVA-D2-101 Configuration Binding Succeeded! "
echo "==================================================="
