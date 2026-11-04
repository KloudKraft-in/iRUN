JAVA-D2-101: Spring Profiles, YAML vs Properties, Configuration Binding
======================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
When you start the application and test the configuration endpoint:
  GET http://localhost:8081/api/store-info
Expected Result:
  Returns unconfigured nulls or 500 Internal Server Error because
  StoreProperties is not annotated with @ConfigurationProperties(prefix = "store")
  and environment-specific profile properties (application-dev.properties, application-prod.properties)
  are missing or not bound!

YOUR MISSION (Guidelines & Solve):
1. Create StoreProperties with @Component and @ConfigurationProperties(prefix = "store").
2. Create application-dev.properties (discount=15) and application-prod.properties (discount=5).
3. Create StoreInfoController injecting StoreProperties and @Value("${store.welcome.message}").
4. Verify dynamic profile activation via --spring.profiles.active=dev and export SPRING_PROFILES_ACTIVE=prod.
