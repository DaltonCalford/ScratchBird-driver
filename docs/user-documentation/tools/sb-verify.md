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

- Uses SBWP v1.1 and TLS 1.3.
- See the ScratchBird engine docs for verification modes and coverage.
