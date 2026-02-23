#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_DIR="$REPO_ROOT/tracks/alpha/drivers/odbc/build_odbc_gate"
TEST_BINARY="$BUILD_DIR/scratchbird_odbc_tests"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_LOG="$SCRIPT_DIR/run_odbc_enterprise_gate.log"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"

{
  echo "ODBC-009 gate run: $TS"
  echo "Repository: $REPO_ROOT"
  echo "Build directory: $BUILD_DIR"
  echo "Test binary: $TEST_BINARY"

  if [[ ! -x "$TEST_BINARY" ]]; then
    echo "Test binary missing. Configuring and building ODBC test target..."
    cmake -S "$REPO_ROOT/tracks/alpha/drivers/odbc" -B "$BUILD_DIR" -DBUILD_TESTING=ON -DODBC_FETCH_GTEST=ON
    if cmake --build "$BUILD_DIR" --target scratchbird_odbc_tests scratchbird_odbc -j 4; then
      :
    else
      cmake --build "$BUILD_DIR" -j 4
    fi
  fi

  if [[ ! -x "$TEST_BINARY" ]]; then
    echo "ERROR: Test binary still missing after build."
    exit 1
  fi

  if [[ ! -x "$TEST_BINARY" && -x "${BUILD_DIR}/tracks/alpha/drivers/odbc/scratchbird_odbc_tests" ]]; then
    TEST_BINARY="${BUILD_DIR}/tracks/alpha/drivers/odbc/scratchbird_odbc_tests"
  fi

  if [[ -x "$TEST_BINARY" ]]; then
    echo "Running ODBC gate executable: $TEST_BINARY"
    "$TEST_BINARY" | tee "$SCRIPT_DIR/verification_${TS}.log"
  else
    echo "Test executable unavailable; attempting CTest path."
    ctest --test-dir "$BUILD_DIR" --output-on-failure > "$SCRIPT_DIR/verification_${TS}.log"
  fi

  if ! grep -q "PASSED" "$SCRIPT_DIR/verification_${TS}.log"; then
    echo "ERROR: ODBC suite did not report a passed run."
    exit 1
  fi

  echo "ODBC-009 gate checks passed."
  cp "$SCRIPT_DIR/verification_${TS}.log" "$LATEST_LOG"
} | tee "$RUN_LOG"
