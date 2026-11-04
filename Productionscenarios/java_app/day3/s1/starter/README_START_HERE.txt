JAVA-D3-101: Spring Cloud Centralized Config Server & @RefreshScope
======================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. Missing @EnableConfigServer:
   Config Server starts as a blank Spring Boot app; requests to http://localhost:8888/retail-service/dev return 404.
2. Missing @RefreshScope on Retail Client:
   When store.discount is updated in Git repository from 10 to 20, calling POST /actuator/refresh
   either fails or has NO EFFECT on GET /discount (still returns 10 instead of 20)!

YOUR MISSION (Guidelines & Solve):
1. Annotate ConfigServerApplication with @EnableConfigServer on port 8888 backed by Git repo.
2. Configure symmetrical encryption/decryption (encrypt.key).
3. Annotate DiscountController with @RefreshScope and expose /actuator/refresh.
4. Update property in Git repository and trigger live refresh without restarting the client app.
