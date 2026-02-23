# ECOSYS-405 Async Contract

## Python asyncio
- Cancellation should propagate through `Task.cancel()` paths.
- Connection/session objects must not leak when context is cancelled.
- Deadline-based wait should map to deterministic driver error code.

## Go context
- Context deadline/cancel should return promptly without hanging goroutines.
- Pool connections should return to pool on timeout/cancel.
- Retry paths must not reuse stale session state after cancel.

## Shared matrix
- Start query with short timeout then force cancel.
- Verify cleanup and no connection leak.
- Verify repeated deadline errors do not increase open descriptors.
