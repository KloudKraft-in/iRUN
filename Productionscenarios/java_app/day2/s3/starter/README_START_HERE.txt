========================================================================
LAB: JAVA-D2-103 - Startup Diagnostics & HikariCP Pool Management
========================================================================
TASK SUMMARY:
1. Expected Failure:
   Exhausting database connections causes application lockups or BeanCreationException.
2. Resolution:
   - Configure HikariCP maximum pool size, idle timeout, and connection leak detection.
   - Implement PoolDiagnosticsController to inspect active vs idle connections via JMX.
   - Run validation_script.ps1 / .sh to verify PASS.
========================================================================
