JAVA-D3-103: JVM Heap Tuning, Graceful Shutdown & Thread Dump Diagnostics
=========================================================================
EXPECTED FAILURE ON STARTUP / INITIAL TEST:
1. Hard Kill during transaction (Without Graceful Shutdown):
   When triggering a 15-second slow checkout request:
     curl http://localhost:8080/checkout
   If the server process is abruptly stopped (Ctrl+C without graceful shutdown), the client immediately fails with:
     "curl: (52) Empty reply from server" OR "Connection reset by peer". Customer transaction is dropped!
2. Unmonitored Memory:
   Without explicit JVM limits (-Xms, -Xmx) and GC logging, high-load JVM memory leak causes silent OOM kills.

YOUR MISSION (Guidelines & Solve):
1. Configure server.shutdown=graceful and spring.lifecycle.timeout-per-shutdown-phase=20s.
2. Launch executable JAR with custom JVM limits:
   java -Xms256m -Xmx512m -Xlog:gc*:file=gc.log -jar target/retail-service.jar
3. Trigger slow checkout and initiate shutdown; verify in-flight request finishes cleanly with HTTP 200 OK.
4. Use 'jcmd <pid> Thread.print > threaddump.txt' to capture active threads in TIMED_WAITING state.
