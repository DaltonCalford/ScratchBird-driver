# Pascal/Delphi driver Implementation Anchors

Date: 2026-04-03
Lane: `pascal`
Selected benchmark: `FireDAC`

## ScratchBird Current Truth Inputs

Current truth sources: BASELINE_REQUIREMENT_MAPPING.md; README.md;
docs/specifications/drivers/language/pascal-delphi/SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `FireDAC docs`: https://docwiki.embarcadero.com/RADStudio/Alexandria/en/Connect_to_PostgreSQL_(FireDAC)
- `ZeosLib mirror`: https://github.com/frones/ZeosLib
- `FreePascal FCL docs`: https://docs.freepascal.org/docs-html/fcl/

## Primary Competitive Closure Areas

- Raise packaging, IDE, and operational guidance to the standard expected by Delphi
developers.
- Add richer dataset- and component-oriented examples and validation.
- Publish performance and release evidence to support commercial-grade evaluation.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
