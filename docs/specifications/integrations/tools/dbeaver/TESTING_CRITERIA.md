# DBeaver Integration Testing Criteria

Status: Updated 2026-03-13
Priority: P0
Category: Database Tool

## Required Coverage

1. JDBC driver tests still cover ScratchBird metadata behavior needed by
   DBeaver.
2. DBeaver-side plugin tests cover recursive tree declarations and tree
   inflation logic.
3. SQL dialect/editor tests cover ScratchBird-specific editor binding.
4. UI/plugin tests cover editor/configurator/connection-page registration once
   those modules exist.
5. Packaging validation confirms the p2 repository builds successfully.
6. Source-checkout install validation confirms patched files remain single-entry
   after reruns.
7. Live validation confirms recursive schemas browse correctly in DBeaver.
8. Live validation confirms supported object managers, editors, auth/network
   flows, and tools behave correctly.

## Required Test Anchors

1. `tracks/p3/drivers/jdbc/src/test/java/com/scratchbird/jdbc/SBDriverTest.java`
2. `tracks/p3/drivers/jdbc/src/test/java/com/scratchbird/jdbc/SBDatabaseMetaDataSchemasTest.java`
3. `tracks/alpha/integrations/scratchbird-dbeaver-driver/plugins/org.jkiss.dbeaver.ext.scratchbird/src/org/jkiss/dbeaver/ext/scratchbird/model/ScratchBirdSchemaTreeSmoke.java`
4. `tracks/alpha/integrations/scratchbird-dbeaver-driver/test/org.jkiss.dbeaver.ext.scratchbird.test/src/org/jkiss/dbeaver/ext/scratchbird/model/ScratchBirdIntegrationTest.java`
5. future ScratchBird SQL dialect tests
6. future ScratchBird UI plugin tests

## Live Validation Checklist

1. Connect DBeaver to a live ScratchBird instance.
2. Confirm nested schemas render as directories.
3. Confirm terminal schema nodes expose tables, views, and data types.
4. Confirm `sys` and `sys.*` are treated as system schemas.
5. Confirm SQL editor/autocomplete binds to ScratchBird dialect behavior.
6. Confirm supported object editors and managers appear only for supported
   ScratchBird object families.
7. Confirm supported auth/network flows are exposed in connection UI.
8. Confirm plugin install/update path works from the generated p2 zip.
