# PHP Driver Checklist

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `php/src/Errors.php`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: PDO errorInfo arrays include SQLSTATE as element 0. (Source: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`)
- [ ] Constraint: Statement errorInfo is separate from connection errorInfo. (Source: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`)
- [ ] Test: Validate PDO::errorInfo and PDOStatement::errorInfo SQLSTATE values. (Source: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`)
- [ ] Test: Verify fetch modes and error mode behavior. (Source: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`)
- [ ] Constraint: Joomla stores DB config in `configuration.php` and expects a PDO or MySQLi-style driver. (Source: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)
- [ ] Constraint: Table prefixes and schema initialization must be supported. (Source: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)
- [ ] Constraint: UTF-8 charset support is required for multilingual content. (Source: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)
- [ ] Test: Validate Joomla installation and administrator login. (Source: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)
- [ ] Test: Confirm extension install and upgrade path. (Source: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)
- [ ] Constraint: Magento stores DB configuration in `app/etc/env.php` and expects MySQL-compatible behavior. (Source: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)
- [ ] Constraint: Large catalog schemas require long-running migrations and indexed queries. (Source: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)
- [ ] Constraint: UTF-8 and JSON column types must be stable. (Source: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)
- [ ] Test: Validate Magento setup:upgrade completes. (Source: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)
- [ ] Test: Confirm catalog search and checkout workflows. (Source: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)
- [ ] Constraint: WordPress expects MySQL/MariaDB-compatible behavior and config in `wp-config.php`. (Source: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)
- [ ] Constraint: PHP extensions must provide `mysqli`/PDO-style behavior. (Source: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)
- [ ] Constraint: Collation and charset must be stable for UTF-8 content. (Source: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)
- [ ] Test: Validate WordPress install and admin login with ScratchBird. (Source: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)
- [ ] Test: Confirm basic CRUD for posts, users, and taxonomy. (Source: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)
- [ ] Constraint: WooCommerce relies on WordPress database behavior and uses the same `wp-config.php` settings. (Source: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)
- [ ] Constraint: High-concurrency order updates require stable transactions and row-level locking. (Source: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)
- [ ] Constraint: UTF-8 and JSON metadata must be preserved. (Source: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)
- [ ] Test: Validate WooCommerce install and product CRUD. (Source: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)
- [ ] Test: Confirm order creation, payment, and refund flows. (Source: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)
- [ ] Constraint: Drupal uses `settings.php` and a `databases` array for connection configuration. (Source: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)
- [ ] Constraint: PDO support is required for database backends. (Source: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)
- [ ] Constraint: Schema management relies on Drupal's database API. (Source: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)
- [ ] Test: Validate Drupal installation and module enablement. (Source: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)
- [ ] Test: Confirm `drush sql:query` runs with parameters. (Source: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)
- [ ] Constraint: Laravel uses `config/database.php` and `.env` variables for connection configuration. (Source: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)
- [ ] Constraint: Eloquent expects PDO-based drivers and supports prepared statements by default. (Source: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)
- [ ] Constraint: Ensure migration commands (`php artisan migrate`) and schema builder operations are supported. (Source: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)
- [ ] Test: Validate schema builder support for indexes and foreign keys. (Source: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)
- [ ] Test: Confirm Eloquent casts (date, json, array) match ScratchBird types. (Source: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)


## P2 (Follow-ups)

- [ ] Add conformance tests for full type matrix in `php/tests/`. Issue: TBD
