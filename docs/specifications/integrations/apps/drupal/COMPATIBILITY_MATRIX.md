# Drupal Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P2

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| Drupal uses `settings.php` and a `databases` array for connection configuration. | Yes | Deferred | Constraint from SPECIFICATION.md |
| PDO support is required for database backends. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Schema management relies on Drupal's database API. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate Drupal installation and module enablement. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm `drush sql:query` runs with parameters. | Yes | Deferred | Test criteria from SPECIFICATION.md |
