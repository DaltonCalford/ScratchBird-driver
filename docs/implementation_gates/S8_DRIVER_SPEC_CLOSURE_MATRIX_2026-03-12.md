# S8 Driver Spec Closure Matrix (2026-03-12)

## Objective

Record the post-`NCW-056` closure state for all PH5 driver lanes after the
residual-expansion block `NCW-054A..054D`, beta closure `NCW-055`, and
specialty closure `NCW-056`.

## Source of truth

- `tracks/*/drivers/*/BASELINE_REQUIREMENT_MAPPING.md`
- `docs/implementation_gates/S7_PROMOTION_DECISIONS_2026-03-12.md`
- `local_work/docs/planning/NON_CLUSTER_IMPLEMENTATION_CLOSURE_WORKTREE/evidence/NCW-051..056`

## Regenerated conclusion

- PH5 no longer carries optional or residual driver surfaces.
- All declared driver lanes are closed on their currently supported surfaces.
- Cross-driver promotion/regeneration is now an evidence-publishing exercise,
  not an implementation-gap hunt.

## Driver matrix

| Driver | Lane | Closure State | Current supported-surface note |
|---|---|---|---|
| JDBC | `tracks/p3/drivers/jdbc` | MET | Current-schema/default-schema, pool reset, metadata parity, and downstream consumer surfaces closed |
| ODBC | `tracks/p3/drivers/odbc` | MET | Packaged runtime/catalog/type surface closed |
| CPP | `tracks/p3/drivers/cpp` | MET | Listener-mediated C/C++ API surface closed |
| DOTNET | `tracks/p3/drivers/dotnet` | MET | Connection, transaction, metadata, type, and multi-result surface closed |
| GO | `tracks/p3/drivers/go` | MET | Live primary lane closed |
| RUST | `tracks/p3/drivers/rust` | MET | Live parity plus generated-key/callable residuals closed |
| NODE | `tracks/p3/drivers/node` | MET | Routine metadata, metadata helpers, and session-schema behavior closed |
| PYTHON | `tracks/p3/drivers/python` | MET | Metadata, routine, and schema fallback surface closed |
| PHP | `tracks/p3/drivers/php` | MET | Metadata convenience and routine metadata surface closed |
| RUBY | `tracks/p3/drivers/ruby` | MET | Cancel sequencing and specialty residuals closed |
| PASCAL | `tracks/p3/drivers/pascal` | MET | Routine-wrapper, generated-key, and stream-control residuals closed |
| MOJO | `tracks/p3/drivers/mojo` | MET | Supported listener-mediated wire-bridge surface closed |
| CLI | `tracks/p3/drivers/cli` | MET | CLI protocol surface closed on declared PH5 scope |
| DART | `tracks/p3/drivers/dart` | MET | Beta lane full-surface parity closed |
| SWIFT | `tracks/p3/drivers/swift` | MET | Beta lane full-surface parity closed |
| R | `tracks/p3/drivers/r` | MET | Beta lane full-surface parity closed |
| ELIXIR | `tracks/p3/drivers/elixir` | MET | Specialty lane closed on supported listener-mediated surface |

## Closure definition

A lane is `MET` in this regenerated matrix when:

1. Its PH5 ticket is closed in the non-cluster tracker.
2. No residual surface remains intentionally out of scope for PH5.
3. The lane has concrete validation evidence on its claimed supported surface.
4. Promotion language is explicit about supported-surface boundaries.
