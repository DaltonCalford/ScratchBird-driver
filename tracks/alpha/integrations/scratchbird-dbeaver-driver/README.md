# ScratchBird DBeaver Integration

This folder stores ScratchBird-specific DBeaver integration assets inside
`ScratchBird-driver` so the DBeaver plugin and JDBC compatibility behavior are
versioned together.

Canonical findings, contract, and workplan artifacts for this adapter live in:

- `~/CliWork/local_work/docs/specifications/work/findings/SCRATCHBIRD_DBEAVER_ADAPTER_FINDINGS_2026-03-13.md`
- `~/CliWork/local_work/docs/specifications/work/planning/SCRATCHBIRD_DBEAVER_ADAPTER_CONTRACT_2026-03-13.md`
- `~/CliWork/local_work/docs/specifications/work/planning/SCRATCHBIRD_DBEAVER_ADAPTER_WORKPLAN_2026-03-13.md`

## Contents

- `plugins/org.jkiss.dbeaver.ext.scratchbird/`
  ScratchBird DBeaver extension plugin (recursive schema tree + Generic DDL folders)
- `features/org.jkiss.dbeaver.ext.scratchbird.feature/`
  p2 feature descriptor for the ScratchBird plugin
- `repository/`
  p2 update-site packaging (`category.xml`, repository module)
- `pom.xml`
  Standalone Tycho reactor for plugin/feature/repository build
- `scripts/build-p2-update-site.sh`
  Build and package a stock-installable p2 update-site zip
- `scripts/install-into-dbeaver.sh`
  Idempotent installer for a local DBeaver source checkout
- `test/org.jkiss.dbeaver.ext.scratchbird.test/`
  DBeaver-side integration tests for plugin metadata behavior

## JDBC Driver Improvements Included

The JDBC driver includes a metadata compatibility switch for recursive schema
clients:

- Property: `metadataExpandSchemaParents` (aliases:
  `metadata_expand_schema_parents`, `expandSchemaParents`,
  `dbeaver_expand_schema_parents`)
- Default: `false`
- Effect when `true`: `DatabaseMetaData.getSchemas()` emits dotted parent
  segments (for example `users`, `users.alice`, `users.alice.dev`), while
  preserving pattern filtering.

This keeps default metadata behavior unchanged for non-DBeaver clients.

## Install Into Stock DBeaver (No DBeaver Source Build)

These steps assume:

- ScratchBird driver repo: `~/CliWork/ScratchBird-driver`
- You are using a regular DBeaver binary download (not a source checkout)

### 1) Build ScratchBird JDBC JAR

```bash
cd ~/CliWork/ScratchBird-driver/tracks/p3/drivers/jdbc
./gradlew clean jar
```

JAR output:

- `~/CliWork/ScratchBird-driver/tracks/p3/drivers/jdbc/build/libs/scratchbird-jdbc-*.jar`

### 2) Build the p2 Update Site

```bash
cd ~/CliWork/ScratchBird-driver/tracks/alpha/integrations/scratchbird-dbeaver-driver
./scripts/build-p2-update-site.sh
```

Outputs:

- Repository folder:
  `~/CliWork/ScratchBird-driver/tracks/alpha/integrations/scratchbird-dbeaver-driver/repository/target/repository`
- Installable zip:
  `~/CliWork/ScratchBird-driver/tracks/alpha/integrations/scratchbird-dbeaver-driver/dist/scratchbird-dbeaver-update-site-*.zip`

### 3) Install Plugin in DBeaver UI

1. Open DBeaver
2. Go to `Help` -> `Install New Software...`
3. Click `Add...` -> `Archive...`
4. Select the generated zip from step 2
5. Choose `ScratchBird Extension`
6. Complete install and restart DBeaver

### 4) Point Driver to Local JDBC JAR

The plugin descriptor references `maven:/com.scratchbird:scratchbird-jdbc:RELEASE`.
If you are testing local builds, set the library manually:

1. Open `Database` -> `Driver Manager` -> `ScratchBird`
2. `Libraries` tab -> add local file
3. Select:
   `~/CliWork/ScratchBird-driver/tracks/p3/drivers/jdbc/build/libs/scratchbird-jdbc-*.jar`
4. Save and reconnect

### 5) Optional: Enable Parent Schema Expansion (JDBC Layer)

If you want parent schema rows emitted directly by JDBC metadata:

- Add connection property `metadataExpandSchemaParents=true`

Use this only when needed; default `false` keeps non-DBeaver metadata behavior
unchanged.

### Policy Note

If `Help` -> `Install New Software...` is disabled in your DBeaver install,
software install/update policies are being enforced by that environment.
In that case, use an unmanaged install or ask your administrator to allow
plugin installation.

## Install Into DBeaver Source Checkout (Developer Flow)

These steps assume:

- ScratchBird driver repo: `~/CliWork/ScratchBird-driver`
- DBeaver repo: `~/CliWork/dbeaver`
- DBeaver common repo: `~/CliWork/dbeaver-common`

### 1) Copy Plugin/Test Sources Into DBeaver Checkout

```bash
cd ~/CliWork/ScratchBird-driver/tracks/alpha/integrations/scratchbird-dbeaver-driver
./scripts/install-into-dbeaver.sh ~/CliWork/dbeaver
```

This copies plugin/test-plugin folders and patches:

- `~/CliWork/dbeaver/plugins/pom.xml`
- `~/CliWork/dbeaver/test/pom.xml`
- `~/CliWork/dbeaver/features/org.jkiss.dbeaver.db.feature/feature.xml`
- `~/CliWork/dbeaver/features/org.jkiss.dbeaver.test.feature/feature.xml`

The installer matches existing module/plugin IDs semantically, so reruns do not
duplicate lines if the target files already contain ScratchBird entries with
different whitespace formatting.

### 2) Build/Verify In DBeaver

```bash
cd ~/CliWork/dbeaver
~/CliWork/dbeaver-common/mvnw -f product/aggregate/pom.xml \
  -pl ../../../dbeaver-common/modules/org.jkiss.utils,../../../dbeaver-common/modules/com.dbeaver.jdbc.api,../../plugins/org.jkiss.dbeaver.model,../../plugins/org.jkiss.dbeaver.model.jdbc,../../plugins/org.jkiss.dbeaver.model.lsm,../../plugins/org.jkiss.dbeaver.model.sql,../../plugins/org.jkiss.dbeaver.model.sql.jdbc,../../plugins/org.jkiss.dbeaver.registry,../../plugins/org.jkiss.dbeaver.ext.generic,../../plugins/org.jkiss.dbeaver.ext.scratchbird,../../test/org.jkiss.dbeaver.ext.scratchbird.test \
  -am verify -DskipITs
```

Expected: `BUILD SUCCESS`.

## Update Workflow

When integration code changes:

1. Update files under this folder
2. Rebuild the p2 archive: `./scripts/build-p2-update-site.sh`
3. Reinstall/update in DBeaver via `Help` -> `Install New Software...`
4. Keep the local JDBC jar updated in Driver Manager when testing local builds
