# Tableau Connector Best-In-Class Research

Status: Current
Lane: `tableau`
Benchmark: `Tableau PostgreSQL / Named Connector SDK`

## Why This Benchmark

Tableau’s PostgreSQL experience and Named Connector SDK define the expectation
set for a serious Tableau integration. They anchor:

- live and extract connectivity behavior
- metadata discovery and relation browsing
- auth and capability declarations
- connector packaging and deployment

## Official Sources

- Tableau PostgreSQL connectivity docs:
  `https://help.tableau.com/current/pro/desktop/en-us/examples_postgresql.htm`
- Tableau Connector Plugin SDK:
  `https://tableau.github.io/connector-plugin-sdk/`
- Implementation anchor:
  `https://github.com/tableau/connector-plugin-sdk`

## Capability Families That Become Non-Optional

- connector and capability declaration behavior
- metadata discovery for schemas, tables, and columns
- auth and SSL/TLS configuration expected by Tableau users
- live query and extract-friendly behavior
- packaging as a Tableau connector artifact

## ScratchBird Implementation Implications

- the lane must specify when native Tableau connector packaging is required
  instead of relying only on generic PostgreSQL/ODBC connectivity
- relation naming, type mapping, and capability flags need explicit treatment
- operational setup guidance is part of the connector contract

## Later Server Validation Focus

- live connection bootstrap
- metadata discovery and browse behavior
- extract creation and refresh behavior
- Tableau connector packaging/install proof
