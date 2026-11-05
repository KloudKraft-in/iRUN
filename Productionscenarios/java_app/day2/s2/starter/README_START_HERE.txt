========================================================================
LAB: JAVA-D2-102 - Actuator Metrics & Security
========================================================================
TASK SUMMARY:
1. Expected Failure:
   curl -i http://localhost:8081/actuator/env
   Without security, credentials and environment variables are dangerously exposed.
2. Resolution:
   - Configure SecurityConfig.java to enforce HTTP Basic authentication for /actuator/**
   - Expose public health on /actuator/health
   - Implement custom StoreHealthIndicator and custom @Endpoint StoreControlEndpoint
   - Run validation_script.ps1 / .sh to verify PASS.
========================================================================
