# Metabase Driver

The Metabase plugin integrates ScratchBird into Metabase using the ScratchBird JDBC driver.

## Build

From the `scratchbird-metabase-driver/` directory:

```bash
clj -T:build jar
```

This produces a plugin JAR with `metabase-plugin.yaml` embedded.

## Install

1. Copy the JAR to Metabase's plugin directory (`MB_PLUGINS_DIR`)
2. Restart Metabase
3. Add a new database using the ScratchBird driver

## Configuration

When adding a ScratchBird database in Metabase:

| Field | Value |
|-------|-------|
| Host | ScratchBird server hostname |
| Port | 3092 |
| Database | Database name |
| Username | Database user |
| Password | Database password |

## JDBC URL Format

The plugin uses the standard JDBC URL format:

```
jdbc:scratchbird://host:3092/database
```

## Requirements

- Metabase 0.45+ (or compatible version)
- ScratchBird server with SBWP v1.1
- TLS 1.3 enabled

## Plugin Contents

- `metabase-plugin.yaml` - Plugin manifest
- Driver namespace implementing Metabase driver interface
- Bundled ScratchBird JDBC driver

## Troubleshooting

### Connection Failed

- Verify ScratchBird server is running on port 3092
- Check TLS is enabled (required)
- Verify credentials

### Plugin Not Loading

- Check JAR is in `MB_PLUGINS_DIR`
- Check Metabase logs for plugin initialization errors
- Verify JAR contains `metabase-plugin.yaml`
