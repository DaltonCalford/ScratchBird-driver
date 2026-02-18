# PHP Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

- [ ] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/php/src/Errors.php`. Issue: Open (2026-02-04)

### Integration Appendix Tasks

- [x] Constraint: PDO errorInfo arrays include SQLSTATE as element 0. (Sources: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Statement errorInfo is separate from connection errorInfo. (Sources: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate PDO::errorInfo and PDOStatement::errorInfo SQLSTATE values. (Sources: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Verify fetch modes and error mode behavior. (Sources: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
## P2 (Follow-ups)

### Integration Appendix Tasks

- [x] Constraint: Magento stores DB configuration in `app/etc/env.php` and expects MySQL-compatible behavior. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Large catalog schemas require long-running migrations and indexed queries. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: UTF-8 and JSON column types must be stable. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate Magento setup:upgrade completes. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm catalog search and checkout workflows. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: WordPress expects MySQL/MariaDB-compatible behavior and config in `wp-config.php`. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: PHP extensions must provide `mysqli`/PDO-style behavior. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Collation and charset must be stable for UTF-8 content. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate WordPress install and admin login with ScratchBird. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm basic CRUD for posts, users, and taxonomy. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: WooCommerce relies on WordPress database behavior and uses the same `wp-config.php` settings. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: High-concurrency order updates require stable transactions and row-level locking. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: UTF-8 and JSON metadata must be preserved. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate WooCommerce install and product CRUD. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm order creation, payment, and refund flows. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Laravel uses `config/database.php` and `.env` variables for connection configuration. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Eloquent expects PDO-based drivers and supports prepared statements by default. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Ensure migration commands (`php artisan migrate`) and schema builder operations are supported. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate schema builder support for indexes and foreign keys. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm Eloquent casts (date, json, array) match ScratchBird types. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Add conformance tests for full type matrix in `tracks/alpha/drivers/php/tests/`. Issue: DONE (2026-02-04) (Sources: ``)
## P3 (Future)

### Integration Appendix Tasks

- [x] Constraint: Joomla stores DB config in `configuration.php` and expects a PDO or MySQLi-style driver. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Table prefixes and schema initialization must be supported. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: UTF-8 charset support is required for multilingual content. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate Joomla installation and administrator login. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm extension install and upgrade path. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Drupal uses `settings.php` and a `databases` array for connection configuration. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: PDO support is required for database backends. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Schema management relies on Drupal's database API. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate Drupal installation and module enablement. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm `drush sql:query` runs with parameters. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
