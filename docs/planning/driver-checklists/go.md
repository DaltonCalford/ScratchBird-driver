# Go Driver Checklist

Note: Integration priorities map to checklist buckets as follows: P0 → P1 (Core), P1 → P2 (Follow-ups), P2 → P3 (Future).

## P1 (Core)

### Integration Appendix Tasks

- [x] Constraint: QueryRow errors are deferred to Scan; no rows returns ErrNoRows. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Context-aware methods required for cancellation. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Verify ErrNoRows behavior. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate context cancellation. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
## P2 (Follow-ups)
- [x] Add conformance tests for full type matrix in `tracks/alpha/drivers/go/conformance/`. Issue: DONE (2026-02-04)

## P3 (Future)

### Integration Appendix Tasks

- [x] Constraint: Mattermost uses PostgreSQL for production deployments. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: DB connection config is in `config.json` with DSN-like fields. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Constraint: Online migrations are common during upgrades. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Validate Mattermost startup migrations complete. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
- [x] Test: Confirm message, channel, and user CRUD flows. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`) Status: DEFERRED (2026-02-04)
