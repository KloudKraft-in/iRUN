Save these files here before you run validation (names are exact):

  load-test-before.txt   output of  .\load-test.ps1 -Requests 500 -Concurrency 50   BEFORE the fix (must show failures)
  counters-before.csv    dotnet-counters export during the failing load test (shows active connections hitting 100)
  dapper.diff            your DapperPaymentRepository.cs diff (using + removed event hook)
  orderquery.diff        your OrderQueryService.cs diff (single LINQ projection)
  counters-after.csv     dotnet-counters export during the passing load test (connections stay low)
  load-test-after.txt    output of  .\load-test.ps1 -Requests 500 -Concurrency 50   AFTER the fix (must show "Failed: 0")

