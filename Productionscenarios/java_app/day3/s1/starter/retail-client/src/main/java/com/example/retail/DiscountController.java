package com.example.retail;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

// TODO: Add @RefreshScope so bean can be re-initialized upon POST /actuator/refresh
//       (import org.springframework.cloud.context.config.annotation.RefreshScope)
@RestController
public class DiscountController {
    // Bound from the Centralized Config Server (observe how @Value is used here)
    @Value("${store.discount:0}")
    private String discount;

    @GetMapping("/discount")
    public String discount() {
        return discount;
    }
}
