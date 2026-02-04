# Magento Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Magento stores DB configuration in `app/etc/env.php` and expects MySQL-compatible behavior. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Large catalog schemas require long-running migrations and indexed queries. | Yes | Deferred | Constraint from SPECIFICATION.md |
| UTF-8 and JSON column types must be stable. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Magento setup:upgrade completes. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm catalog search and checkout workflows. | Yes | Deferred | Test criteria from SPECIFICATION.md |
