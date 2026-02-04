# WordPress Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| WordPress expects MySQL/MariaDB-compatible behavior and config in `wp-config.php`. | Yes | Deferred | Constraint from SPECIFICATION.md |
| PHP extensions must provide `mysqli`/PDO-style behavior. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Collation and charset must be stable for UTF-8 content. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate WordPress install and admin login with ScratchBird. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm basic CRUD for posts, users, and taxonomy. | Yes | Deferred | Test criteria from SPECIFICATION.md |
