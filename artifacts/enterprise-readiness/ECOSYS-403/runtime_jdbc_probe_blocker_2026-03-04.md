# ECOSYS-403 Runtime JDBC/Hibernate Probe Blocker (2026-03-04)

## Attempt
Executed runtime JDBC probe for ScratchBird URL through `DriverManager` using:

- `artifacts/enterprise-readiness/ECOSYS-403/verification_hibernate_runtime_probe.sh`

## Result
Probe failed with runtime JDBC bootstrap error indicating the ScratchBird JDBC
implementation was not available to `DriverManager` in the probe classpath.

## Impact
- Deterministic Hibernate dialect contracts remain complete and passing.
- Live JPA/Hibernate runtime matrix cannot start until the ScratchBird JDBC driver
  jar is provided on probe/runtime classpath and endpoint compatibility is confirmed.

## Next step
Build/provide ScratchBird JDBC driver jar and re-run probe with:

- `SCRATCHBIRD_JDBC_PROBE_CLASSPATH=/path/to/scratchbird-jdbc.jar`
