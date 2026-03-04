# ECOSYS-404 Runtime Driver Blocker (2026-03-04)

## Attempt
Executed runtime datasource initialization with TypeORM against `type: "scratchbird"`.

Probe command path:

- `artifacts/enterprise-readiness/ECOSYS-404/verification_typeorm_runtime_probe.sh`

## Result
TypeORM returned `MissingDriverError`:

- `Wrong driver: "scratchbird" given.`
- Supported drivers list does not include `scratchbird`.

## Impact
- Deterministic adapter contract suite is complete and passing.
- Live TypeORM runtime schema/CRUD/transaction matrix is blocked until TypeORM
  runtime accepts/registers a ScratchBird driver integration path.

## Next step
Implement/register a TypeORM driver bridge for ScratchBird and re-run the runtime probe
before executing the full live TypeORM matrix.
