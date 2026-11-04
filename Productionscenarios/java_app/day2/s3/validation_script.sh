#!/usr/bin/env bash
echo "Validating HikariCP Pool Diagnostics Endpoint..."
curl -s -f http://localhost:8081/api/pool/status || { echo "[FAIL] Pool status endpoint unreachable"; exit 1; }
echo ""
echo "[PASS] JAVA-D2-103 HikariCP Pool diagnostics validated!"
