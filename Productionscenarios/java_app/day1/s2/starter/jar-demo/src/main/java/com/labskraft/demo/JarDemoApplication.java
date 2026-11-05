package com.labskraft.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@SpringBootApplication
@RestController
public class JarDemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(JarDemoApplication.class, args);
    }

    @GetMapping("/api/demo")
    public Map<String, String> demo() {
        return Map.of("status", "UP", "runtime", "Embedded Tomcat (JAR)", "port", "8083");
    }
}
