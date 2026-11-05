========================================================================
LAB: JAVA-D3-101 - Spring Cloud Centralized Config & @RefreshScope
========================================================================
TASK SUMMARY:
1. Expected Failure:
   - Config Server fails to serve configurations if @EnableConfigServer is missing.
   - Retail Client values do not update dynamically when git repo changes without @RefreshScope.
2. Resolution:
   - Configure @EnableConfigServer on ConfigServerApplication.
   - Add @RefreshScope on DiscountController in retail-client.
   - Trigger POST http://localhost:8083/actuator/refresh to reload properties without restart.
   - Run validation_script.ps1 / .sh to verify PASS.
========================================================================
