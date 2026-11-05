========================================================================
LAB: JAVA-D3-102 - Tomcat & WildFly WAR Deployment
========================================================================
TASK SUMMARY:
1. Expected Failure:
   - Packaging default fat jar causes external container deployment errors.
   - SLF4J / Log4j library collisions trigger ClassCastException or LinkageError.
2. Resolution:
   - Configure pom.xml: <packaging>war</packaging>, exclude log4j-to-slf4j, scope tomcat provided.
   - Extend SpringBootServletInitializer in RetailServiceApplication.java.
   - Deploy WAR to Tomcat webapps/ and verify http://localhost:8080/retail-service/health-check.
   - Run validation_script.ps1 / .sh to verify PASS.
========================================================================
