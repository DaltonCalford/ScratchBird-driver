# Secret Integration Patterns

## Pattern 1 — Kubernetes Secret and Mounted Volume
Use `secret.yaml` and `deployment.yaml` for projected credentials that mount as files.
Driver DSN or connection properties should reference:

- `/var/run/secrets/scratchbird/username`
- `/var/run/secrets/scratchbird/password`
- optional `/var/run/secrets/scratchbird/manager_auth_token`

This pattern supports:
- short-lived token rotation by patching and replacing secrets.
- pod restart or sidecar volume updates to consume new values.

## Pattern 2 — Environment Variable Injection
Set `SCRATCHBIRD_USERNAME`, `SCRATCHBIRD_PASSWORD` and optional
`SCRATCHBIRD_MANAGER_TOKEN` from a secret-backed environment.

Use this for local tooling and CI when file watches are unavailable.

## Pattern 3 — External File Secret (non-Kubernetes)
Store a credentials file outside source control with strict permissions (`0600`) and
read it at startup.

Recommended for:
- bare-metal and container systems without secret managers.
- short-lived bootstrap flows.

## Secret Contract (Minimum)
- Connection credentials must fail fast when any required secret field is missing.
- Secret values must never be logged at info/debug level.
- Secret rotation should update consumers before creating new pooled sessions.
