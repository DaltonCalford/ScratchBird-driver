# C/C++ Client Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)
- [x] Expand `sb_type` and `sb_value` coverage to full SBWP type matrix in `tracks/beta/drivers/cpp/include/scratchbird/client/scratchbird_client.h`. Issue: TBD
- [x] Implement encoding/decoding for arrays, composite, range, geometry, vector, inet/cidr/macaddr in `tracks/beta/drivers/cpp/src/`. Issue: TBD
- [x] Expose SET_OPTION and PING helpers in `tracks/beta/drivers/cpp/include/scratchbird/client/scratchbird_client.h` and `tracks/beta/drivers/cpp/src/scratchbird_client_c.cpp`. Issue: TBD
- [x] Add sys.* metadata helper queries or API in `tracks/beta/drivers/cpp/include/scratchbird/client/`. Issue: TBD


## P2 (Follow-ups)
- [x] Add conformance tests for type mapping and paging in `tracks/beta/drivers/cpp/tests/`. Issue: TBD

## P3 (Future)

### Integration Appendix Tasks

- [ ] Constraint: Provide a stable C API façade for language bindings where ABI stability is required. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)
- [ ] Constraint: Support both static and shared builds with explicit linkage flags. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)
- [ ] Constraint: Document ownership of buffers returned to callers. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)
- [ ] Test: Verify both static and shared builds link successfully. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)
- [ ] Test: Validate row buffers remain valid until the next fetch call. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)