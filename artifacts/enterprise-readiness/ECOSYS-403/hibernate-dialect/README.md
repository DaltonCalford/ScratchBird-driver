# ECOSYS-403 Hibernate Dialect Artifacts

## Implementation

- Package path:
  - `tracks/alpha/integrations/scratchbird-hibernate-dialect`
- Key files:
  - `src/main/java/com/scratchbird/hibernate/ScratchBirdDialect.java`
  - `src/main/java/com/scratchbird/hibernate/ScratchBirdTypeMappings.java`
  - `src/main/java/com/scratchbird/hibernate/ScratchBirdJdbcUrlPolicy.java`
  - `src/main/java/com/scratchbird/hibernate/ScratchBirdJdbcMetadataMapper.java`
  - `src/main/java/com/scratchbird/hibernate/ScratchBirdTransactionContract.java`
  - `src/test/java/com/scratchbird/hibernate/ScratchBirdDialectContractTest.java`
  - `examples/ScratchBirdEntityLifecycleExample.java`
  - `examples/migration-mapping.sql`

## Verification

Run deterministic verification:

```bash
bash artifacts/enterprise-readiness/ECOSYS-403/verification_hibernate.sh
```

Verification log output:

- `artifacts/enterprise-readiness/ECOSYS-403/verification_hibernate.log`
- `artifacts/enterprise-readiness/ECOSYS-403/latest_verification.log`

## Runtime-gated remainder

Live JPA bootstrap, entity lifecycle, and migration/runtime matrix testing remains
pending runtime DSN endpoints. Current runtime probe/blocker artifacts:

- `artifacts/enterprise-readiness/ECOSYS-403/verification_hibernate_runtime_probe.sh`
- `artifacts/enterprise-readiness/ECOSYS-403/runtime_jdbc_probe_blocker_2026-03-04.md`
