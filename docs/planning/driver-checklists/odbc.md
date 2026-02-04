# ODBC Driver Checklist

## P1 (Core)

- [ ] Expand type mapping to cover complex SBWP types where applicable in `odbc/src/odbc_client_bridge.cpp`. Issue: TBD

## P2 (Follow-ups)

- [x] Removed fallback metadata queries; use only server-defined `sys.columns` and `sys.index_columns` columns in `odbc/src/odbc_handles.cpp`. Issue: N/A
- [ ] Add conformance tests for metadata + type coverage in `odbc/tests/`. Issue: TBD
