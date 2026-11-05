package com.labskraft.product.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.provisioning.InMemoryUserDetailsManager;

@Configuration
public class SecurityConfig {

    // TODO for Participant (action items 1 and 2):
    // Define a @Bean method that builds and returns a SecurityFilterChain from an HttpSecurity parameter:
    //   1. Permit unauthenticated access to /actuator/health and /actuator/info
    //   2. Restrict every other /actuator/** endpoint to the role ACTUATOR_ADMIN
    //   3. Enable HTTP Basic authentication
    //   4. Keep all non-actuator requests open (anyRequest().permitAll())
    // Hint: http.authorizeHttpRequests(...) with requestMatchers(...).permitAll() / .hasRole(...), then http.httpBasic(...)
    // Imports you will need:
    //   org.springframework.security.config.annotation.web.builders.HttpSecurity
    //   org.springframework.security.web.SecurityFilterChain

    // YOUR CODE HERE

    // PROVIDED: in-memory user used for the authenticated check (admin / admin123 / ACTUATOR_ADMIN)
    @Bean
    public UserDetailsService userDetailsService() {
        UserDetails admin = User.withUsername("admin")
                .password("{noop}admin123")
                .roles("ACTUATOR_ADMIN")
                .build();
        return new InMemoryUserDetailsManager(admin);
    }
}
