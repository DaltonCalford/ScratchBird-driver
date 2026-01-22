# Prepare/Bind Requirements (ScratchBird Drivers)

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define how drivers must implement server-side prepared statements and parameter
binding using SBWP v1.1. Client-side SQL substitution is not allowed for
parameterized execution.

## Authoritative Reference

- `ScratchBird/docs/specifications/wire_protocols/scratchbird_native_wire_protocol.md`
  - Section 9: Prepared Statements
  - Section 15: Type Serialization

## Requirements

1. Placeholder conventions
   - Drivers must translate language-native placeholders into SBWP "$1" style.
   - Named placeholders must be rewritten into positional indexes before PARSE.

2. Server-side prepare
   - Use PARSE with parameter type OIDs when known.
   - Use DESCRIBE to retrieve parameter and result metadata.

3. Binding
   - Use BIND with per-parameter format codes (text or binary).
   - NULL values must be encoded with length = -1 and no payload.
   - Binary encoding must follow SBWP Type Serialization.

4. Execution
   - Use EXECUTE with an optional max_rows for paging.
   - Use SYNC to terminate a portal sequence and return to READY.

5. Batching
   - Batch execution must reuse PARSE and issue repeated BIND/EXECUTE cycles.
   - No string concatenation of values into SQL for batches.

6. Errors
   - Parameter count mismatches must surface as client errors before execution.
   - Server-side bind errors must map to SQLSTATE and driver-native exceptions.

## Prohibited

- Client-side SQL substitution for parameters.
- Inline quoting/escaping of parameter values.
- Mixing text-encoded parameters with binary result formats unless explicitly supported.

