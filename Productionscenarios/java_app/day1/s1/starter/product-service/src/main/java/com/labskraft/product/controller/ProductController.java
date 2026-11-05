package com.labskraft.product.controller;

import com.labskraft.product.model.Product;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    // Pre-populated product catalog to assist participants
    private final Map<Long, Product> products = Map.of(
        1L, new Product(1L, "Laptop", 50000.0),
        2L, new Product(2L, "Monitor", 12000.0),
        3L, new Product(3L, "Keyboard", 2500.0)
    );

    /**
     * TODO for Participant:
     * Implement the GET endpoint to fetch a product by ID:
     * 1. Add @GetMapping("/{id}")
     * 2. Look up product in the 'products' map using 'id'
     * 3. If product is null, throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found: " + id);
     * 4. Return the found product
     *
     * Imports you will need:
     *   org.springframework.http.HttpStatus
     *   org.springframework.web.server.ResponseStatusException
     */

    // YOUR CODE HERE
}
