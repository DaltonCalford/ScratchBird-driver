# WooCommerce Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P1

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| WooCommerce relies on WordPress database behavior and uses the same `wp-config.php` settings. | Yes | Deferred | Constraint from SPECIFICATION.md |
| High-concurrency order updates require stable transactions and row-level locking. | Yes | Deferred | Constraint from SPECIFICATION.md |
| UTF-8 and JSON metadata must be preserved. | Yes | Deferred | Constraint from SPECIFICATION.md |
| Validate WooCommerce install and product CRUD. | Yes | Deferred | Test criteria from SPECIFICATION.md |
| Confirm order creation, payment, and refund flows. | Yes | Deferred | Test criteria from SPECIFICATION.md |
