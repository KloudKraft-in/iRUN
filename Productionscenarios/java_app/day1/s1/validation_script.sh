#!/usr/bin/env bash
echo "Validating Product Service on port 8082..."
curl -s -f http://localhost:8082/api/products/1 || { echo "[FAIL] Product service not responding on 8082"; exit 1; }
echo ""
echo "Creating Order via Order Service on port 8081..."
curl -s -f -X POST "http://localhost:8081/api/orders?productId=1&quantity=2" || { echo "[FAIL] Order creation failed"; exit 1; }
echo ""
echo "[PASS] JAVA-D1-101 validation succeeded!"
