#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_DIR="${ODBC_008_BUILD_DIR:-$REPO_ROOT/tracks/alpha/drivers/odbc/build_odbc_gate}"
TEST_BINARY="${ODBC_008_TEST_BINARY:-$BUILD_DIR/scratchbird_odbc_tests}"

EXPECTED_FUNCTION_MATRIX="${ODBC_008_EXPECTED_FUNCTION_MATRIX_PATH:-$SCRIPT_DIR/odbc_function_matrix.csv}"
EXPECTED_INFO_MATRIX="${ODBC_008_EXPECTED_INFO_MATRIX_PATH:-$SCRIPT_DIR/odbc_info_matrix.csv}"
EXPORTED_FUNCTION_MATRIX="${ODBC_008_CAPABILITY_MATRIX_PATH:-$SCRIPT_DIR/latest_function_matrix_export.csv}"

if [[ ! -x "$TEST_BINARY" ]]; then
  cmake -S "$REPO_ROOT/tracks/alpha/drivers/odbc" -B "$BUILD_DIR" -DBUILD_TESTING=ON -DODBC_FETCH_GTEST=ON
  cmake --build "$BUILD_DIR" --target scratchbird_odbc_tests scratchbird_odbc -j 4
fi

if [[ ! -x "$TEST_BINARY" && -x "$BUILD_DIR/tracks/alpha/drivers/odbc/scratchbird_odbc_tests" ]]; then
  TEST_BINARY="$BUILD_DIR/tracks/alpha/drivers/odbc/scratchbird_odbc_tests"
fi

if [[ ! -x "$TEST_BINARY" ]]; then
  echo "ERROR: ODBC test binary not found."
  exit 1
fi

if [[ ! -f "$EXPECTED_FUNCTION_MATRIX" ]]; then
  echo "ERROR: Expected function matrix not found: $EXPECTED_FUNCTION_MATRIX"
  exit 1
fi
if [[ ! -f "$EXPECTED_INFO_MATRIX" ]]; then
  echo "ERROR: Expected info matrix not found: $EXPECTED_INFO_MATRIX"
  exit 1
fi

echo "Running ODBC capability matrix checks"
echo "  function matrix: $EXPECTED_FUNCTION_MATRIX"
echo "  info matrix:     $EXPECTED_INFO_MATRIX"
echo "  export matrix:   $EXPORTED_FUNCTION_MATRIX"

ODBC_008_EXPECTED_FUNCTION_MATRIX_PATH="$EXPECTED_FUNCTION_MATRIX" \
ODBC_008_EXPECTED_INFO_MATRIX_PATH="$EXPECTED_INFO_MATRIX" \
ODBC_008_CAPABILITY_MATRIX_PATH="$EXPORTED_FUNCTION_MATRIX" \
"$TEST_BINARY" \
  --gtest_color=no \
  --gtest_filter="OdbcCapabilityBrowseTest.GetFunctionsAdvertisesOnlyImplementedFunctions:OdbcCapabilityBrowseTest.GetFunctionsCanCompareAgainstExpectedCsvMatrix:OdbcCapabilityBrowseTest.GetInfoCanCompareAgainstExpectedCsvMatrix:OdbcCapabilityBrowseTest.DriverEntryGetFunctionsMatchesConnectionGetter:OdbcCapabilityBrowseTest.DriverEntryGetInfoMatchesConnectionGetter"
