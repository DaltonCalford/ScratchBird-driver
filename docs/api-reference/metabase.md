# Metabase Plugin API Reference

The Metabase driver is a thin adapter on top of the ScratchBird JDBC driver.
It exposes ScratchBird as a Metabase database type and provides metadata
queries required by Metabase.

## Driver Namespace

- `metabase.driver.scratchbird`

## Key Behaviors

- Connection details normalize to JDBC properties, including optional
  `currentSchema`, manager-proxy ingress (`front_door_mode`,
  `manager_auth_token`), and the full JDBC `sslmode` set.
- If no `currentSchema` is supplied, the adapter leaves schema resolution to
  the server-side user/role/group policy, which falls back to `users.public`.
- Capabilities are gated via `driver/database-supports?` and now match the
  supported JDBC metadata/index surface explicitly.
- Metadata uses the SQL JDBC sync utilities.

See `tracks/alpha/integrations/scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj` for the
full adapter behavior.
