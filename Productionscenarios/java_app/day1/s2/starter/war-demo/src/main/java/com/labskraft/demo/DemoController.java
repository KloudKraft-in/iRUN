package com.labskraft.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

/**
 * PROVIDED - no changes required.
 * Exposes the /api/demo endpoint that the lab verifies at
 * http://localhost:8080/war-demo/api/demo once the WAR is deployed to Tomcat.
 */
@RestController
public class DemoController {

    @GetMapping("/api/demo")
    public Map<String, String> demo() {
        return Map.of("status", "UP", "runtime", "External Tomcat (WAR)", "context", "/war-demo");
    }
}
