# Laravel Eloquent Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Laravel uses `config/database.php` and `.env` variables for connection configuration. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Eloquent expects PDO-based drivers and supports prepared statements by default. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Ensure migration commands (`php artisan migrate`) and schema builder operations are supported. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate schema builder support for indexes and foreign keys. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm Eloquent casts (date, json, array) match ScratchBird types. | Yes | Deferred | Test criteria from SPECIFICATION.md |
