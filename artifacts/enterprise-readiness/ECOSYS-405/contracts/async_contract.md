# ECOSYS-405 Async Contract

## Scope
Normalize cancellation + timeout behavior between Go (`context`) and Python (`asyncio` integration around blocking DB-API calls).

## Shared invariants
- Cancel path uses SBWP `CANCEL` with urgent flag, not socket-close emulation.
- Timeout/cancel returns promptly and does not hang reader loops.
- Connection remains reusable after cancel/timeout unless server explicitly closes it.
- Timeout/read failures surface deterministic operational errors (`08006` class behavior).

## Go contract
- `ExecContext` / `QueryContext` honor `context` deadlines.
- Driver sends urgent `CANCEL` when context is cancelled while waiting for ready.
- Query payload deadline is propagated via timeout field when context has deadline.

## Python contract
- `connection.cancel()` sends SBWP urgent `CANCEL`.
- Read/connect timeouts map to `OperationalError` with deterministic `08001` / `08006` class behavior in error text.
- `asyncio` usage pattern is standardized as:
  - run blocking query in task/thread boundary
  - on task timeout/cancel, call `connection.cancel()`
  - propagate `OperationalError`/`CancelledError` to caller

## Interop examples
### Go
```go
ctx, cancel := context.WithTimeout(context.Background(), 250*time.Millisecond)
defer cancel()
_, err := db.ExecContext(ctx, cancelSQL)
```

### Python
```python
task = asyncio.create_task(asyncio.to_thread(run_query))
try:
    await asyncio.wait_for(task, timeout=0.25)
except (asyncio.TimeoutError, asyncio.CancelledError):
    conn.cancel()
    raise
```

## Verification matrix
- Go deterministic contract tests:
  - context cancel triggers urgent cancel message
  - row-stream cancel watcher triggers urgent cancel message
  - context deadline encoded into query timeout field
- Python deterministic contract tests:
  - `cancel()` sends urgent cancel message
  - `_read_exact` maps socket timeout/read failure to `OperationalError` (`08006`)
  - `_connect` maps connect timeout/failure to `OperationalError` (`08001`)
- Optional runtime integration (when DSNs are available):
  - Go integration cancel test
  - Python integration cancel test
