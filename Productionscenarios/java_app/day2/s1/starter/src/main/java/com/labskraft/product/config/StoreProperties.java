package com.labskraft.product.config;

// TODO for Participant:
// 1. Register this class as a Spring bean            -> @Component
// 2. Bind it to the "store.*" properties             -> @ConfigurationProperties(prefix = "store")
// Imports you will need:
//   org.springframework.stereotype.Component
//   org.springframework.boot.context.properties.ConfigurationProperties
//
// 3. Confirm the getters and setters for environment, discount and welcomeMessage exist (they do below).
public class StoreProperties {

    private String environment;
    private int discount;
    private String welcomeMessage;

    public String getEnvironment() {
        return environment;
    }

    public void setEnvironment(String environment) {
        this.environment = environment;
    }

    public int getDiscount() {
        return discount;
    }

    public void setDiscount(int discount) {
        this.discount = discount;
    }

    public String getWelcomeMessage() {
        return welcomeMessage;
    }

    public void setWelcomeMessage(String welcomeMessage) {
        this.welcomeMessage = welcomeMessage;
    }
}
