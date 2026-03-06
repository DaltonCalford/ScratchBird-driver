#!/usr/bin/env bash

set -euo pipefail

SMOKE_BINARY="${ODBC_009_SMOKE_BINARY:-${1:-}}"

if [[ -z "${SMOKE_BINARY}" || ! -x "${SMOKE_BINARY}" ]]; then
  echo "ERROR: hosted BI smoke requires an executable binary in ODBC_009_SMOKE_BINARY."
  exit 1
fi

if [[ -z "${SCRATCHBIRD_ODBC_TABLEAU_CONNSTR:-}" && \
      -z "${SCRATCHBIRD_ODBC_POWERBI_CONNSTR:-}" && \
      -z "${SCRATCHBIRD_ODBC_EXCEL_CONNSTR:-}" ]]; then
  echo "ERROR: hosted BI smoke requires at least one vendor connection string:"
  echo "  SCRATCHBIRD_ODBC_TABLEAU_CONNSTR"
  echo "  SCRATCHBIRD_ODBC_POWERBI_CONNSTR"
  echo "  SCRATCHBIRD_ODBC_EXCEL_CONNSTR"
  exit 1
fi

echo "ODBC hosted BI smoke: running vendor metadata probes"
"${SMOKE_BINARY}" \
  --gtest_filter="OdbcExternalRuntimeTest.HostedTableauMetadataSmoke:OdbcExternalRuntimeTest.HostedPowerBiMetadataSmoke:OdbcExternalRuntimeTest.HostedExcelMetadataSmoke" \
  --gtest_color=no
