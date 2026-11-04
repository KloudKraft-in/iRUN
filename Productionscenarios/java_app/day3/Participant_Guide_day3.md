# Java Application Operations - Participant Lab Guide (Day 3)

## Hands-On Production Scenarios, Troubleshooting & Resolution Guidelines

---

## 1. Module-Wise Setup Requirements

All lab scenarios run natively on your training VM or local workstation. Ensure the following tools and prerequisites are in place before starting.

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
| **Apache Tomcat** | Tomcat 10.1 (Jakarta EE 10) | `/opt/tomcat10/bin/version.sh` | External servlet container WAR deployment |
| **WildFly** | WildFly 30.0.1.Final | `/opt/wildfly/bin/standalone.sh` | Enterprise Java application server deployment |

### Port Allocation & Reservation

Ensure the following ports are unoccupied before launching exercises:

- `8080`: Apache Tomcat / Retail Service WAR & Heap Diagnostics  
- `8083`: Retail Client Application  
- `8888`: Spring Cloud Centralized Config Server  
- `9990`: WildFly Management Console & Deployment Port  

---

## 2. Common Instructions for Trainers and Participants

### Standard Lab Workflow

Every scenario in this training follows a rigorous **Simulation & Troubleshooting Cycle**:

1. **Setup & Template Fetch**:
   - Clone the repository and navigate to the scenario folder.
2. **Execute Initial Validation (Reproduce Failure)**:
   - Run the scenario validation script or application launch command.
   - Observe and record the failure before altering any code or configuration.
3. **Step-by-Step Investigation**:
   - Inspect configuration files, check network ports, and analyze logs.
4. **Implement the Solution (Solve)**:
   - Complete the TODO markers in the boilerplate files.
5. **Re-Test & Self-Validate**:
   - Re-run the validation script to verify all checks pass.

---

## 3. Day 3: Production Deployment, JVM Tuning & Troubleshooting

### Scenario JAVA-D3-101: Spring Cloud Centralized Config & @RefreshScope

- **Ticket ID:** `JAVA-D3-101` | **Category:** Cloud Configuration & Distributed Systems | **Suggested Time:** 60 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-1_JAVA-D3-101_Spring_Cloud_Centralized_Config/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day3/s1` to fetch boilerplate code

#### A. Expected Failure (Reproduction Steps)

1. Launch `config-server` on port 8888 and `retail-client` on port 8083:

```sh
cd config-server && mvn spring-boot:run
cd ../retail-client && mvn spring-boot:run
```

2. Query initial discount:

```sh
curl -s http://localhost:8083/discount
```

3. Modify the configuration value in the Git repository without restarting services, then trigger `POST http://localhost:8083/actuator/refresh`.  
4. **Observed Error:** The returned value does not update dynamically and remains stale, because `@RefreshScope` is absent from the controller.

#### B. Step-by-Step Investigation Guidelines

- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8888 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8888 :8083"`
- Inspect `config-server/src/main/resources/application.yml` for Git repository path and label.
- Verify `ConfigServerApplication.java` has `@EnableConfigServer`.
- Inspect `DiscountController.java` in `retail-client` and observe how `@Value("${store.discount}")` is bound.

#### C. Action Items to Solve

1. In `ConfigServerApplication.java`, add `@EnableConfigServer`.  
2. In `DiscountController.java`, add `@RefreshScope` to enable runtime dynamic reconfiguration.  
3. In `retail-client/src/main/resources/application.properties`, expose actuator refresh endpoint (`management.endpoints.web.exposure.include=refresh,health`).  
4. Trigger `POST http://localhost:8083/actuator/refresh` and verify the discount updates without service restarts.  
5. Run `validation_script.ps1` (or `.sh`) to confirm all checks PASS.

---

### Scenario JAVA-D3-102: Tomcat & WildFly WAR Deployment & Dependency Conflicts

- **Ticket ID:** `JAVA-D3-102` | **Category:** Enterprise App Server Operations | **Suggested Time:** 60 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-2_JAVA-D3-102_Tomcat_WildFly_WAR_Deployment/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day3/s2` to fetch boilerplate code

#### A. Expected Failure (Reproduction Steps)

1. Build the WAR application without excluding conflicting logging libraries or servlet dependencies:

```sh
mvn clean package
```

2. Deploy the WAR into Apache Tomcat or WildFly:

```sh
cp target/retail-service.war /opt/tomcat10/webapps/
```

3. **Observed Error:** Deployment fails with `LinkageError`, `ClassCastException`, or SLF4J binding collision on server startup.

#### B. Step-by-Step Investigation Guidelines

- Run `mvn dependency:tree` to identify conflicting transitives.
- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8080 :9990"`
- Review `pom.xml` for `<packaging>war</packaging>` and embedded Tomcat `<scope>provided</scope>`.
- Check for duplicate logging bridges (such as `log4j-to-slf4j`) conflicting with JBoss LogManager.

#### C. Action Items to Solve

1. Configure `pom.xml` with `<packaging>war</packaging>`.  
2. Set `spring-boot-starter-tomcat` to `<scope>provided</scope>`.  
3. Exclude `log4j-to-slf4j` from `spring-boot-starter-web`.  
4. Ensure `RetailServiceApplication` extends `SpringBootServletInitializer`.  
5. Deploy `retail-service.war` and access `http://localhost:8080/retail-service/health-check`.  
6. Run `validation_script.ps1` (or `.sh`) to verify HTTP 200 OK.

---

### Scenario JAVA-D3-103: JVM Heap Tuning, Graceful Shutdown & Thread Dumps

- **Ticket ID:** `JAVA-D3-103` | **Category:** JVM Tuning & Reliability Engineering | **Suggested Time:** 60 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-3_JAVA-D3-103_JVM_Heap_Tuning_Thread_Dumps/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day3/s3` to fetch boilerplate code

#### A. Expected Failure (Reproduction Steps)

1. Launch the service with default unconstrained memory settings and immediate termination.  
2. Send a 15-second long-running request to `/checkout`:

```sh
curl "http://localhost:8080/checkout"
```

3. Immediately issue a `SIGTERM` / termination command to the application.  
4. **Observed Error:** The active connection is aborted abruptly (`Connection reset by peer`), dropping customer transactions without graceful completion.

#### B. Step-by-Step Investigation Guidelines

- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8080 :8083"`
- Inspect running JVM process ID using `jcmd -l`.
- Inspect heap configuration using `jcmd <PID> GC.heap_info`.
- Inspect active thread states using `jstack <PID>` or `jcmd <PID> Thread.print`.

#### C. Action Items to Solve

1. Configure graceful shutdown in `application.properties`:  
   `server.shutdown=graceful`  
   `spring.lifecycle.timeout-per-shutdown-phase=20s`  
2. Launch the application with production JVM memory ergonomics:  
   `java -Xms256m -Xmx512m -XX:+HeapDumpOnOutOfMemoryError -jar target/retail-service.jar`  
3. Capture thread dumps during an in-flight request to verify graceful drainage.  
4. Run `validation_script.ps1` (or `.sh`) to confirm all checks PASS.
