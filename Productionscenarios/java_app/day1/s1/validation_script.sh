#!/usr/bin/env bash
set -e
echo "==================================================="
echo " Validating JAVA-D1-101: Monolith to Microservices "
echo "==================================================="

echo ""
echo "[Check 1/2] Testing Product Service on port 8082..."
if ! curl -s -f "http://localhost:8082/api/products/1" > /dev/null 2>&1; then
    echo "  [FAIL] Product Service is not running on port 8082."
    echo "  Action: Start product-service in a separate terminal: mvn spring-boot:run"
    exit 1
fi
echo "  -> Product Service is UP."

echo ""
echo "[Check 2/2] Testing Order Service on port 8081 creating order..."
res=$(curl -s -f -X POST "http://localhost:8081/api/orders?productId=1&quantity=2") || {
    echo "  [FAIL] Order Service is not running on port 8081 or inter-service request failed."
    echo "  Action: Start order-service in a separate terminal: mvn spring-boot:run"
    exit 1
}
echo "  -> Order Response: $res"

echo ""
echo "==================================================="
echo " [PASS] JAVA-D1-101 Validation Succeeded! "
echo "==================================================="
