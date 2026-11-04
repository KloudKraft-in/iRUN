JAVA-D1-102: JAR/WAR Deployment and External Tomcat 10.1
=========================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. Port Collision: The executable JAR defaults to port 8080. If Tomcat or another service is running on 8080:
   "Port 8080 was already in use. Failed to start bean 'webServerStartStop'"
2. WAR Deployment Failure: Deploying an unconfigured Spring Boot WAR to Tomcat 10.1 without extending
   SpringBootServletInitializer results in:
   HTTP 404 Not Found (Spring application context fails to bootstrap inside Tomcat servlet container).

YOUR MISSION (Guidelines & Solve):
1. Configure executable JAR to run on custom port 8083 (server.port=8083).
2. Modify WAR main class to extend SpringBootServletInitializer and override configure().
3. Mark spring-boot-starter-tomcat dependency as <scope>provided</scope> in pom.xml.
4. Deploy the built WAR to external Apache Tomcat 10.1 webapps/ and verify HTTP 200 on /api/demo.
