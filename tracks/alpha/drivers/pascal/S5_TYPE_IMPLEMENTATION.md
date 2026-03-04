# DLB-PASCAL-006 S5 TYPE Implementation

Date: 2026-03-04  
Lane: `tracks/alpha/drivers/pascal`  
Scope: close current `TYPE` lane gaps around deterministic codec evidence and explicit `TIMETZ` handling.

## Changes Implemented

1. `TIMETZ` encode/decode implementation in lane type codec
   - File: `src/ScratchBird.Types.pas`
   - Added:
     - `NormalizeMicrosOfDay(...)` helper for day-wrap normalization.
     - `EncodeTimeTzValue(...)` producing binary payload as `int64 micros` + `int32 zone_seconds_west`.
     - `DecodeTimeTzValue(...)` with:
       - full 12-byte decode (`time + zone`),
       - backward-compatible 8-byte decode (`time` only => UTC offset).
     - explicit `OID_TIMETZ` decode branch in `DecodeValue(...)`.
   - Added variant-array encode input path:
     - `[TDateTime timeOfDay, offsetSecondsEast]` -> `OID_TIMETZ` binary payload.

2. Integer variant subtype parity hardening
   - File: `src/ScratchBird.Types.pas`
   - Expanded scalar and numeric-array routing to include `varByte`, `varShortInt`, `varWord`, `varLongWord` in addition to existing integer variants.
   - This prevents small integer variant values from falling back to text encoding in codec paths.

3. New deterministic type codec lane tests
   - File: `tests/TypesCodecTests.pas`
   - Covers representative encode/decode assertions for:
     - scalar bool/uuid
     - vector, jsonb, composite
     - unknown-type text/binary heuristics
     - `TIMETZ` 12-byte decode semantics
     - `TIMETZ` 8-byte backward-compatible decode semantics
     - `TIMETZ` encode payload shape/sign semantics

## Targeted Tests Run

1. Type codec suite
   - `mkdir -p /tmp/sb_pascal_type_build /tmp/sb_pascal_type_bin`
   - `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_type_build -FE/tmp/sb_pascal_type_bin ./tracks/alpha/drivers/pascal/tests/TypesCodecTests.pas`
   - `/tmp/sb_pascal_type_bin/TypesCodecTests`
   - Result: PASS (`TypesCodecTests: OK`)

2. Full Pascal lane regression sweep
   - `set -euo pipefail`
   - `mkdir -p /tmp/sb_pascal_reg_build /tmp/sb_pascal_reg_bin`
   - `for test in ConfigTests ConnectionAuthProtocolTests TxnExecParityTests SqlTests MetadataRecursiveSchemaTests ResourceResilienceTests TlsCryptoAndPolicyTests IntegrationTest TypesCodecTests; do`
   - `  fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_reg_build -FE/tmp/sb_pascal_reg_bin ./tracks/alpha/drivers/pascal/tests/${test}.pas >/tmp/sb_pascal_reg_build/${test}.compile.log`
   - `  /tmp/sb_pascal_reg_bin/${test}`
   - `done`
   - Result: PASS
     - `ConfigTests: OK`
     - `ConnectionAuthProtocolTests: OK`
     - `TxnExecParityTests: OK`
     - `SqlTests: OK`
     - `MetadataRecursiveSchemaTests: OK`
     - `ResourceResilienceTests: OK`
     - `TlsCryptoAndPolicyTests: OK`
     - `IntegrationTest: SKIPPED (SCRATCHBIRD_PASCAL_URL not set)`
     - `TypesCodecTests: OK`

## TYPE Status Recommendation

- Recommendation: keep `PARTIAL`
- Rationale:
  - `TIMETZ` handling and representative deterministic codec tests are now implemented and anchored.
  - Remaining work is exhaustive per-OID matrix depth and live integration breadth, not the previously open `TIMETZ` codec gap.

## Remaining Gaps

1. Expand deterministic tests from representative codec coverage to exhaustive per-OID matrix.
2. Add non-env-gated live type integration assertions (current integration fixture remains env-gated).
