package com.labskraft.order.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    @GetMapping("/ping")
    public Map<String, String> ping() {
        return Map.of("status", "UP", "message", "Order Service Build Standardized!");
    }
}
