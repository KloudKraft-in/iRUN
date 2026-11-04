JAVA-D1-103: Maven, Gradle and Dependency Management
===================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
Running build without standardized wrapper or with conflicting transitive dependencies:
  "mvn: command not found" (missing wrapper) OR build failures due to unpinned dependency versions.

YOUR MISSION (Guidelines & Solve):
1. Lock down all dependency versions and plugins in pom.xml.
2. Execute 'mvn clean test package' and inspect target/*.jar.
3. Generate dependency tree using 'mvn dependency:tree > deps.txt'.
4. Review equivalent build.gradle configuration and compare lifecycle phases.
