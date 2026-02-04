# Metabase Plugin API Reference

The Metabase driver is a thin adapter on top of the ScratchBird JDBC driver.
It exposes ScratchBird as a Metabase database type and provides metadata
queries required by Metabase.

## Driver Namespace

- `metabase.driver.scratchbird`

## Key Behaviors

- Connection details normalize to JDBC properties.
- Capabilities are gated via `driver/database-supports?`.
- Metadata uses the SQL JDBC sync utilities.

See `tracks/alpha/integrations/scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj` for the
full adapter behavior.
