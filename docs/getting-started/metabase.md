# Metabase Plugin Driver

This driver integrates ScratchBird into Metabase using the ScratchBird JDBC driver.

## Build

From `tracks/alpha/integrations/scratchbird-metabase-driver/`:

```bash
clj -T:build jar
```

## Install in Metabase

1. Copy the JAR to `MB_PLUGINS_DIR`.
2. Restart Metabase.
3. Add a new database using the ScratchBird driver.

## Notes

- The plugin bundles `metabase-plugin.yaml` and the driver namespace.
- JDBC URL format: `jdbc:scratchbird://host:3092/database`.

See `tracks/alpha/integrations/scratchbird-metabase-driver/README.md` for the scaffold details.
