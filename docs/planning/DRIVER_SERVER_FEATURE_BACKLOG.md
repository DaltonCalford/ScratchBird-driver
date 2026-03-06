# Driver-Visible Server Features Backlog

Status: Open
Last Updated: 2026-03-06

Purpose: provide a server-side work list that unlocks higher driver
conformance and optional capabilities.

## Scope

Targets ScratchBird server changes only. Drivers already contain the hooks or
guards; once each item is implemented server-side, the driver specs and
conformance suite can be updated to enable it.

## Backlog (Priority Order)

1. Auth plugin handshake + capability advertisement
   - Add explicit handshake fields for auth plugin negotiation and server-selected
     method/profile disclosure so drivers can connect without pre-knowing enabled
     plugins.
   - Ensure AUTH_CHALLENGE/AUTH_CONTINUE paths surface deterministic plugin
     metadata and capability flags for non-SCRAM methods.
   - Add server-driven fallback behavior and conformance fixtures for unknown
     plugin configurations.
   - Note: Deferred until current server auth/plugin refactor is completed by the
     active ScratchBird server agent.

2. Compression (zstd)
   - Add negotiated compression flag to STARTUP/READY.
   - Implement message compress/decompress in SBWP.
   - Enable `compression=zstd` in drivers + conformance test.

3. COPY/Bulk streaming
   - Define COPY request/response frames and error behavior.
   - Implement binary COPY IN/OUT.
   - Add conformance test for row count + checksum.

4. Large object streaming
   - Define BLOB/CLOB chunk frames (size + sequence).
   - Expose streaming API in sys.* or protocol.
   - Add conformance test (stream + checksum).

5. Prepared statement cache + stats
   - Add server cache + eviction policy.
   - Add sys.prepared_statements (hits, misses, avg time).
   - Update JDBC prepareThreshold guidance.

6. Holdable/named portals
   - Support named portals across transactions.
   - Add scrollable cursor semantics for JDBC/.NET.
   - Provide sys.portal_stats (optional).

7. Capability negotiation flags
   - Add explicit feature flags in READY/parameter status.
   - Drivers auto-enable when flag present.

8. Query progress/metrics frames
   - Emit periodic progress frames or sys.query_progress.
   - Enable UI progress + smarter cancel UX.

9. Event/notification channel
   - Add LISTEN/NOTIFY or SBWP event frames.
   - Driver-level callbacks for UI tooling.

10. Richer metadata views
   - sys.index_columns (if missing), sys.constraints, sys.domains, sys.enums,
     expression index metadata, partitioning info, table stats.
   - Improves BI tooling + driver metadata fidelity.

## Tracking Notes

- Once each item is implemented, update
  `docs/specifications/DRIVER_SERVER_FEATURE_GAPS_AND_EXTENSIONS.md`
  and expand the conformance suite.
