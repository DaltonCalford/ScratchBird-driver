# DLB-PASCAL-006 S5 TYPE Implementation

Date: 2026-03-04  
Lane: `tracks/alpha/drivers/pascal`  
Scope: expand deterministic `TYPE` lane codec coverage from representative assertions toward broader per-OID matrix depth while preserving the explicit `TIMETZ` behavior already implemented.

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

3. Expanded deterministic type codec lane tests
   - File: `tests/TypesCodecTests.pas`
   - Expanded coverage now includes:
     - scalar decode matrix (`INT2/INT4/INT8/FLOAT4/FLOAT8/NUMERIC/MONEY`)
     - text-family decode matrix (`TEXT/VARCHAR/CHAR/BPCHAR/JSON/XML/TSVECTOR/TSQUERY/INET/CIDR/MACADDR/MACADDR8`)
     - temporal/interval decode matrix (`DATE/TIME/TIMESTAMP/TIMESTAMPTZ/INTERVAL`)
     - primitive encode matrix (int/float/text/date-variant + mixed array fallback behavior)
     - object wrapper encode/decode matrix (JSONB, geometry object path, range object path including int/timestamp ranges)
     - geometry-family decode matrix (`POINT/LSEG/PATH/BOX/POLYGON/LINE/CIRCLE`)
     - existing `TIMETZ` decode/encode coverage (12-byte, backward-compatible 8-byte, payload sign semantics)

## Targeted Tests Run

1. Type codec suite
   - `mkdir -p /tmp/sb_pascal_type_build /tmp/sb_pascal_type_bin`
   - `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_type_build -FE/tmp/sb_pascal_type_bin ./tracks/alpha/drivers/pascal/tests/TypesCodecTests.pas`
   - `/tmp/sb_pascal_type_bin/TypesCodecTests`
   - Result: PASS (`TypesCodecTests: OK`)

2. Targeted Pascal lane regression sweep
   - `set -euo pipefail`
   - `tests=(ConnectionAuthProtocolTests ConnectionDirectAuthMatrixTests ConnectionManagerProxyTests TxnExecParityTests TxnStateTransitionsTests BatchExecutionTests QueryMultiTests StreamControlBackpressureTests MetadataRecursiveSchemaTests AdapterMetadataApiTests MetadataExecutionFlowTests TypesCodecTests ResourceResilienceTests)`
   - `for test in "${tests[@]}"; do`
   - `  build_dir="/tmp/sb_pascal_reg_${test}_build"`
   - `  bin_dir="/tmp/sb_pascal_reg_${test}_bin"`
   - `  fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU"$build_dir" -FE"$bin_dir" ./tracks/alpha/drivers/pascal/tests/${test}.pas >/tmp/${test}.compile.log`
   - `  "$bin_dir/${test}" >/tmp/${test}.run.log`
   - `done`
   - Result: PASS
     - `ConnectionAuthProtocolTests: OK`
     - `ConnectionDirectAuthMatrixTests: OK`
     - `ConnectionManagerProxyTests: OK`
     - `TxnExecParityTests: OK`
     - `TxnStateTransitionsTests: OK`
     - `BatchExecutionTests: OK`
     - `QueryMultiTests: OK`
     - `StreamControlBackpressureTests: OK`
     - `MetadataRecursiveSchemaTests: OK`
     - `AdapterMetadataApiTests: OK`
     - `MetadataExecutionFlowTests: OK`
     - `ResourceResilienceTests: OK`
     - `TypesCodecTests: OK`

## TYPE Status Recommendation

- Recommendation: keep `PARTIAL`
- Rationale:
  - Deterministic `TIMETZ` handling remains implemented and now sits inside a broader scalar/temporal/text/range/geometry codec matrix.
  - Remaining work is no longer the original `TIMETZ` gap; it is final edge-case matrix depth plus live integration breadth.

## Remaining Gaps

1. Continue extending deterministic coverage toward exhaustive edge payload variants (for example additional bytea/null/limit shape assertions).
2. Add non-env-gated live type integration assertions (current integration fixture remains env-gated).
