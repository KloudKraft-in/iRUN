package com.labskraft.product.controller;

import com.labskraft.product.config.StoreProperties;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
public class StoreInfoController {

    // TODO: Inject StoreProperties via constructor once you annotate it with @Component and @ConfigurationProperties
    //       (make the field final and assign it in a constructor)
    private StoreProperties storeProperties;

    // TODO: Map welcomeMessage using @Value("${store.welcome.message:DefaultStore}")
    //       (import org.springframework.beans.factory.annotation.Value; add it as a constructor parameter)
    private String welcomeMessage;

    // YOUR CODE HERE (constructor)

    @GetMapping("/api/store-info")
    public Map<String, Object> getStoreInfo() {
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("environment", storeProperties != null ? storeProperties.getEnvironment() : null);
        result.put("discount", storeProperties != null ? storeProperties.getDiscount() : 0);
        result.put("welcomeMessage", welcomeMessage);
        result.put("boundWelcomeMessage", storeProperties != null ? storeProperties.getWelcomeMessage() : null);
        return result;
    }
}
