package com.example.retail;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// TODO: Extend SpringBootServletInitializer and override configure() to bootstrap in external containers
//       (configure(SpringApplicationBuilder) should return application.sources(RetailServiceApplication.class))
// Imports you will need:
//   org.springframework.boot.builder.SpringApplicationBuilder
//   org.springframework.boot.web.servlet.support.SpringBootServletInitializer
@SpringBootApplication
public class RetailServiceApplication {

    // YOUR CODE HERE (configure method)

    public static void main(String[] args) {
        SpringApplication.run(RetailServiceApplication.class, args);
    }
}
