# Java Application Operations - Participant Lab Guide (Day 2)

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
| **Version Control** | Git 2.30+ | `git --version` | Source control and repository management |
| **Network Tools** | curl, lsof / netstat | `curl --version` | API testing, HTTP REST requests, port verification |

### Port Allocation & Reservation

Ensure the following ports are unoccupied before launching exercises:

- `8081`: Product Service, Actuator Endpoints & Pool Diagnostics (Day 2)

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

## 3. Day 2: Spring Boot Configuration, Monitoring & Diagnostics

### Scenario JAVA-D2-101: Spring Profiles and Configuration Binding

- **Ticket ID:** `JAVA-D2-101` | **Category:** Configuration Architecture | **Suggested Time:** 50 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-1_JAVA-D2-101_Spring_Profiles_and_Binding/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day2/s1` to fetch boilerplate code

#### A. Expected Failure (Reproduction Steps)

1. Navigate to the starter directory and launch `product-service` on port 8081:

```sh
mvn spring-boot:run
```

2. In a second terminal tab, query the store info endpoint:

```sh
curl -s http://localhost:8081/api/store-info
```

3. **Observed Error:** The JSON response contains null or zero unbound fields:

```json
{"environment":null,"discount":0,"welcomeMessage":null,"boundWelcomeMessage":null}
```

*Why this fails:* The configuration class `StoreProperties` is not registered as a Spring bean (`@Component`) and lacks `@ConfigurationProperties(prefix = "store")`, so property values from `application-dev.properties` remain unbound.

#### B. Step-by-Step Investigation Guidelines

- Inspect `src/main/resources/application.properties` and verify `spring.profiles.active=dev`.
- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8081"`
- Review `StoreProperties.java` and confirm if Spring Boot property binding annotations are present.
- Inspect `StoreInfoController.java` to verify whether constructor injection binds `StoreProperties` correctly.

#### C. Action Items to Solve

1. Open `StoreProperties.java` and annotate the class with `@Component` and `@ConfigurationProperties(prefix = "store")`.  
2. Ensure getters and setters exist for `environment`, `discount`, and `welcomeMessage`.  
3. In `StoreInfoController.java`, inject `StoreProperties` via constructor and return the bound properties.  
4. Restart the application and run `validation_script.ps1` (or `validation_script.sh`) to confirm all checks PASS.

---

### Scenario JAVA-D2-102: Actuator Observability & Endpoint Security

- **Ticket ID:** `JAVA-D2-102` | **Category:** Observability & Endpoint Security | **Suggested Time:** 50 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-2_JAVA-D2-102_Actuator_Metrics_and_Security/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day2/s2` to fetch boilerplate code

#### A. Expected Failure (Reproduction Steps)

1. Launch the application:

```sh
mvn spring-boot:run
```

2. Attempt to query sensitive actuator environment variables without credentials:

```sh
curl -i http://localhost:8081/actuator/env
```

3. **Observed Security Flaw / Error:** If unconfigured, sensitive environment variables and internal server properties are exposed publicly (HTTP 200 instead of HTTP 401 Unauthorized), or public health probes fail.

#### B. Step-by-Step Investigation Guidelines

- Inspect `application.properties` for `management.endpoints.web.exposure.include`.
- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8081"`
- Inspect `SecurityConfig.java` to verify `SecurityFilterChain` rules for `/actuator/**`.
- Confirm `InMemoryUserDetailsManager` defines user `admin` with password `admin123` and role `ACTUATOR_ADMIN`.

#### C. Action Items to Solve

1. In `SecurityConfig.java`, permit unauthenticated access to `/actuator/health` and `/actuator/info`.  
2. Restrict all other actuator endpoints (`/actuator/**`) to role `ACTUATOR_ADMIN` with HTTP Basic authentication.  
3. Implement `StoreHealthIndicator` implementing `HealthIndicator` returning `Health.up()`.  
4. Implement custom Actuator endpoint `StoreControlEndpoint` with `@Endpoint(id = "storeControl")`.  
5. Execute `validation_script.ps1` (or `.sh`) to verify health is public (200 OK), unauthenticated env is blocked (401), and authenticated env returns 200 OK.

---

### Scenario JAVA-D2-103: Startup Diagnostics & HikariCP Pool Management

- **Ticket ID:** `JAVA-D2-103` | **Category:** Diagnostics & Database Connection Pooling | **Suggested Time:** 50 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-3_JAVA-D2-103_Startup_Diagnostics_HikariCP_Pool/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day2/s3` to fetch boilerplate code

#### A. Expected Failure (Reproduction Steps)

1. Inspect an application configured with improperly sized connection pools or missing Hikari pool diagnostics.
2. Launch the application:

```sh
mvn spring-boot:run
```

3. Trigger concurrent database operations or query `/api/pool/status` when pool JMX beans are unconfigured or connections leak:

```sh
curl -s http://localhost:8081/api/pool/status
```

4. **Observed Error:** The endpoint returns `"Not a Hikari DataSource"` or database connection acquisition hangs.

#### B. Step-by-Step Investigation Guidelines

- Inspect `application.properties` and verify HikariCP pool parameters: `spring.datasource.hikari.maximum-pool-size=2`, `minimum-idle=1`, `connection-timeout=3000`.
- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8081"`
- In `PoolDiagnosticsController.java`, verify how `HikariDataSource` pool metrics (`activeConnections`, `idleConnections`, `totalConnections`) are extracted via `getHikariPoolMXBean()`.

#### C. Action Items to Solve

1. Configure HikariCP connection pool settings in `application.properties`.  
2. Implement `PoolDiagnosticsController` to query and expose active and idle pool connections.  
3. Run `validation_script.ps1` (or `.sh`) to verify successful HikariCP pool diagnostics reporting.
