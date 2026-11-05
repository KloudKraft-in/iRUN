package com.labskraft.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

// TODO for Participant:
// 1. Make this class extend SpringBootServletInitializer so an external servlet container
//    (Tomcat) can bootstrap the Spring ApplicationContext without public static void main().
// 2. Override configure(SpringApplicationBuilder) and return application.sources(WarDemoApplication.class);
//
// Imports you will need:
//   SpringApplicationBuilder
//   SpringBootServletInitializer
@SpringBootApplication
public class WarDemoApplication {

    // YOUR CODE HERE (configure method)

    public static void main(String[] args) {
        SpringApplication.run(WarDemoApplication.class, args);
    }
}
