#!/usr/bin/env bash
echo "Validating Centralized Config Server on port 8888..."
curl -s -f http://localhost:8888/retail-service/dev || { echo "[FAIL] Config Server not responding"; exit 1; }
echo ""
echo "Validating Retail Client Discount on port 8083..."
curl -s -f http://localhost:8083/discount || { echo "[FAIL] Retail client not responding"; exit 1; }
echo ""
echo "[PASS] JAVA-D3-101 Spring Cloud Config validation succeeded!"
