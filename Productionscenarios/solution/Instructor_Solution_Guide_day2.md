# Java Application Operations - Master Instructor Solution Guide (Day 2)

## Day 2: Spring Boot Configuration, Monitoring & Diagnostics

---

## 1. Common Trainer Instructions & Pedagogy

### Lab Objectives & Concepts
- Master Spring Boot profile-based configuration (`dev`, `prod`, `default`).
- Type-safe `@ConfigurationProperties` binding vs. `@Value`.
- Production Actuator observability: health indicators, custom endpoints, and Spring Security lockdown.
- HikariCP connection pool sizing, diagnostics, leak detection, and JMX metrics.

### Pre-Flight Verification
- Ensure port `8081` is completely free before starting Day 2 exercises.

---

## 2. Day 2 Scenario Solutions

### Scenario JAVA-D2-101: Spring Profiles and Configuration Binding

- **Ticket ID:** `JAVA-D2-101` | **Category:** Configuration Architecture | **Time:** 50 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-1_JAVA-D2-101_Spring_Profiles_and_Binding/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day2/s1` to fetch boilerplate code

#### Step 0: Expected Failure (Reproduction Steps)

1. In VS Code, navigate to `product-service` and start the service:

```sh
mvn spring-boot:run
```

2. Query store info endpoint:

```sh
curl -s http://localhost:8081/api/store-info
```

3. **Observed Error:**

```text
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [CONFIGURATION BINDING ERROR]                                                           |
+----------------------------------------------------------------------------------------------------+
$ curl -s http://localhost:8081/api/store-info
{"environment":null,"discount":0,"welcomeMessage":null,"boundWelcomeMessage":null}
+----------------------------------------------------------------------------------------------------+
```

#### Step-by-Step Investigation Guidelines

- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8081"`
- Inspect `src/main/resources/application.properties` and `application-dev.properties`.

#### Full Solution Code & Configuration

**1. Type-Safe Configuration Properties Bean (`StoreProperties.java`):**

```java
package com.labskraft.product.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "store")
public class StoreProperties {
    private String environment;
    private int discount;
    private String welcomeMessage;

    public String getEnvironment() { return environment; }
    public void setEnvironment(String environment) { this.environment = environment; }

    public int getDiscount() { return discount; }
    public void setDiscount(int discount) { this.discount = discount; }

    public String getWelcomeMessage() { return welcomeMessage; }
    public void setWelcomeMessage(String welcomeMessage) { this.welcomeMessage = welcomeMessage; }
}
```

**2. Store Info Controller (`StoreInfoController.java`):**

```java
package com.labskraft.product.controller;

import com.labskraft.product.config.StoreProperties;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
public class StoreInfoController {
    private final StoreProperties storeProperties;
    private final String welcomeMessage;

    public StoreInfoController(
            StoreProperties storeProperties,
            @Value("${store.welcome.message:DefaultStore}") String welcomeMessage) {
        this.storeProperties = storeProperties;
        this.welcomeMessage = welcomeMessage;
    }

    @GetMapping("/api/store-info")
    public Map<String, Object> getStoreInfo() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("environment", storeProperties.getEnvironment());
        result.put("discount", storeProperties.getDiscount());
        result.put("welcomeMessage", welcomeMessage);
        result.put("boundWelcomeMessage", storeProperties.getWelcomeMessage());
        return result;
    }
}
```

#### Visual Verification Mockup

```text
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [SUCCESSFUL PROFILE CONFIGURATION BINDING]                                              |
+----------------------------------------------------------------------------------------------------+
$ curl -s http://localhost:8081/api/store-info
{"environment":"Dev","discount":15,"welcomeMessage":"Welcome Dev","boundWelcomeMessage":"Welcome Dev"}

[PASS] JAVA-D2-101 Configuration Binding Succeeded!
+----------------------------------------------------------------------------------------------------+
```

---

### Scenario JAVA-D2-102: Actuator Observability & Endpoint Security

- **Ticket ID:** `JAVA-D2-102` | **Category:** Observability & Security | **Time:** 50 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-2_JAVA-D2-102_Actuator_Metrics_and_Security/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day2/s2` to fetch boilerplate code

#### Step 0: Expected Failure (Reproduction Steps)

```sh
curl -i http://localhost:8081/actuator/env
```

Observed flaw: sensitive environment properties are completely exposed without authentication.

#### Step-by-Step Investigation Guidelines

- Check which network ports are currently open using below :
  - `Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue;`
  - `netstat -ano | findstr ":8081"`

#### Full Solution Code & Configuration

**1. Security Configuration (`SecurityConfig.java`):**

```java
package com.labskraft.product.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.authorizeHttpRequests(auth -> auth
                .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                .requestMatchers("/actuator/**").hasRole("ACTUATOR_ADMIN")
                .anyRequest().permitAll()
        );
        http.httpBasic(basic -> {});
        return http.build();
    }

    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails admin = User.withUsername("admin")
                .password("{noop}admin123")
                .roles("ACTUATOR_ADMIN")
                .build();
        return new InMemoryUserDetailsManager(admin);
    }
}
```

**2. Custom Health Indicator (`StoreHealthIndicator.java`):**

```java
package com.labskraft.product.monitoring;

import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

@Component
public class StoreHealthIndicator implements HealthIndicator {
    @Override
    public Health health() {
        return Health.up()
                .withDetail("store", "Open for Student Orders")
                .build();
    }
}
```

**3. Custom Actuator Endpoint (`StoreControlEndpoint.java`):**

```java
package com.labskraft.product.monitoring;

import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.ReadOperation;
import org.springframework.stereotype.Component;
import java.util.Map;

@Component
@Endpoint(id = "storeControl")
public class StoreControlEndpoint {
    @ReadOperation
    public Map<String, String> getStoreStatus() {
        return Map.of("status", "ACTIVE");
    }
}
```

#### Visual Verification Mockup

```text
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [ACTUATOR SECURITY VERIFICATION]                                                       |
+----------------------------------------------------------------------------------------------------+
$ curl -s http://localhost:8081/actuator/health
{"status":"UP","components":{"storeHealth":{"status":"UP","details":{"store":"Open for Student Orders"}}}}

$ curl -i http://localhost:8081/actuator/env
HTTP/1.1 401 Unauthorized

$ curl -s -u admin:admin123 http://localhost:8081/actuator/env
{"activeProfiles":["dev"],"propertySources":[...]}

[PASS] JAVA-D2-102 Actuator & Security Validation Succeeded!
+----------------------------------------------------------------------------------------------------+
```

---

### Scenario JAVA-D2-103: Startup Diagnostics & HikariCP Pool Management

- **Ticket ID:** `JAVA-D2-103` | **Category:** Diagnostics & Performance | **Time:** 50 mins  
- **Starter Artifacts Location:** `Artefacts/Scenario-3_JAVA-D2-103_Startup_Diagnostics_HikariCP_Pool/starter`  

#### Setup: Fetch template details

- Execute

```sh
git clone https://github.com/KloudKraft-in/iRUN.git
```

- `https://github.com/KloudKraft-in/iRUN/tree/main/Productionscenarios/java_app/day2/s3` to fetch boilerplate code

#### Full Solution Code & Configuration

**1. Pool Diagnostics Controller (`PoolDiagnosticsController.java`):**

```java
package com.labskraft.product.controller;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Map;

@RestController
public class PoolDiagnosticsController {
    private final DataSource dataSource;

    public PoolDiagnosticsController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @GetMapping("/api/pool/status")
    public Map<String, Object> getPoolStatus() {
        if (dataSource instanceof HikariDataSource hikari) {
            return Map.of(
                "activeConnections", hikari.getHikariPoolMXBean().getActiveConnections(),
                "idleConnections", hikari.getHikariPoolMXBean().getIdleConnections(),
                "totalConnections", hikari.getHikariPoolMXBean().getTotalConnections(),
                "threadsAwaitingConnection", hikari.getHikariPoolMXBean().getThreadsAwaitingConnection()
            );
        }
        return Map.of("status", "Not a Hikari DataSource");
    }

    @GetMapping("/api/pool/leak-test")
    public String leakTest() throws SQLException, InterruptedException {
        Connection conn = dataSource.getConnection();
        Thread.sleep(5000);
        conn.close();
        return "Connection acquired, used, and closed safely";
    }
}
```

#### Visual Verification Mockup

```text
+----------------------------------------------------------------------------------------------------+
| TERMINAL - [HIKARICP POOL DIAGNOSTICS]                                                            |
+----------------------------------------------------------------------------------------------------+
$ curl -s http://localhost:8081/api/pool/status
{"activeConnections":0,"idleConnections":1,"totalConnections":1,"threadsAwaitingConnection":0}

[PASS] JAVA-D2-103 HikariCP Diagnostics Succeeded!
+----------------------------------------------------------------------------------------------------+
```
