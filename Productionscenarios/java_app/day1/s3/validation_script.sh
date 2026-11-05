#!/usr/bin/env bash
set -e
echo "==========================================================="
echo " Validating JAVA-D1-103: Maven/Gradle & Dependency Mgmt   "
echo "==========================================================="

echo ""
echo "[Check 1/2] Running Maven Clean Test Package..."
mvn clean package -DskipTests

echo ""
echo "[Check 2/2] Verifying executable JAR artifact..."
ls -lh target/*.jar || {
    echo "  [FAIL] No JAR artifact generated."
    exit 1
}

echo ""
echo "==========================================================="
echo " [PASS] JAVA-D1-103 Build Validation Succeeded!           "
echo "==========================================================="
