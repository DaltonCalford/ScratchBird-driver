# Go Driver Checklist

## P1 (Core)

### Integration Appendix Tasks

- [ ] Constraint: QueryRow errors are deferred to Scan; no rows returns ErrNoRows. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)
- [ ] Constraint: Context-aware methods required for cancellation. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)
- [ ] Test: Verify ErrNoRows behavior. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)
- [ ] Test: Validate context cancellation. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)
- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `go/errors.go`. Issue: TBD


## P2 (Follow-ups)
- [ ] Add conformance tests for full type matrix in `go/conformance/`. Issue: TBD

## P3 (Future)

### Integration Appendix Tasks

- [ ] Constraint: Mattermost uses PostgreSQL for production deployments. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)
- [ ] Constraint: DB connection config is in `config.json` with DSN-like fields. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)
- [ ] Constraint: Online migrations are common during upgrades. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)
- [ ] Test: Validate Mattermost startup migrations complete. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)
- [ ] Test: Confirm message, channel, and user CRUD flows. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)
