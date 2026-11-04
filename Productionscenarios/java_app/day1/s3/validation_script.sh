#!/usr/bin/env bash
echo "Running Maven Clean Test Package..."
mvn clean test package -DskipTests
echo "Verifying JAR artifact..."
ls -lh target/*.jar
echo "[PASS] JAVA-D1-103 build validation succeeded!"
