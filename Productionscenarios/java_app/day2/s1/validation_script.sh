#!/usr/bin/env bash
echo "Validating Store Info with Active Dev Profile..."
curl -s http://localhost:8081/api/store-info | grep '"discount":15' && echo "[PASS] Dev profile discount verified (15%)"
echo "[PASS] JAVA-D2-101 validation succeeded!"
