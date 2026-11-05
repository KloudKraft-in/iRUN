# Java Application Operations - Master Instructor Solution Guide

## Trainer Instructions, Step-by-Step Solutions & Visual Verification Mockups

> > [!IMPORTANT] **CONFIDENTIAL - FOR TRAINER & INSTRUCTOR USE ONLY** Do not distribute this guide to participants. Use this document to guide simulations, facilitate troubleshooting, and validate participant submissions against expected reference implementations.

---

## 1. Module-Wise Setup Requirements (Trainer VM & Lab Fleet)

### Training Fleet Readiness Checklist

- **Host VM Specification:** Ubuntu 22.04/24.04 LTS or Windows 11 Enterprise (4 vCPU, 8 GB RAM, 30 GB SSD).  
- **Core Toolchain:** OpenJDK 17 LTS, Apache Maven 3.9+, Git 2.30+, curl, jq, lsof.  
- **Standalone Servers:** Apache Tomcat 10.1 extracted at `/opt/tomcat10` (or `C:\training_tools\apache-tomcat-10.1.20`) and WildFly 30 extracted at `/opt/wildfly` (or `C:\training_tools\wildfly-30.0.1.Final`).  
- **Pre-Flight Port Verification:** Before starting sessions, ensure ports `8080`, `8081`, `8082`, `8083`, `8888`, and `9990` are completely free. Run the provided validation script:

```sh
# On Ubuntu:
./Setup_Scripts/ubuntu/validate_environment_ubuntu.sh
# On Windows:
.\Setup_Scripts\windows\validate_environment_windows.bat
```

---

## 2. Common Trainer Instructions & Pedagogy

### The Simulation Methodology

1. **Present the Scenario as a Production Incident Ticket:** Provide participants with the ticket summary, priority, and symptoms. Do not immediately reveal the underlying cause.  
2. **Mandate the Expected Failure Run:** Instruct every participant to run the initial starter code or validation script first. They must observe and analyze the exact failure before making code edits.  
3. **Facilitating Troubleshooting (Socratic Coaching):** When participants get stuck, avoid giving them the code directly. Prompt them with diagnostic questions:  
   - *"What does the stack trace tell you about the failed HTTP connection or missing bean?"*  
   - *"Which port is the service attempting to bind to, and what process already owns it?"*  
   - *"How can you use `mvn dependency:tree` to identify where that duplicate class is coming from?"*  
4. **Validating Submissions:** Check both the functional behavior (curl output, HTTP status codes) and the engineering hygiene (graceful shutdown logs, clean code without hardcoded credentials).

---

## 3. Day 1: Enterprise Architecture & Spring Boot Fundamentals

### Scenario JAVA-D1-101: Monolith to Two REST Microservices

- **Ticket ID:** `JAVA-D1-101` \| **Category:** Architecture \| **Time:** 75 mins  
- **Starter Artifacts Location:** `Artifacts_Sorted/Day-1/Scenario-1_JAVA-D1-101_Monolith_to_Microservices/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day1/s1` to fetch boilerplate code

#### Step 0: Expected Failure (Reproduction Steps)

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

#### A. Expected Failure Screenshot / Terminal Mockup

```
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [PARTICIPANT WORKSPACE]                                                                 |
+----------------------------------------------------------------------------------------------------+
$ curl -X POST "http://localhost:8081/api/orders?productId=1&quantity=2"
{"timestamp":"2026-11-03T07:15:22.104+00:00","status":500,"error":"Internal Server Error",
 "message":"I/O error on GET request for "http://localhost:8082/api/products/1": Connection refused"}

CONSOLE LOG:
2026-11-03 12:45:10.112 ERROR 18420 --- [nio-8081-exec-1] c.l.o.controller.OrderController : 
org.springframework.web.client.ResourceAccessException: I/O error on GET request for 
"http://localhost:8082/api/products/1": Connection refused: connect
    at org.springframework.web.client.RestTemplate.createResourceAccessException(RestTemplate.java:902)
    at org.springframework.web.client.RestTemplate.doExecute(RestTemplate.java:876)
+----------------------------------------------------------------------------------------------------+
```

#### B. Full Solution Code & Configuration

**1. Product Service - Model (`Product.java`):**

```java
package com.labskraft.product.model;

public record Product(Long id, String name, Double price) {}
```

**2. Product Service - Controller (`ProductController.java`):**

```java
package com.labskraft.product.controller;

import com.labskraft.product.model.Product;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
import java.util.Map;

@RestController
@RequestMapping("/api/products")
public class ProductController {
    private final Map<Long, Product> products = Map.of(
        1L, new Product(1L, "Laptop", 50000.0),
        2L, new Product(2L, "Monitor", 12000.0),
        3L, new Product(3L, "Keyboard", 2500.0)
    );

    @GetMapping("/{id}")
    public Product getProductById(@PathVariable Long id) {
        Product p = products.get(id);
        if (p == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product " + id + " not found");
        }
        return p;
    }
}
```

**3. Product Service Configuration (`product-service/src/main/resources/application.properties`):**

```properties
server.port=8082
spring.application.name=product-service
```

&nbsp;

**4. Order Service - Controller (`OrderController.java`):**

```java
package com.labskraft.order.controller;

import com.labskraft.order.model.Order;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/api/orders")
public class OrderController {
    private final Map<Long, Order> orderDb = new ConcurrentHashMap<>();
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${product.service.url:http://localhost:8082/api/products}")
    private String productServiceUrl;

    @PostMapping
    public ResponseEntity<Order> createOrder(@RequestParam Long productId, @RequestParam Integer quantity) {
        // Inter-service REST invocation
        Map<?, ?> product = restTemplate.getForObject(productServiceUrl + "/" + productId, Map.class);
        String name = (String) product.get("name");
        Double price = Double.valueOf(product.get("price").toString());
        
        Long orderId = (long) (orderDb.size() + 1);
        Order order = new Order(orderId, productId, name, price, quantity);
        orderDb.put(orderId, order);
        return ResponseEntity.ok(order);
    }
}
```

#### C. Visual Verification Screenshot / Output Mockup

```
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [SUCCESSFUL REST COMMUNICATION VERIFICATION]                                            |
+----------------------------------------------------------------------------------------------------+
$ curl -s http://localhost:8082/api/products/1
{"id":1,"name":"Laptop","price":50000.0}

$ curl -s -X POST "http://localhost:8081/api/orders?productId=1&quantity=2"
{"orderId":1,"productId":1,"productName":"Laptop","price":50000.0,"quantity":2}

[PASS] Inter-service HTTP call succeeded. Order record successfully created with enriched product data.
+----------------------------------------------------------------------------------------------------+
```

---

### Scenario JAVA-D1-102: JAR/WAR Deployment and External Tomcat 10.1

- **Ticket ID:** `JAVA-D1-102` \| **Category:** Deployment Architecture \| **Time:** 50 mins  
- **Starter Artifacts Location:** `Artifacts_Sorted/Day-1/Scenario-2_JAVA-D1-102_JAR_WAR_Tomcat_Deployment/starter`


#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day1/s2` to fetch boilerplate code

#### Step 0: Expected Failure (Reproduction Steps)

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

#### Step-by-Step Investigation Guidelines

- Check which process is occupying port 8080 using `lsof -i :8080` (Linux) or `netstat -ano | findstr 8080` (Windows).  
- Inspect Tomcat log files in `CATALINA_HOME/logs/catalina.out` and `localhost.<date>.log`.  
- Review standard Jakarta EE servlet requirements for external containers: external containers require a servlet initialization hook to bootstrap Spring without `public static void main()`.

#### A. Expected Failure Screenshot Mockup

```
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [PORT COLLISION & WAR 404 LOGS]                                                         |
+----------------------------------------------------------------------------------------------------+
$ java -jar target/demo-app.jar
***************************
APPLICATION FAILED TO START
***************************
Description:
Web server failed to start. Port 8080 was already in use.
Action:
Identify and stop the process that's listening on port 8080 or configure this application to listen on another port.

$ curl -i http://localhost:8080/war-demo/api/demo
HTTP/1.1 404 Not Found
Content-Type: text/html;charset=utf-8
+----------------------------------------------------------------------------------------------------+
```

B. Full Solution Code & Configuration

**1. Executable JAR Configuration (`jar-demo/src/main/resources/application.properties`):**

```properties
server.port=8083
spring.application.name=jar-demo
```

&nbsp;

**2. WAR Application Class (`WarDemoApplication.java`):**

```java
package com.labskraft.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.boot.web.servlet.support.SpringBootServletInitializer;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class WarDemoApplication extends SpringBootServletInitializer {

    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder builder) {
        return builder.sources(WarDemoApplication.class);
    }

    public static void main(String[] args) {
        SpringApplication.run(WarDemoApplication.class, args);
    }

    @GetMapping("/api/demo")
    public String demo() {
        return "Tomcat 10.1 Deployed WAR Success!";
    }
}
```

**3. WAR Build Configuration (`war-demo/pom.xml`):**

```xml
<packaging>war</packaging>
<dependencies>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
  </dependency>
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-tomcat</artifactId>
    <scope>provided</scope>
  </dependency>
</dependencies>
```

#### C. Visual Verification Mockup

```
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [DEPLOYMENT VERIFICATION]                                                               |
+----------------------------------------------------------------------------------------------------+
$ curl -i http://localhost:8083/api/demo
HTTP/1.1 200 OK
Content-Type: text/plain;charset=UTF-8
Tomcat 10.1 Deployed WAR Success!

$ curl -i http://localhost:8080/war-demo/api/demo
HTTP/1.1 200 OK
Content-Type: text/plain;charset=UTF-8
Tomcat 10.1 Deployed WAR Success!
+----------------------------------------------------------------------------------------------------+
```

&nbsp;

## 

### Scenario JAVA-D1-103: Maven, Gradle and Dependency Management

- **Ticket ID:** `JAVA-D1-103` | **Category:** Build & Dependency Management | **Time:** 45 mins
- **Solution Artifacts Location:** `Artefacts/Scenario-3_JAVA-D1-103_Maven_Gradle_Dependency_Management.zip`


#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day1/s3` to fetch boilerplate code

#### A. Expected Failure Screenshot Mockup
- **Failure Classification:** `Fail >> expected` (Build Failure & Incompatible API)

```text
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [BUILD FAILURE: DEPENDENCY DRIFT & INCOMPATIBLE APIs]                                    |
+----------------------------------------------------------------------------------------------------+
$ mvn clean package
[INFO] Scanning for projects...
[INFO] --------------------< com.labskraft:order-service >--------------------
[INFO] Building order-service 0.0.1-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.11.0:compile
[ERROR] /order-service/src/main/java/com/labskraft/order/controller/OrderController.java:[15,28]
package org.springframework.web.bind.annotation does not exist
[ERROR] Incompatible dependency version detected: Spring Framework 5.3.x collided with Jakarta EE 10 servlet spec.
[INFO] BUILD FAILURE
+----------------------------------------------------------------------------------------------------+
```

#### B. Steps to Solve the Problem (With Complete Solutions)

**1. Standardized Parent POM (`pom.xml`):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.3</version>
        <relativePath/>
    </parent>
    <groupId>com.labskraft</groupId>
    <artifactId>order-service</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <properties>
        <java.version>17</java.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

**2. Equivalent Gradle Build Configuration (`build.gradle`):**
```groovy
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.2.3'
    id 'io.spring.dependency-management' version '1.1.4'
}

group = 'com.labskraft'
version = '0.0.1-SNAPSHOT'

java {
    sourceCompatibility = '17'
}

repositories {
    mavenCentral()
}

dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
}

tasks.named('test') {
    useJUnitPlatform()
}
```

**3. Dependency Tree Inspection & Build Commands:**
```bash
# Generate Maven dependency tree to detect transitive conflicts:
./mvnw dependency:tree

# Build the standardized fat JAR:
./mvnw clean package -DskipTests
```

#### C. Visual Verification Mockup

```text
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [REPRODUCIBLE BUILD SUCCESS & DEPENDENCY TREE OUTPUT]                                  |
+----------------------------------------------------------------------------------------------------+
$ ./validation_script.sh
Running Maven Clean Test Package...
[INFO] Scanning for projects...
[INFO] Building order-service 0.0.1-SNAPSHOT
[INFO] --- maven-compiler-plugin:3.11.0:compile (default-compile) @ order-service ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 2 source files with javac [debug target 17] to target/classes
[INFO] --- spring-boot-maven-plugin:3.2.3:repackage (repackage) @ order-service ---
[INFO] Replacing main artifact [target/order-service-0.0.1-SNAPSHOT.jar] with repackaged fat jar
[INFO] BUILD SUCCESS
[INFO] Total time:  3.421 s

Validating executable JAR artifact generation:
-rw-r--r-- 1 student student 19M target/order-service-0.0.1-SNAPSHOT.jar
[SUCCESS] Maven reproducible build verified successfully!
+----------------------------------------------------------------------------------------------------+
```

#### D. Trainer Evaluation Notes & Scoring Rubric
- **Socratic Coaching:** Ask student: *"Why does removing explicit `<version>` tags from `<dependency>` entries prevent dependency collisions when using `spring-boot-starter-parent`?"*
- **Scoring Rubric (100 Points Total):**
  - **30 Pts - Parent POM Locking:** Correct inheritance from `spring-boot-starter-parent:3.2.3`.
  - **35 Pts - Dependency Tree Analysis:** Demonstrated `mvn dependency:tree` and documented differences between Maven lifecycles and Gradle DAG.
  - **35 Pts - Build Validation:** Clean executable JAR generated via `./mvnw clean package`.

---

## 6. Evaluation & Scoring Rubric

| Criteria | Weight | Evaluation Method |
| :---- | :---: | :---- |
| **Architectural Separation & REST Design** | **30%** | Demonstrated separate services on dedicated ports with non-blocking error handling. |
| **Diagnostics & Troubleshooting Discipline** | **35%** | Correctly resolved port collisions, BeanCreationException, and duplicate dependencies via exclusions. |
| **Operational & Production Readiness** | **35%** | Secured actuator endpoints, verified HikariCP tuning, and demonstrated graceful shutdown with thread dump evidence. |

&nbsp;