NET-D2-203: Connection Pool Leak & EF Core N+1 Query
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Run initial load test:
     cd starter
     .\load-test.ps1 -Requests 500 -Concurrency 50
3. OBSERVED FAILURE:
     Failed requests with 'Timeout expired prior to obtaining a connection from the pool. Max pool size (100) was reached.'
   Why this fails: DapperPaymentRepository does not wrap SqlConnection in a using statement,
   and subscribes to AppDomain.ProcessExit keeping connections rooted in memory.
   Also, OrderQueryService executes an N+1 query loop with ~401 SQL queries.

YOUR MISSION (Guidelines & Solve):
1. In starter/PaymentApi/Services/DapperPaymentRepository.cs, wrap the connection in
   await using var connection = new SqlConnection(_connectionString);
   and remove the ProcessExit subscription.
2. In starter/PaymentApi/Services/OrderQueryService.cs, replace the N+1 query loop with
   a single LINQ projection using .Select(...) and .AsNoTracking().
3. Restart via validation harness:
     cd ..
     .\validation_script.ps1 restart
4. Run load test again to verify 0 failures:
     cd starter
     .\load-test.ps1 -Requests 500 -Concurrency 50
5. Save metrics and diffs into starter/evidence/ and validate:
     cd ..
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================

