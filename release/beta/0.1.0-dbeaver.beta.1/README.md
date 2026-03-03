# ScratchBird DBeaver Beta Package (0.1.0-dbeaver.beta.1)

Status: **beta** (automation-built, **no human QA sign-off yet**).

Built from:

- Repository: ScratchBird-driver
- Commit: a2f83fbf0fda947ce6f24dfd37b939d6024fe379
- Build timestamp (UTC): 2026-03-03T03:31:55Z

Artifacts:

- dbeaver/scratchbird-dbeaver-update-site-1.0.1-beta.1.zip
  - Install in DBeaver CE/EE with:
    - Help -> Install New Software... -> Add... -> Archive...
- dbeaver/org.jkiss.dbeaver.ext.scratchbird.repository-1.0.1-SNAPSHOT.zip
  - Raw Tycho repository archive (same plugin contents, alternate package form)
- jdbc/scratchbird-jdbc-0.1.0.jar
- jdbc/scratchbird-jdbc-0.1.0-sources.jar

JDBC property compatibility note:

- metadataExpandSchemaParents=true enables parent schema segment expansion in DatabaseMetaData.getSchemas() for recursive schema tools.

Install summary for stock DBeaver downloads:

1. Install scratchbird-dbeaver-update-site-1.0.1-beta.1.zip via Help -> Install New Software....
2. Restart DBeaver.
3. Open Database -> Driver Manager -> ScratchBird -> Libraries.
4. Add local file jdbc/scratchbird-jdbc-0.1.0.jar (or your own published JDBC artifact).
5. Optional: set connection property metadataExpandSchemaParents=true.

Checksums:

- SHA256SUMS.txt

Source instructions:

- tracks/alpha/integrations/scratchbird-dbeaver-driver/README.md
