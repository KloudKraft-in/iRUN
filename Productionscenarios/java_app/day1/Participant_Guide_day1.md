# Java Application Operations \- Participant Lab Guide

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines

---

## 1\. Module-Wise Setup Requirements

All lab scenarios are designed to run natively on your training VM or local workstation. Ensure the following tools and prerequisites are in place before starting.

### System Hardware & Operating System

- **Operating System:** Ubuntu 20.04 / 22.04 / 24.04 LTS, Windows 10 / 11, or macOS.  
- **Hardware Allocation:** Minimum 4 vCPU, 8 GB RAM, 30 GB free disk space.  
- **IDE / Editor:** Visual Studio Code (recommended) with the **Extension Pack for Java**, Eclipse, or IntelliJ IDEA.

### Required Software & Toolchain

| Component | Supported Version | Verification Command | Purpose |
| :---- | :---- | :---- | :---- |
| **Java JDK** | OpenJDK 17 LTS or 21 LTS | `java -version`, `javac -version` | Core Java runtime and compiler |
| **JDK Diagnostics** | Included in JDK | `jcmd -l`, `jstack -h` | Heap diagnostics, thread dump inspection |
| **Apache Maven** | Maven 3.9+ | `mvn -version` | Build lifecycle, dependency resolution, packaging |
| **Version Control** | Git 2.30+ | `git --version` | Source control, local Git config repo for Day 3 |
| **Network Tools** | curl, lsof / netstat | `curl --version` | API testing, HTTP REST requests, port verification |
| **Apache Tomcat** | Tomcat 10.1 (Jakarta EE 10\) | `/opt/tomcat10/bin/version.sh` | External servlet container WAR deployment |
| **WildFly** | WildFly 30.0.1.Final | `/opt/wildfly/bin/standalone.sh` | Enterprise Java application server deployment |

### Port Allocation & Reservation

Ensure the following ports are unoccupied before launching exercises:

- `8080`: Default HTTP / Apache Tomcat / Day 1 WAR & Day 3 WAR  
- `8081`: Order Service (Day 1\) / Product Service & Actuator (Day 2\)  
- `8082`: Product Lookup Service (Day 1\)  
- `8083`: Standalone Executable JAR (Day 1\) / Retail Client App (Day 3\)  
- `8888`: Spring Cloud Centralized Config Server (Day 3\)  
- `9990`: WildFly Management Console & Deployment Port (Day 3\)

---

## 2\. Common Instructions for Trainers and Participants

### Standard Lab Workflow

Every scenario in this training follows a rigorous **Simulation & Troubleshooting Cycle**:

```
[1. Download Artifacts] ──> [2. Open in VS Code] ──> [3. Run Validation / Start App]
                                                                  │
                                                                  ▼
[6. Verify & Submit]   <── [5. Apply Solve Steps] <── [4. Observe Expected Failure]
                                                              (Check Guidelines)
```

1. **Artifact Distribution & Setup**:  
   - Download the scenario bundle (`Day-X_Artifacts.zip` or clone from repository).  
   - Extract the files into your designated workspace (e.g., `~/day1`, `~/day2`, `~/day3` or `C:\day1`, `C:\day2`, `C:\day3`).  
   - Launch **Visual Studio Code** and select **File \-\> Open Folder...** pointing to the scenario root.  
2. **Execute Initial Validation Script / Start Application**:  
   - In the VS Code integrated terminal (```Ctrl + \``), execute the scenario validation script (```./validation\_script.sh`on Linux or`.\\validation\_script.ps1\` on Windows).  
   - Alternatively, attempt to launch the application with `mvn spring-boot:run`.  
3. **The Expected Failure Principle**:  
   - **Crucial Note:** Every scenario is intentionally provided in a broken, misconfigured, or incomplete starter state.  
   - You **MUST** run the initial test and observe the **Expected Failure** before altering any code or configuration\!  
   - Examples of expected failures include: *Port collision (8080 already in use)*, *Connection refused (500 Internal Server Error)*, *BeanCreationException (missing property)*, *401 Unauthorized (unsecured Actuator)*, *LinkageError (duplicate dependency collision)*, or *Connection reset (ungraceful shutdown)*.  
4. **Troubleshooting & Investigation**:  
   - Read the console logs, exception stack traces, and HTTP error codes.  
   - Consult the **Step-by-Step Investigation Guidelines** in this guide.  
5. **Implement the Solution (Solve)**:  
   - Apply the required Java code changes, property configurations, or build modifications based on the guidelines.  
6. **Re-Test & Self-Validate**:  
   - Re-run the validation script to confirm all checks pass.  
   - Capture the terminal output evidence and save to your lab evidence file.

---

## 3\. Day 1: Enterprise Architecture & Spring Boot Fundamentals

### Scenario JAVA-D1-101: Monolith to Two REST Microservices

- **Ticket ID:** `JAVA-D1-101` \| **Category:** Architecture \| **Suggested Time:** 75 mins  
- **Starter Artifacts Location:** `Artifacts_Sorted/Day-1/Scenario-1_JAVA-D1-101_Monolith_to_Microservices/starter`  
- Template Location:&nbsp;

#### Setup: Fetch template details

- Execute `git clone https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day1/s1`  to fetch boilerplate code

#### A. Expected Failure (Reproduction Steps)

1. In VS Code, navigate to `order-service` and start the service on port 8081:

```sh
mvn spring-boot:run
```

2. Open a second terminal tab and trigger an order creation request:

```sh
curl -X POST "http://localhost:8081/api/orders?productId=1&quantity=2"
```

3. **Observed Error:** The request fails with HTTP 500:

```
org.springframework.web.client.ResourceAccessException: I/O error on POST request for "http://localhost:8082/api/products/1":
Connection refused: connect
```

*Why this fails:* The monolithic order application has been decoupled, but the dependent `product-service` on port 8082 has not yet been built or launched.

#### B. Step-by-Step Investigation Guidelines

- Inspect `order-service/src/main/resources/application.properties` and note the `product.service.url` configuration.  
- Check which network ports are currently open using `netstat -tuln | grep 8082` or `Get-NetTCPConnection -LocalPort 8082`.  
- Review the REST contract required by `order-service`: it expects a JSON payload from `GET /api/products/{id}` with fields `{ "id": 1, "name": "...", "price": ... }`.

#### C. Action Items to Solve

1. Create a lightweight Spring Boot application `product-service` running on port 8082 (`server.port=8082`).  
2. Implement a `Product` domain model (record or class) containing `id`, `name`, and `price`.  
3. Implement `ProductController` annotated with `@RestController` and `@RequestMapping("/api/products")`.  
4. Add a `GET /{id}` endpoint that looks up products from an in-memory repository and returns HTTP 404 (`ResponseStatusException`) if not found.  
5. Start both `product-service` (port 8082\) and `order-service` (port 8081).  
6. Execute `validation_script.sh` (or `.ps1`) to verify successful inter-service communication.

---

### Scenario JAVA-D1-102: JAR/WAR Deployment and Servlet Container

- **Ticket ID:** `JAVA-D1-102` \| **Category:** Deployment Architecture \| **Suggested Time:** 50 mins  
- **Starter Artifacts Location:** `Artifacts_Sorted/Day-1/Scenario-2_JAVA-D1-102_JAR_WAR_Tomcat_Deployment/starter`

#### Setup: Fetch template details

- Execute `git clone https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day1/s2`  to fetch boilerplate code

#### A. Expected Failure (Reproduction Steps)

1. Attempt to launch the standalone executable JAR without changing default ports while Apache Tomcat is running on port 8080:

```sh
java -jar target/demo-app.jar
```

**Observed Error:**

```
APPLICATION FAILED TO START
Description: Web server failed to start. Port 8080 was already in use.
Action: Identify and stop the process that's listening on port 8080 or configure this application to listen on another port.
```

2. Build a standard Spring Boot application as a `.war` file without configuring the servlet initializer and copy to Tomcat's `webapps/` directory.

3. Access `http://localhost:8080/war-demo/api/demo`: **Observed Error:** HTTP 404 Not Found (Tomcat cannot bootstrap the Spring ApplicationContext).

#### B. Step-by-Step Investigation Guidelines

- Check which process is occupying port 8080 using `lsof -i :8080` (Linux) or `netstat -ano | findstr 8080` (Windows).  
- Inspect Tomcat log files in `CATALINA_HOME/logs/catalina.out` and `localhost.<date>.log`.  
- Review standard Jakarta EE servlet requirements for external containers: external containers require a servlet initialization hook to bootstrap Spring without `public static void main()`.

#### C. Action Items to Solve

1. Configure `jar-demo` to listen on an alternate, non-conflicting port (`server.port=8083`) in `application.properties`.  
2. In `war-demo/pom.xml`, specify `<packaging>war</packaging>` and set `spring-boot-starter-tomcat` to `<scope>provided</scope>` so embedded Tomcat classes are not packaged inside the WAR.  
3. Modify the primary `@SpringBootApplication` class to extend `SpringBootServletInitializer` and override the `configure(SpringApplicationBuilder)` method.  
4. Package the archive with `mvn clean package` and copy the resulting `war-demo.war` into `$CATALINA_HOME/webapps/`.  
5. Verify both endpoints respond with HTTP 200:  
   - Standalone JAR: `http://localhost:8083/api/demo`  
   - Tomcat Deployed WAR: `http://localhost:8080/war-demo/api/demo`

---

### Scenario JAVA-D1-103: Maven, Gradle and Dependency Management

- **Ticket ID:** `JAVA-D1-103` \| **Category:** Build & Dependency Management \| **Suggested Time:** 45 mins  
- **Starter Artifacts Location:** `Artifacts_Sorted/Day-1/Scenario-3_JAVA-D1-103_Maven_Gradle_Dependency_Management/starter`

#### Setup: Fetch template details

- Execute `git clone https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day1/s3`  to fetch boilerplate code

#### A. Expected Failure (Reproduction Steps)

1. Inspect an unstandardized project containing unversioned plugins and unmanaged dependencies.  
2. Attempt to run tests using inconsistent environment commands without the Maven wrapper (`mvnw`).  
3. Notice that builds on different machines pull different minor library releases, leading to intermittent unit test failures or `NoSuchMethodError`.

#### B. Step-by-Step Investigation Guidelines

- Run `mvn dependency:tree` to produce a complete hierarchy of compile, runtime, and test dependencies.  
- Look for mismatched parent POM versions and unpinned dependencies.  
- Compare the declarative XML lifecycle of Maven (`validate`, `compile`, `test`, `package`, `verify`, `install`) with Gradle's task-based DAG execution model (`build.gradle`).

#### C. Action Items to Solve

1. Standardize `pom.xml` using `spring-boot-starter-parent` (version 3.2.x) to manage transitive dependency versions centrally.  
2. Verify repeatable builds using `mvn clean test package -DskipTests`.  
3. Inspect `target/*.jar` to verify the fat JAR structure (`BOOT-INF/classes`, `BOOT-INF/lib`, and `org/springframework/boot/loader`).  
4. Generate and save the dependency tree:

```sh
mvn dependency:tree > dependency-tree.txt
```

5. Review the provided `build.gradle` and document a 3-point operational comparison between Maven and Gradle.

---

