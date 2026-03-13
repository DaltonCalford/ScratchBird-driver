# Track Structure

This repository is organized by delivery track to keep the root clean and make
scope clear.

- `alpha` and `beta` remain in use for in-flight work and integrations.
- `p3` is the pre-release track for finished driver lanes that are ready to
  package, certify, and promote.
- Release state is tracked separately (current project release: Initial Early Beta `0.1.0`).

## Layout

- `tracks/alpha/drivers/` - in-flight driver implementations that have not yet moved to pre-release
- `tracks/alpha/integrations/` - P0/P1 integration projects
- `tracks/beta/drivers/` - in-flight secondary driver implementations that have not yet moved to pre-release
- `tracks/beta/integrations/` - P2 integration projects
- `tracks/p3/drivers/` - pre-release driver implementations
- `tracks/p3/integrations/` - P3 integration projects

Docs and specifications remain under `docs/` and refer to these paths.
