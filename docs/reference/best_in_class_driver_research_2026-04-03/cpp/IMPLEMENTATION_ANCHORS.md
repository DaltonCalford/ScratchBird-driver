# C/C++ driver Implementation Anchors

Date: 2026-04-03
Lane: `cpp`
Selected benchmark: `libpqxx`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `libpqxx docs`: https://libpqxx.readthedocs.io/stable/
- `libpqxx repo`: https://github.com/jtv/libpqxx (`refs/heads/master 0314658cdc693d9d223490aecf0932b81854d13e`)
- `SOCI repo`: https://github.com/SOCI/soci (`refs/heads/master 897dac8f9cb327eb24827731e569fadd32ae53d4`)
- `nanodbc docs`: https://nanodbc.github.io/nanodbc/

## Primary Competitive Closure Areas

- Add benchmark-backed performance and memory-footprint evidence comparable to libpqxx’s
mature deployment posture.
- Tighten diagnostic and tracing documentation so operational debugging is as easy as the
incumbent C++ stack.
- Expand package/distribution guidance for Linux, Windows, and ABI-safe consumption.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
