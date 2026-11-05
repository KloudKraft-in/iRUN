JAVA-D1-103: Maven, Gradle and Dependency Management
===============================================================================
EXPECTED FAILURE ON INITIAL BUILD:
1. In terminal, navigate to order-service:
     cd starter/order-service
2. Run clean test and package:
     mvn clean package
3. OBSERVED FAILURE:
     [ERROR] Incompatible dependency version detected: Spring Framework 5.3.x (from Boot 2.7.0)
     collided with Java 17 / Jakarta EE servlet spec.
     [INFO] BUILD FAILURE
   Why this fails: The project has no parent POM and uses unpinned/drifted dependency versions.

YOUR MISSION (Guidelines & Solve):
1. In pom.xml:
   - Add spring-boot-starter-parent version 3.2.3
   - Remove explicit <version> tags from spring-boot-starter-web, test, and maven-plugin.
2. Run dependency tree analysis:
     mvn dependency:tree
3. Re-build the reproducible fat JAR:
     mvn clean test package -DskipTests
4. Review build.gradle in the same folder and document a 3-point comparison between
   Maven's declarative XML lifecycles and Gradle's task-based DAG execution.
5. Run validation:
   .\validation_script.ps1 (Windows) or ./validation_script.sh (Ubuntu)
===============================================================================
