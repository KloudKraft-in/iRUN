JAVA-D1-102: JAR/WAR Deployment and Servlet Container
===============================================================================
EXPECTED FAILURE 1 (Port Collision):
1. Ensure Apache Tomcat is running on port 8080:
     curl http://localhost:8080
2. In terminal, navigate to jar-demo and start the application:
     cd starter/jar-demo
     mvn clean package
     java -jar target/jar-demo-0.0.1-SNAPSHOT.jar
3. OBSERVED FAILURE:
     APPLICATION FAILED TO START
     Web server failed to start. Port 8080 was already in use.

EXPECTED FAILURE 2 (Tomcat 404):
1. Build war-demo without extending SpringBootServletInitializer:
     cd starter/war-demo
     mvn clean package
2. Deploy target/war-demo.war to Tomcat's webapps/ folder.
3. Access: http://localhost:8080/war-demo/api/demo
4. OBSERVED FAILURE:
     HTTP 404 Not Found (Tomcat cannot bootstrap the Spring ApplicationContext)

YOUR MISSION (Guidelines & Solve):
1. In jar-demo/src/main/resources/application.properties, change server.port to 8083.
2. In war-demo/pom.xml:
   - Change <packaging> from jar to war
   - Add spring-boot-starter-tomcat with <scope>provided</scope>
3. In war-demo/src/main/java/com/labskraft/demo/WarDemoApplication.java:
   - Extend SpringBootServletInitializer
   - Override configure(SpringApplicationBuilder)
4. Package and deploy war-demo.war to Tomcat webapps/ directory.
5. Run validation:
   .\validation_script.ps1 (Windows) or ./validation_script.sh (Ubuntu)
===============================================================================
