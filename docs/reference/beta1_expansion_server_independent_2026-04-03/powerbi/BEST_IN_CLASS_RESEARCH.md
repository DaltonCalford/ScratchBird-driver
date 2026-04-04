# Power BI Connector Best-In-Class Research

Status: Current
Lane: `powerbi`
Benchmark: `Power BI PostgreSQL / ODBC custom connector surface`

## Why This Benchmark

Power BI is a strategic BI entry point, and the benchmark is the combination of
the built-in PostgreSQL surface plus the Power Query custom connector model. It
defines the expectation set for:

- Power Query connection UX and credential handling
- metadata/type projection into the Power BI model
- query folding where feasible
- custom connector packaging and desktop deployment

## Official Sources

- Power Query PostgreSQL connector docs:
  `https://learn.microsoft.com/en-us/power-query/connectors/postgresql`
- Power Query SDK docs:
  `https://learn.microsoft.com/en-us/power-query/install-sdk`
- Implementation anchor:
  `https://github.com/microsoft/DataConnectors`

## Capability Families That Become Non-Optional

- Power Query connector bootstrap and credential flow
- type mapping suitable for model loading and refresh
- folding-friendly SQL generation where the host stack allows it
- packaging as a `.mez` custom connector when needed
- reliable diagnostics for desktop/service troubleshooting

## ScratchBird Implementation Implications

- generic ODBC connectivity is not enough if a better connector path is
  required for user experience or capability flags
- the lane must document what is delegated to ODBC and what must be implemented
  in a custom connector surface
- refresh behavior and credential storage expectations must be explicit

## Later Server Validation Focus

- desktop connector bootstrap and credential dialogs
- import/refresh correctness and representative type mapping
- folding behavior for common filter/project cases
- custom connector packaging and installation proof
