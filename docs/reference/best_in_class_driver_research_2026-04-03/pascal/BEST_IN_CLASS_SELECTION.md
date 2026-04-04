# Pascal/Delphi driver Best-In-Class Selection

Date: 2026-04-03
Lane: `pascal`
Selected benchmark: `FireDAC`

## Selection Summary

FireDAC remains the strongest Pascal/Delphi benchmark because of its dataset
integration, IDE fit, and broad feature surface, while ZeosLib is the practical open-
source anchor for implementation comparison.

## Candidate Pool

`FireDAC`, `ZeosLib`, `FreePascal SQLDB`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FireDAC | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| ZeosLib | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| FreePascal SQLDB | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The lane is baseline complete, but the commercial FireDAC bar is still higher on
IDE/packaging polish. Competitive closure must use an open-source anchor where the commercial benchmark is not
inspectable.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | FireDAC docs | https://docwiki.embarcadero.com/RADStudio/Alexandria/en/Connect_to_PostgreSQL_(FireDAC) | downloaded |
| anchor_docs | ZeosLib mirror | https://github.com/frones/ZeosLib | downloaded |
| candidate_docs | FreePascal FCL docs | https://docs.freepascal.org/docs-html/fcl/ | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
