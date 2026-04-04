# ScratchBird Driver Implementation Audit

Status: Current  
Last Updated: 2026-04-03  
Scope: Driver lanes under `tracks/p3/drivers/`, audited against the lane-local JDBC/.NET-class baseline mappings.

## Findings

1. Not every lane is at full JDBC/.NET baseline parity today.
2. The following lanes are currently fully implemented across `CONN`, `TXN`, `EXEC`, `META`, `TYPE`, `ERR`, and `RES`:
   - `cpp`
   - `dotnet`
   - `go`
   - `jdbc`
   - `node`
   - `pascal`
   - `php`
   - `python`
   - `ruby`
   - `rust`
3. The following lanes still have real baseline gaps:
   - `dart`
   - `elixir`
   - `odbc`
   - `r`
   - `swift`
4. `mojo` is functionally mapped as implemented in its lane-local baseline file, but it is still not a fully native lane because the Python bridge replacement remains open.
5. `cli` remains partial, but it should be treated as a tooling lane rather than a JDBC/.NET-equivalent application driver.

## Method

Source of truth for this audit:
- lane-local `BASELINE_REQUIREMENT_MAPPING.md` files under `tracks/p3/drivers/*/`
- lane checklists under `docs/planning/driver-checklists/`
- lane `README.md` files where they materially qualify the implementation model

This audit intentionally treats the lane-local baseline mappings as more authoritative than the older cross-driver audit text when they disagree.

## Full-Parity Lanes

These lanes currently declare all baseline groups implemented in their lane-local mappings:

| Lane | Source of truth |
| --- | --- |
| `cpp` | `tracks/p3/drivers/cpp/BASELINE_REQUIREMENT_MAPPING.md` |
| `dotnet` | `tracks/p3/drivers/dotnet/BASELINE_REQUIREMENT_MAPPING.md` |
| `go` | `tracks/p3/drivers/go/BASELINE_REQUIREMENT_MAPPING.md` |
| `jdbc` | `tracks/p3/drivers/jdbc/BASELINE_REQUIREMENT_MAPPING.md` |
| `node` | `tracks/p3/drivers/node/BASELINE_REQUIREMENT_MAPPING.md` |
| `pascal` | `tracks/p3/drivers/pascal/BASELINE_REQUIREMENT_MAPPING.md` |
| `php` | `tracks/p3/drivers/php/BASELINE_REQUIREMENT_MAPPING.md` |
| `python` | `tracks/p3/drivers/python/BASELINE_REQUIREMENT_MAPPING.md` |
| `ruby` | `tracks/p3/drivers/ruby/BASELINE_REQUIREMENT_MAPPING.md` |
| `rust` | `tracks/p3/drivers/rust/BASELINE_REQUIREMENT_MAPPING.md` |

## Partial Lanes

### Dart

Current lane status in `tracks/p3/drivers/dart/BASELINE_REQUIREMENT_MAPPING.md`:
- `CONN`: Implemented
- `TXN`: Partial
- `EXEC`: Partial
- `META`: Partial
- `TYPE`: Partial
- `ERR`: Partial
- `RES`: Partial

Blocking reasons called out in the lane mapping:
- live TXN failure-path validation still missing
- live pagination / `portalSuspended` / SBLR execution coverage still missing
- metadata restriction / wildcard / DDL-editor payload coverage still missing
- live complex-type binary roundtrip coverage still missing
- live server SQLSTATE/code propagation coverage still missing
- live resilience cleanup and idle-validation coverage still missing

Verdict: not yet at full JDBC/.NET baseline parity.

### Elixir

Current lane status in `tracks/p3/drivers/elixir/BASELINE_REQUIREMENT_MAPPING.md`:
- `CONN`: Implemented
- `TXN`: Implemented
- `EXEC`: Partial
- `META`: Implemented
- `TYPE`: Implemented
- `ERR`: Implemented
- `RES`: Partial

Blocking reasons called out in the lane mapping:
- no standalone public portal-resume helper and limited deterministic stream/paging proof
- resilience is still fresh-connect-only rather than transparent in-place reconnect

Verdict: not yet at full JDBC/.NET baseline parity.

### ODBC

Current lane status in `tracks/p3/drivers/odbc/BASELINE_REQUIREMENT_MAPPING.md`:
- `CONN`: Implemented
- `TXN`: Implemented
- `EXEC`: Implemented
- `META`: Partial
- `TYPE`: Implemented
- `ERR`: Implemented
- `RES`: Implemented

Blocking reason called out in the lane mapping:
- recursive schema browse metadata is present, but broader full-family metadata parity and richer catalog surfaces remain incomplete

Verdict: not yet at full JDBC/.NET baseline parity.

### R

Current lane status in `tracks/p3/drivers/r/BASELINE_REQUIREMENT_MAPPING.md`:
- `CONN`: Partial
- `TXN`: Implemented
- `EXEC`: Implemented
- `META`: Partial
- `TYPE`: Implemented
- `ERR`: Implemented
- `RES`: Implemented

Blocking reasons called out in the lane mapping:
- connection/auth integration coverage remains environment-gated and is still called out as a lane gap
- richer privilege/key/type and DDL-editor metadata parity remains incomplete

Verdict: not yet at full JDBC/.NET baseline parity.

### Swift

Current lane status in `tracks/p3/drivers/swift/BASELINE_REQUIREMENT_MAPPING.md`:
- `CONN`: Implemented
- `TXN`: Implemented
- `EXEC`: Partial
- `META`: Partial
- `TYPE`: Partial
- `ERR`: Partial
- `RES`: Partial

Blocking reasons called out in the lane mapping:
- live cancellation timing and portal suspend/resume execution coverage missing
- metadata coverage still limited relative to full catalog payload families
- live codec roundtrip coverage for advanced types missing
- live auth/connect error propagation coverage still incomplete
- pool wait-queue/timeout/fault-recovery semantics still incomplete

Verdict: not yet at full JDBC/.NET baseline parity.

## Special Cases

### Mojo

`tracks/p3/drivers/mojo/BASELINE_REQUIREMENT_MAPPING.md` currently marks all baseline groups implemented, but the lane remains architecturally incomplete as a native driver:
- `tracks/p3/drivers/mojo/README.md` states that the current implementation is a Mojo-Python interop lane
- `docs/planning/driver-checklists/mojo.md` still has an open unchecked task to replace the Python bridge with a native SBWP client
- `tracks/p3/drivers/mojo/README.md` still says native Mojo transport/auth remains future work

Verdict:
- functional surface: close to or at the JDBC/.NET-class baseline
- implementation architecture: not yet fully closed as a native driver lane

### CLI

`tracks/p3/drivers/cli/BASELINE_REQUIREMENT_MAPPING.md` is still partial:
- `TXN`: Partial
- `META`: Partial
- `TYPE`: Partial
- `RES`: Partial

This lane should be tracked separately from the application-driver parity set because it is a tooling/admin lane, not a language driver expected to mirror JDBC/.NET semantics directly.

## Overall Verdict

The repository does not currently support the claim that every driver is already up to the full JDBC/.NET implementation bar.

Current state:
- full-parity application-driver lanes: `10`
- partial application-driver lanes: `5`
- functionally strong but still hybrid/native-incomplete lane: `1` (`mojo`)
- tooling lane outside the core parity set: `1` (`cli`)

For current structured status by lane, see:
- `docs/audit/DRIVER_IMPLEMENTATION_AUDIT_MATRIX.csv`
