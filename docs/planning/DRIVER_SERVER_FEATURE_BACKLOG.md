# Driver-Visible Server Features Backlog

Status: Open
Last Updated: 2026-01-30

Purpose: provide a server-side work list that unlocks higher driver
conformance and optional capabilities.

## Scope

Targets ScratchBird server changes only. Drivers already contain the hooks or
guards; once each item is implemented server-side, the driver specs and
conformance suite can be updated to enable it.

## Backlog (Priority Order)

1. Compression (zstd)
   - Add negotiated compression flag to STARTUP/READY.
   - Implement message compress/decompress in SBWP.
   - Enable `compression=zstd` in drivers + conformance test.

2. COPY/Bulk streaming
   - Define COPY request/response frames and error behavior.
   - Implement binary COPY IN/OUT.
   - Add conformance test for row count + checksum.

3. Large object streaming
   - Define BLOB/CLOB chunk frames (size + sequence).
   - Expose streaming API in sys.* or protocol.
   - Add conformance test (stream + checksum).

4. Prepared statement cache + stats
   - Add server cache + eviction policy.
   - Add sys.prepared_statements (hits, misses, avg time).
   - Update JDBC prepareThreshold guidance.

5. Holdable/named portals
   - Support named portals across transactions.
   - Add scrollable cursor semantics for JDBC/.NET.
   - Provide sys.portal_stats (optional).

6. Capability negotiation flags
   - Add explicit feature flags in READY/parameter status.
   - Drivers auto-enable when flag present.

7. Query progress/metrics frames
   - Emit periodic progress frames or sys.query_progress.
   - Enable UI progress + smarter cancel UX.

8. Event/notification channel
   - Add LISTEN/NOTIFY or SBWP event frames.
   - Driver-level callbacks for UI tooling.

9. Richer metadata views
   - sys.index_columns (if missing), sys.constraints, sys.domains, sys.enums,
     expression index metadata, partitioning info, table stats.
   - Improves BI tooling + driver metadata fidelity.

## Tracking Notes

- Once each item is implemented, update
  `docs/specifications/DRIVER_SERVER_FEATURE_GAPS_AND_EXTENSIONS.md`
  and expand the conformance suite.
