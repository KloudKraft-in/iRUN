JAVA-D1-101: Monolith to Two REST Microservices
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In Terminal 1, navigate to order-service and run:
     mvn spring-boot:run
   (Order Service starts on port 8081).
2. In Terminal 2, attempt to create an order:
     curl.exe -X POST "http://localhost:8081/api/orders?productId=1&quantity=2"
3. OBSERVED FAILURE:
     500 Internal Server Error / ResourceAccessException (Connection refused to localhost:8082)
   Why this fails: The monolithic order application has been decoupled, but the dependent
   product-service on port 8082 has not yet been started!

YOUR MISSION (Guidelines & Solve):
1. Navigate to product-service in a separate terminal:
     cd starter/product-service
2. Review ProductController.java and ensure the @GetMapping("/{id}") endpoint is active.
3. Start product-service:
     mvn spring-boot:run
   (Product Service runs on port 8082).
4. Run validation:
     .\validation_script.ps1 (Windows) or ./validation_script.sh (Ubuntu)
===============================================================================
