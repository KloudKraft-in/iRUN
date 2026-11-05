# Java Application Operations - Master Instructor Solution Guide (Day 3)

## Day 3: Production Deployment, JVM Tuning & Troubleshooting

---

## 1. Common Trainer Instructions & Pedagogy

### Lab Objectives & Concepts
- Spring Cloud Centralized Config Server architecture, Git backend, and `@RefreshScope` dynamic updates.
- External enterprise servlet containers (Apache Tomcat 10.1 & WildFly 30), WAR packaging, and ClassLoader dependency exclusions.
- Production JVM memory ergonomics (`-Xms`, `-Xmx`), thread dump diagnostics (`jcmd`, `jstack`), and zero-downtime graceful shutdown.

### Pre-Flight Verification
- Ensure ports `8080`, `8083`, `8888`, and `9990` are free before commencing sessions.

---

## 2. Day 3 Scenario Solutions

### Scenario JAVA-D3-101: Spring Cloud Centralized Config & @RefreshScope

- **Ticket ID:** `JAVA-D3-101` | **Category:** Cloud Configuration | **Time:** 60 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-1_JAVA-D3-101_Spring_Cloud_Centralized_Config/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day3/s1` to fetch boilerplate code

#### Step 0: Expected Failure (Reproduction Steps)

1. Launch `config-server` on port 8888 and `retail-client` on port 8083:

```sh
cd config-server && mvn spring-boot:run
cd ../retail-client && mvn spring-boot:run
```

2. Attempt dynamic configuration refresh without `@RefreshScope`.

#### Step-by-Step Investigation Guidelines

- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8888 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8888 :8083"`

#### Full Solution Code & Configuration

**1. Config Server Main Application (`ConfigServerApplication.java`):**

```java
package com.example.configserver;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.config.server.EnableConfigServer;

@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ConfigServerApplication.class, args);
    }
}
```

**2. Retail Client Refresh Controller (`DiscountController.java`):**

```java
package com.example.retail;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RefreshScope
public class DiscountController {
    @Value("${store.discount:0}")
    private String discount;

    @GetMapping("/discount")
    public String discount() {
        return discount;
    }
}
```

#### Visual Verification Mockup

```text
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [SPRING CLOUD CONFIG VERIFICATION]                                                      |
+----------------------------------------------------------------------------------------------------+
$ curl -s http://localhost:8888/retail-service/dev
{"name":"retail-service","profiles":["dev"],"propertySources":[...]}

$ curl -s http://localhost:8083/discount
15

[PASS] JAVA-D3-101 Centralized Config Succeeded!
+----------------------------------------------------------------------------------------------------+
```

---

### Scenario JAVA-D3-102: Tomcat & WildFly WAR Deployment & Dependency Conflicts

- **Ticket ID:** `JAVA-D3-102` | **Category:** App Server Operations | **Time:** 60 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-2_JAVA-D3-102_Tomcat_WildFly_WAR_Deployment/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day3/s2` to fetch boilerplate code

#### Step-by-Step Investigation Guidelines

- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8080 :9990"`

#### Full Solution Code & Configuration

**1. Optimized POM with Exclusion (`pom.xml`):**

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.3</version>
  </parent>
  <groupId>com.example</groupId>
  <artifactId>retail-service</artifactId>
  <version>1.0.0</version>
  <packaging>war</packaging>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
      <exclusions>
        <exclusion>
          <groupId>org.apache.logging.log4j</groupId>
          <artifactId>log4j-to-slf4j</artifactId>
        </exclusion>
      </exclusions>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-tomcat</artifactId>
      <scope>provided</scope>
    </dependency>
  </dependencies>
</project>
```

**2. Servlet Initializer (`RetailServiceApplication.java`):**

```java
package com.example.retail;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;

@SpringBootApplication
public class RetailServiceApplication extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
        return application.sources(RetailServiceApplication.class);
    }

    public static void main(String[] args) {
        SpringApplication.run(RetailServiceApplication.class, args);
    }
}
```

#### Visual Verification Mockup

```text
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [WAR DEPLOYMENT VERIFICATION]                                                           |
+----------------------------------------------------------------------------------------------------+
$ curl -s http://localhost:8080/retail-service/health-check
Retail Service WAR Deployed and Active!

[PASS] JAVA-D3-102 WAR Deployment Validation Succeeded!
+----------------------------------------------------------------------------------------------------+
```

---

### Scenario JAVA-D3-103: JVM Heap Tuning, Graceful Shutdown & Thread Dumps

- **Ticket ID:** `JAVA-D3-103` | **Category:** JVM Diagnostics | **Time:** 60 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-3_JAVA-D3-103_JVM_Heap_Tuning_Thread_Dumps/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day3/s3` to fetch boilerplate code

#### Step-by-Step Investigation Guidelines

- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8080 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8080 :8083"`

#### Full Solution Code & Configuration

**1. Retail Controller (`RetailController.java`):**

```java
package com.example.retail;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RetailController {

    @GetMapping("/checkout")
    public String checkout() throws InterruptedException {
        // Simulates 15-second transactional checkout
        Thread.sleep(15000);
        return "Checkout completed successfully!";
    }

    @GetMapping("/health-check")
    public String healthCheck() {
        return "Retail Service is running!";
    }
}
```

**2. Application Properties (`application.properties`):**

```properties
server.port=8080
spring.application.name=retail-service

# Graceful Shutdown Configuration
server.shutdown=graceful
spring.lifecycle.timeout-per-shutdown-phase=20s
```

#### Visual Verification Mockup

```text
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [JVM DIAGNOSTICS & GRACEFUL SHUTDOWN]                                                  |
+----------------------------------------------------------------------------------------------------+
$ curl -s http://localhost:8080/health-check
Retail Service is running!

$ jcmd -l
18240 com.example.retail.RetailServiceApplication

[PASS] JAVA-D3-103 JVM & Diagnostics Succeeded!
+----------------------------------------------------------------------------------------------------+
```
