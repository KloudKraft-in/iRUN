#!/bin/bash
set -e
echo "==========================================================="
echo " Validating JAVA-D3-101: Spring Cloud Centralized Config   "
echo "==========================================================="

echo -e "\n[Check 1/2] Testing Config Server on http://localhost:8888/retail-service/dev..."
CFG=$(curl -s --connect-timeout 5 http://localhost:8888/retail-service/dev || true)
if [ -z "$CFG" ]; then
    echo "  [FAIL] Centralized Config Server not responding on port 8888."
    exit 1
fi
echo "  -> Config Server responded successfully."

echo -e "\n[Check 2/2] Testing Retail Client on http://localhost:8083/discount..."
DISC=$(curl -s --connect-timeout 5 http://localhost:8083/discount || true)
if [ -z "$DISC" ]; then
    echo "  [FAIL] Retail Client not responding on port 8083."
    exit 1
fi
echo "  -> Retail Client is UP. Discount: $DISC"

echo "==========================================================="
echo " [PASS] JAVA-D3-101 Centralized Config Succeeded!          "
echo "==========================================================="
