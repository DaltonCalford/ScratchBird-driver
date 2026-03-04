# ECOSYS-405 Runtime Python TLS Blocker (2026-03-04)

## Attempt
Executed the ECOSYS-405 verification gate with live runtime variables set:

- `SCRATCHBIRD_GO_URL` / `SCRATCHBIRD_GO_CANCEL_SQL`
- `SCRATCHBIRD_TEST_DSN` / `SCRATCHBIRD_TEST_CANCEL_SQL`
- DSN host: `127.0.0.1:13092`

Command:

```bash
bash artifacts/enterprise-readiness/ECOSYS-405/run-ecosy405-async-contract.sh
```

## Result
- Deterministic Go + Python contract tests passed.
- Go live cancel integration passed.
- Python live cancel integration failed at connect:
  - `InterfaceError: TLS is required for ScratchBird connections`

## Inference
The currently reachable local endpoint in this shell is non-TLS for driver purposes,
while the Python driver enforces TLS and rejects `sslmode=disable`.

## Impact
- Cross-stack runtime cancel parity is only partially validated (Go live pass, Python blocked).
- ECOSYS-405 cannot be closed as runtime-complete in this shell.

## Next step
Re-run ECOSYS-405 live runtime matrix with a TLS-enabled ScratchBird endpoint for the
Python lane.
