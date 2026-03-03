# DLB-PHP-004 S3 Metadata Implementation

Date: 2026-03-03  
Lane: `tracks/alpha/drivers/php`

## What Changed

1. Added metadata-only recursive schema shaping helpers in `src/Metadata.php`:
   - `schemaPathsForNavigation(...)` and `expandSchemaPaths(...)` for normalized schema path handling and dotted parent expansion.
   - `listMetadataSchemaPaths(...)` for metadata-row schema path extraction plus optional parent expansion mode.
   - `buildMetadataSchemaTree(...)` for recursive schema tree generation with:
     - optional parent expansion,
     - per-parent uniqueness,
     - same leaf-name support under different parent paths,
     - optional database label on output.
   - `expandSchemaMetadataRows(...)` for metadata-row parent expansion that emits synthetic ancestor rows while preserving physical leaf rows.
2. Extended executable metadata collection routing in `src/Metadata.php`:
   - Added query constants and resolvers for extended metadata families:
     - `catalogs`
     - `primary_keys`
     - `foreign_keys`
     - `table_privileges`
     - `column_privileges`
     - `type_info`
     - `routines`
   - Expanded alias normalization (including separator/case variants like `primaryKeys`, `table privileges`, `column-privileges`).
3. Added focused lane tests in `tests/MetadataRecursiveSchemaTest.php` covering:
   - database/default branch-style metadata rows,
   - dotted parent expansion,
   - no duplicates within the same parent,
   - same leaf name under different parents.
4. Added metadata execution tests in `tests/MetadataExecutionTest.php` covering:
   - extended alias normalization,
   - extended collection query resolution,
   - connection-level metadata execution path (`Connection::getSchema(...)`) with wire-fixture validation of emitted metadata SQL,
   - unsupported collection mapping to `ScratchBirdNotSupportedException` (`0A000`).
5. Updated `BASELINE_REQUIREMENT_MAPPING.md` META evidence anchors and status note.

## Tests Run

1. `vendor/bin/phpunit --bootstrap tests/bootstrap.php tests/MetadataRecursiveSchemaTest.php tests/MetadataExecutionTest.php`
   Result: PASS

## META Status Recommendation

Recommendation: `Partial`

Why:
- The lane now has executable metadata collection routing and validation for extended metadata families plus wire-level execution-path tests.
- Recursive schema-tree shaping behavior remains covered with dedicated tests.
- Status remains `Partial` because live metadata integration assertions and richer restriction-aware metadata shaping are still pending.

## Blockers

1. Live metadata integration assertions against an active ScratchBird endpoint are still missing.
