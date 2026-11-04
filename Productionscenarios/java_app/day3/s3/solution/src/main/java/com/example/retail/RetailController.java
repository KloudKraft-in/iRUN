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
