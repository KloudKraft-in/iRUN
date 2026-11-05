package com.labskraft.order.controller;

import com.labskraft.order.model.Order;
import com.labskraft.order.model.Product;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    @Value("${product.service.url:http://localhost:8082}")
    private String productServiceUrl;

    private final RestTemplate restTemplate = new RestTemplate();

    @PostMapping
    public ResponseEntity<Order> createOrder(
            @RequestParam Long productId,
            @RequestParam Integer quantity) {

        // Inter-service call to decoupled Product Service on port 8082:
        // EXPECTED FAILURE: When product-service is not running, this will throw
        // ResourceAccessException (Connection refused: connect) returning HTTP 500!
        Product product = restTemplate.getForObject(
            productServiceUrl + "/api/products/" + productId,
            Product.class
        );

        if (product == null) {
            return ResponseEntity.notFound().build();
        }

        Order order = new Order(
            product.getId(),
            product.getName(),
            quantity,
            product.getPrice() * quantity
        );

        return ResponseEntity.ok(order);
    }
}
