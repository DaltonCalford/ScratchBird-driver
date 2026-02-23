#!/usr/bin/env bash

set -euo pipefail
SMOKE_BINARY="${ODBC_009_SMOKE_BINARY:-${1:-}}"

if [[ -z "${SMOKE_BINARY}" || ! -x "${SMOKE_BINARY}" ]]; then
  echo "ERROR: ODBC BI smoke command requires an executable binary in ODBC_009_SMOKE_BINARY."
  exit 1
fi

echo "ODBC BI smoke: running subset against ${SMOKE_BINARY}"
"${SMOKE_BINARY}" \
  --gtest_filter="OdbcSmokeTest.*:OdbcCapabilityBrowseTest.BrowseConnectTraversesCatalogSchemaTableColumns:OdbcCatalogTest.TablesHonorsPatterns" \
  --gtest_color=no
