# sb_verify

Database verification CLI for ScratchBird.

## Status

Baseline implementation available; advanced checks depend on server support.

## Synopsis

```
sb_verify [OPTIONS] <command>
```

## Purpose

- Run integrity checks
- Inspect verification results
- Report issues for remediation

## Connection Options

```
sb_verify -H host -p 3092 -U admin -d scratchbird <command>
```

## Notes

- Connection behavior follows the current ScratchBird CLI lane build. Prefer
  TLS-enabled modes in production deployments.
- See the ScratchBird engine docs for verification modes and coverage.
