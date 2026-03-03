# ScratchBird DBeaver Integration

This folder stores the ScratchBird-specific DBeaver integration assets inside
`ScratchBird-driver` so the work is versioned with the JDBC driver.

## Contents

- `plugins/org.jkiss.dbeaver.ext.scratchbird/`
  ScratchBird DBeaver extension plugin (recursive schema tree + Generic DDL folders)
- `test/org.jkiss.dbeaver.ext.scratchbird.test/`
  DBeaver-side integration tests for plugin metadata behavior
- `scripts/install-into-dbeaver.sh`
  Idempotent installer for a local DBeaver source checkout

## JDBC Driver Improvements Included

The JDBC driver now includes a metadata compatibility switch for recursive
schema tools:

- Property: `metadataExpandSchemaParents` (aliases:
  `metadata_expand_schema_parents`, `expandSchemaParents`,
  `dbeaver_expand_schema_parents`)
- Default: `false`
- Effect when `true`: `DatabaseMetaData.getSchemas()` emits dotted parent
  segments (for example `users`, `users.alice`, `users.alice.dev`), while
  preserving pattern filtering.

This keeps default metadata behavior unchanged for non-DBeaver clients.

## Install Into DBeaver (Source Checkout)

These steps assume:

- ScratchBird driver repo: `~/CliWork/ScratchBird-driver`
- DBeaver repo: `~/CliWork/dbeaver`
- DBeaver common repo: `~/CliWork/dbeaver-common`

### 1) Build ScratchBird JDBC JAR

```bash
cd ~/CliWork/ScratchBird-driver/tracks/alpha/drivers/jdbc
./gradlew clean jar
```

JAR output:

- `~/CliWork/ScratchBird-driver/tracks/alpha/drivers/jdbc/build/libs/scratchbird-jdbc-*.jar`

### 2) Install Plugin Sources Into DBeaver

```bash
cd ~/CliWork/ScratchBird-driver/tracks/alpha/integrations/scratchbird-dbeaver-driver
./scripts/install-into-dbeaver.sh ~/CliWork/dbeaver
```

This copies plugin/test-plugin folders and patches:

- `~/CliWork/dbeaver/plugins/pom.xml`
- `~/CliWork/dbeaver/test/pom.xml`
- `~/CliWork/dbeaver/features/org.jkiss.dbeaver.db.feature/feature.xml`
- `~/CliWork/dbeaver/features/org.jkiss.dbeaver.test.feature/feature.xml`

### 3) Build/Verify In DBeaver

```bash
cd ~/CliWork/dbeaver
~/CliWork/dbeaver-common/mvnw -f product/aggregate/pom.xml \
  -pl ../../../dbeaver-common/modules/org.jkiss.utils,../../../dbeaver-common/modules/com.dbeaver.jdbc.api,../../plugins/org.jkiss.dbeaver.model,../../plugins/org.jkiss.dbeaver.model.jdbc,../../plugins/org.jkiss.dbeaver.model.lsm,../../plugins/org.jkiss.dbeaver.model.sql,../../plugins/org.jkiss.dbeaver.model.sql.jdbc,../../plugins/org.jkiss.dbeaver.registry,../../plugins/org.jkiss.dbeaver.ext.generic,../../plugins/org.jkiss.dbeaver.ext.scratchbird,../../test/org.jkiss.dbeaver.ext.scratchbird.test \
  -am verify -DskipITs
```

Expected: `BUILD SUCCESS`.

### 4) Configure Driver Library In DBeaver UI

The plugin descriptor references `maven:/com.scratchbird:scratchbird-jdbc:RELEASE`.
If you are testing local builds, point the driver to the local JAR:

1. Open `Database` -> `Driver Manager` -> `ScratchBird`
2. `Libraries` tab -> add local file
3. Select:
   `~/CliWork/ScratchBird-driver/tracks/alpha/drivers/jdbc/build/libs/scratchbird-jdbc-*.jar`
4. Save and reconnect

### 5) Optional: Enable Parent Schema Expansion (JDBC Layer)

If you want parent schema rows emitted directly by JDBC metadata:

- Add connection property `metadataExpandSchemaParents=true`

Use this only when needed; default `false` keeps non-DBeaver metadata behavior
unchanged.

## Update Workflow

When this integration is updated:

1. Update files under this folder
2. Re-run `install-into-dbeaver.sh` against your DBeaver checkout
3. Re-run the aggregate `verify` command above
