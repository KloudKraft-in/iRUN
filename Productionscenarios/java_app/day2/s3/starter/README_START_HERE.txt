JAVA-D2-103: Startup Diagnostics & HikariCP Pool Management
============================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. Port Collision:
   "Port 8081 was already in use. Failed to start bean 'webServerStartStop'"
2. Missing Property Injection Failure (BeanCreationException):
   Injecting @Value("${store.timeout}") without a default value when property is omitted:
   "org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'storeService':
    Could not resolve placeholder 'store.timeout' in value '${store.timeout}'"
3. Hikari Connection Pool Exhaustion:
   Under load, default unmonitored pools can run out of connections leading to SQLTransientConnectionException.

YOUR MISSION (Guidelines & Solve):
1. Resolve port collision using server.port configuration.
2. Provide safe default values for injected properties: @Value("${store.timeout:5000}").
3. Configure HikariCP parameters: maximum-pool-size=2, connection-timeout=3000.
4. Implement PoolDiagnosticsController to monitor active vs idle connections and verify timeout handling.
