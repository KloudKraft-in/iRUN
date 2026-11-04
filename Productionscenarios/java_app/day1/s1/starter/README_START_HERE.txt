JAVA-D1-101: Monolith to Two REST Microservices
====================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
When you start the Order Service and attempt to create an order:
  POST http://localhost:8081/api/orders?productId=1&quantity=2
You will receive:
  500 Internal Server Error / ResourceAccessException (Connection refused to localhost:8082)
Because the independent Product Service on port 8082 has not yet been implemented or started!

YOUR MISSION (Guidelines & Solve):
1. Build and launch the independent Product Service on port 8082 with endpoint /api/products/{id}.
2. Configure Order Service to consume Product Service via RestTemplate.
3. Verify successful order creation with product details populated.
