# Joomla Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P2

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Joomla stores DB config in `configuration.php` and expects a PDO or MySQLi-style driver. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Table prefixes and schema initialization must be supported. | Yes | Deferred | Constraint from SPECIFICATION.md |
| UTF-8 charset support is required for multilingual content. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Joomla installation and administrator login. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm extension install and upgrade path. | Yes | Deferred | Test criteria from SPECIFICATION.md |
