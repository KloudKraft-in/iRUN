package com.example.retail;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.ArrayList;
import java.util.List;

@RestController
public class RetailController {
    // Memory leak simulation storage
    private final List<byte[]> leakList = new ArrayList<>();

    @GetMapping("/checkout")
    public String checkout() throws InterruptedException {
        // Simulates 15-second transactional checkout to verify graceful shutdown
        Thread.sleep(15000);
        return "Checkout completed successfully!";
    }

    @GetMapping("/health-check")
    public String healthCheck() {
        return "Retail Service is running!";
    }

    @GetMapping("/simulate-leak")
    public String simulateLeak() {
        leakList.add(new byte[10 * 1024 * 1024]); // 10MB chunk
        return "Allocated 10MB. Current chunks: " + leakList.size();
    }
}
