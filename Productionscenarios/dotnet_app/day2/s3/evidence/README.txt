Save these files here before you run `lab check` (names are exact):

  load-test-before.txt   output of load-test (500 requests) against the LEAKING build - must show failures
  counters-before.csv    dotnet-counters collect output taken during that run (number-of-active-connections climbs to 100)
  counters-after.csv     dotnet-counters collect output taken during the run AFTER your fix (flat / returns to 0)
  dapper.diff            diff of DapperPaymentRepository.cs (before vs after)
  orderquery.diff        diff of OrderQueryService.cs (before vs after)
  load-test-after.txt    output of load-test (500 requests) against the FIXED build - must show "Failed: 0"
