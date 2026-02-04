# Go Driver Checklist

## P1 (Core)

- [x] Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `go/errors.go`. Issue: TBD

### Integration Appendix Tasks

- [ ] Constraint: QueryRow errors are deferred to Scan; no rows returns ErrNoRows. (Source: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)
- [ ] Constraint: Context-aware methods required for cancellation. (Source: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)
- [ ] Test: Verify ErrNoRows behavior. (Source: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)
- [ ] Test: Validate context cancellation. (Source: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)
- [ ] Constraint: Mattermost uses PostgreSQL for production deployments. (Source: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)
- [ ] Constraint: DB connection config is in `config.json` with DSN-like fields. (Source: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)
- [ ] Constraint: Online migrations are common during upgrades. (Source: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)
- [ ] Test: Validate Mattermost startup migrations complete. (Source: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)
- [ ] Test: Confirm message, channel, and user CRUD flows. (Source: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)


## P2 (Follow-ups)

- [ ] Add conformance tests for full type matrix in `go/conformance/`. Issue: TBD
