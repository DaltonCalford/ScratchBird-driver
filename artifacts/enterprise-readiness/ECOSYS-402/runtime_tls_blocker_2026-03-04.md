# ECOSYS-402 Runtime TLS Blocker (2026-03-04)

## Attempt
Executed a live SQLAlchemy runtime smoke in a temporary virtualenv with:

- local Python driver package (`tracks/alpha/drivers/python`)
- local SQLAlchemy dialect package (`tracks/alpha/integrations/scratchbird-sqlalchemy-dialect`)
- `sqlalchemy` from PyPI

Connection URL attempted:

- `scratchbird://sb_admin:SbAdmin_Compat1!@127.0.0.1:13092/main?sslmode=require&binaryTransfer=true`

## Result
Runtime connection failed with TLS handshake error:

- `OperationalError: TLS handshake failed: [SSL: WRONG_VERSION_NUMBER]`

## Inference
The currently reachable local endpoint in this shell behaves as a non-TLS endpoint,
while the Python driver policy enforces TLS (`sslmode=disable` is rejected).

## Impact
- Deterministic ECOSYS-402 validation remains green.
- Live SQLAlchemy runtime matrix remains blocked in this shell until a TLS-capable
  ScratchBird endpoint is provided.

## Next step
Re-run runtime smoke and ORM/session matrix once a TLS-enabled DSN endpoint is available.
