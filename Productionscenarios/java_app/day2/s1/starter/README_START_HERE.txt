========================================================================
LAB: JAVA-D2-101 - Spring Profiles & Configuration Binding
========================================================================
TASK SUMMARY:
1. Observe Expected Failure:
   Run: mvn spring-boot:run
   In a second terminal: curl -s http://localhost:8081/api/store-info
   Notice values are null or unbound.
2. Investigation:
   Check active profile in application.properties (spring.profiles.active=dev).
   Inspect StoreProperties.java and note missing annotations.
3. Resolution:
   - Add @Component and @ConfigurationProperties(prefix = "store") to StoreProperties.java
   - Verify properties in application-dev.properties match fields.
   - Run validation_script.ps1 / .sh to verify PASS.
========================================================================
