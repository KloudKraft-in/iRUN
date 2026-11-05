========================================================================
LAB: JAVA-D3-103 - JVM Heap Tuning, Graceful Shutdown & Thread Dumps
========================================================================
TASK SUMMARY:
1. Expected Failure:
   - Application memory exhaustion triggers java.lang.OutOfMemoryError.
   - Immediate shutdown terminates active transactions prematurely.
2. Resolution:
   - Launch application with tuned JVM memory flags: -Xms256m -Xmx512m -XX:+HeapDumpOnOutOfMemoryError.
   - Configure graceful shutdown: server.shutdown=graceful and spring.lifecycle.timeout-per-shutdown-phase=20s.
   - Inspect thread dumps and memory diagnostics using jcmd <PID> Thread.print and GC.heap_info.
   - Run validation_script.ps1 / .sh to verify PASS.
========================================================================
