NET-D2-202: DI Scope Validation, Kestrel Limits & Single-File Build
===============================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. In this scenario directory, initialize the incident:
     .\validation_script.ps1 start   (Ubuntu: ./validation_script.sh start)
2. Test liveness and readiness:
     curl.exe -i http://localhost:5000/health/live   -> 200 OK
     curl.exe -i http://localhost:5000/health/ready  -> 500 Internal Server Error
3. OBSERVED FAILURE:
     System.InvalidOperationException: No service for type 'Retail.Core.IDiscountRule' has been registered.
   Why this fails: ASP.NET Core disables DI scope and build validation in Production mode for speed.
   The service booted fine, but readiness probe resolved OrderProcessor, throwing at runtime.

YOUR MISSION (Guidelines & Solve):
1. In starter/OrderService/Program.cs, register the missing service:
     builder.Services.AddScoped<IDiscountRule, TieredDiscountRule>();
2. Add Kestrel limits and protocols in Program.cs:
     builder.WebHost.ConfigureKestrel(options => {
         options.Limits.MaxRequestBodySize = 1_048_576; // 1 MB
         options.ConfigureEndpointDefaults(listen => listen.Protocols = HttpProtocols.Http1AndHttp2);
     });
3. Restart via validation harness:
     cd ..
     .\validation_script.ps1 restart
4. Produce a self-contained single-file build into starter/OrderService/publish:
     cd starter/OrderService
     dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o publish
5. Verify /health/ready returns 200 OK and small POST returns 200, large POST returns 413.
6. Populate starter/evidence/ and validate:
     cd ../..
     .\validation_script.ps1   (Ubuntu: ./validation_script.sh)
===============================================================================

