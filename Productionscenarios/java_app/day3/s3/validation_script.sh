#!/usr/bin/env bash
echo "Validating Retail Service Health..."
curl -s -f http://localhost:8080/health-check || { echo "[FAIL] Retail service not responding"; exit 1; }
echo ""
echo "Capturing JVM Thread Dump using jcmd..."
PID=$(jcmd | grep retail-service | awk '{print $1}')
if [ -n "$PID" ]; then
    jcmd $PID Thread.print | head -n 30
    echo "[PASS] Live Thread dump captured for PID $PID"
else
    echo "[INFO] retail-service PID not found; start app with java -jar target/*.jar"
fi
echo "[PASS] JAVA-D3-103 validation complete!"
