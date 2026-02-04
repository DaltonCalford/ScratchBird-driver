# Mojo Driver Completion Checklist

This checklist maps directly to `docs/specifications/DRIVER_MOJO_NATIVE_API.md`
and the shared SBWP conformance fixtures.

## 1) Goal + Constraints (Spec: Goal, Constraints)

- [ ] Confirm Mojo package layout: `scratchbird_mojo` with `scratchbird`, `scratchbird/protocol`, `scratchbird/transport`.
- [x] Document transport isolation boundaries for swapping TCP/TLS implementation later (see `mojo/README.md`).
- [ ] Remove Python transport dependency in runtime path.

## 2) Configuration + DSN (Spec: Configuration)

- [x] Implement DSN parser conforming to `DRIVER_DSN_AND_CONFIG_STANDARD.md` (delegates to Python driver parser).
- [x] Enforce `binary_transfer=true`; reject `binary_transfer=false`.
- [ ] Enforce TLS requirement; reject `sslmode=disable`.
- [ ] Map config keys: host, port, database, user, password, sslmode, sslrootcert, sslcert, sslkey, sslpassword,
      connect_timeout_ms, socket_timeout_ms, application_name, search_path, role, compression, fetch_size.

## 3) Protocol (Spec: API Surface + Prepare/Bind)

- [ ] Implement SBWP v1.1 message encoding/decoding for Startup, Auth, Query, Parse, Bind, Describe, Execute, Sync, Cancel.
- [ ] Implement Ready/RowDescription/DataRow/CommandComplete/Error/Notice parsing.
- [ ] Implement SCRAM-SHA-256 authentication.
- [ ] Implement server-side prepare/bind with positional parameters.
- [ ] Implement paging via portal `max_rows` and `MSG_PORTAL_SUSPENDED`.

## 4) Transactions (Spec: Transactions)

- [x] Support BEGIN/COMMIT/ROLLBACK (delegated to Python bridge).
- [x] Support savepoints (savepoint/release/rollback-to) (delegated to Python bridge).
- [ ] Support read-only and isolation options where provided.

## 5) Types + Wrappers (Spec: Type Mapping)

- [ ] Encode/decode core types per `TYPE_MAPPING_MATRIX.md`.
- [ ] Implement wrapper types: JSONB, RANGE, GEOMETRY.
- [ ] Verify binary encoding for DATE/TIME/TIMESTAMP/UUID.

## 6) Errors (Spec: Error Handling)

- [ ] Map protocol errors to `ScratchBirdError` with sqlstate/code/detail.
- [ ] Implement SQLSTATE mapping per `DRIVER_ERROR_MAPPING.md`.
- [ ] Surface cancel (SQLSTATE 57014) distinctly.

## 7) Observability (Spec: Observability)

- [ ] Always send `application_name` on startup.
- [ ] Expose server version/backend id where provided.
- [ ] Expose last query plan + last SBLR compiled payload (optional but recommended).

## 8) Conformance Fixtures (Spec: Conformance Tests)

Use `docs/fixtures/sbwp_conformance_manifest.json` and fixtures:

- [ ] **Handshake**: `SELECT 1` (fixture `core_fixture.sql`)
- [ ] **Auth**: SCRAM ok in manifest
- [ ] **Prepare/Bind**: `SELECT $1::INTEGER`
- [ ] **Param mismatch**: expect SQLSTATE `07001`
- [ ] **Types**: `type_coverage`
- [ ] **Paging**: `fetch_size` with portal paging
- [ ] **Cancel**: `SQLSTATE 57014` on cancel

## 9) Deliverables (Spec: Deliverables)

- [ ] `scratchbird_mojo` package with examples.
- [ ] Integration tests gated by `SCRATCHBIRD_TEST_DSN`.
- [ ] Update `mojo/README.md` to reflect native transport completion.
