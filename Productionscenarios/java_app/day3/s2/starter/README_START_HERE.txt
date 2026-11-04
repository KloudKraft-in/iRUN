JAVA-D3-102: Tomcat & WildFly WAR Deployment & Classpath Conflict
====================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. Missing Servlet Initializer:
   WAR deployed to Tomcat or WildFly fails to start the Spring context (HTTP 404).
2. Transitive Dependency / ClassLoader Collision:
   Simulated duplicate JSON or logging library on classpath throws:
   "java.lang.NoSuchMethodError" or "java.lang.LinkageError: loader constraint violation".

YOUR MISSION (Guidelines & Solve):
1. Configure RetailServiceApplication extending SpringBootServletInitializer.
2. Package application as WAR with embedded tomcat marked <scope>provided</scope>.
3. Run 'mvn dependency:tree' to pinpoint conflicting duplicate libraries.
4. Add <exclusion> tags in pom.xml to eliminate duplicate versions.
5. Deploy cleanly to Apache Tomcat 10.1 (webapps/) and WildFly 30 (standalone/deployments/).
