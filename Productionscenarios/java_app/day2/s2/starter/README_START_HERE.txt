JAVA-D2-102: Actuator Health, Metrics, Info, Env & Endpoint Security
======================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. When requesting /actuator/health, custom details are missing:
   Only returns basic {"status":"UP"} without store diagnostics.
2. When accessing sensitive environment properties:
   GET http://localhost:8081/actuator/env
   Returns HTTP 404 (endpoint not exposed) OR exposes sensitive server variables publicly without authentication!

YOUR MISSION (Guidelines & Solve):
1. Expose health, info, metrics, env, and custom endpoints in application.properties.
2. Implement custom StoreHealthIndicator reporting 'Open for Student Orders'.
3. Build custom management @Endpoint(id = 'storeControl').
4. Configure Spring Security: permit /actuator/health and /actuator/info publicly,
   while requiring HTTP Basic Authentication and role ACTUATOR_ADMIN for all other /actuator/** paths.
