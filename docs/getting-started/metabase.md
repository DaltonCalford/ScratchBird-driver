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
- Manager-proxy ingress is available through JDBC URL parameters such as
  `front_door_mode=manager_proxy&manager_auth_token=token`, and the driver now
  surfaces those fields directly in the Metabase connection UI as well.
- The plugin inherits current JDBC connection properties, including the
  standard `sslmode` values, optional `currentSchema`, and auth-plugin startup
  keys.
- If `currentSchema` is omitted, ScratchBird resolves the session schema from
  the server-side user/role/group default chain and falls back to `users.public`.

See `tracks/alpha/integrations/scratchbird-metabase-driver/README.md` for the scaffold details.
