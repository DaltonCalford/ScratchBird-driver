#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BUILD_DIR="$REPO_ROOT/tracks/alpha/drivers/odbc/build_odbc_gate"
TEST_BINARY="$BUILD_DIR/scratchbird_odbc_tests"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_LOG="$SCRIPT_DIR/run_odbc_enterprise_gate.log"
LATEST_LOG="$SCRIPT_DIR/latest_verification.log"
BASELINE_FILE="$SCRIPT_DIR/perf_baseline.csv"
SNAPSHOT_FILE="$SCRIPT_DIR/latest_perf_snapshot.json"

TIMING_AVAILABLE=0
if command -v /usr/bin/time >/dev/null 2>&1; then
  TIME_BINARY="/usr/bin/time"
  TIMING_AVAILABLE=1
fi

elapsed_threshold="${ODBC_009_ELAPSED_REGRESSION_THRESHOLD:-2}"
rss_threshold="${ODBC_009_MAX_RSS_REGRESSION_THRESHOLD:-2}"
mandatory_bi_smoke="${ODBC_009_BI_SMOKE_MANDATORY:-0}"
bi_smoke_cmd="${ODBC_009_BI_SMOKE_CMD:-}"
default_bi_smoke_script="$SCRIPT_DIR/odbc_bi_smoke.sh"
if [[ -z "$bi_smoke_cmd" && -x "$default_bi_smoke_script" ]]; then
  bi_smoke_cmd="$default_bi_smoke_script"
fi

{
  echo "ODBC-009 gate run: $TS"
  echo "Repository: $REPO_ROOT"
  echo "Build directory: $BUILD_DIR"
  echo "Test binary: $TEST_BINARY"
  echo "Timing capture: $TIMING_AVAILABLE"

  if [[ ! -x "$TEST_BINARY" ]]; then
    echo "Test binary missing. Configuring and building ODBC test target..."
    cmake -S "$REPO_ROOT/tracks/alpha/drivers/odbc" -B "$BUILD_DIR" -DBUILD_TESTING=ON -DODBC_FETCH_GTEST=ON
    if cmake --build "$BUILD_DIR" --target scratchbird_odbc_tests scratchbird_odbc -j 4; then
      :
    else
      cmake --build "$BUILD_DIR" -j 4
    fi
  fi

  if [[ ! -x "$TEST_BINARY" && -x "${BUILD_DIR}/tracks/alpha/drivers/odbc/scratchbird_odbc_tests" ]]; then
    TEST_BINARY="${BUILD_DIR}/tracks/alpha/drivers/odbc/scratchbird_odbc_tests"
  fi

  if [[ ! -x "$TEST_BINARY" ]]; then
    echo "Test executable unavailable. Attempting CTest path."
    RUN_CMD=(ctest --test-dir "$BUILD_DIR" --output-on-failure)
  else
    RUN_CMD=("$TEST_BINARY")
    echo "Running ODBC gate executable: $TEST_BINARY"
  fi

  VERIFICATION_LOG="$SCRIPT_DIR/verification_${TS}.log"
  TIMING_LOG="$SCRIPT_DIR/odbc_gate_timing_${TS}.log"

  if (( TIMING_AVAILABLE == 1 )); then
    "${TIME_BINARY}" -f "PERF_ELAPSED_SECONDS=%e
PERF_CPU_USER_SECONDS=%U
PERF_CPU_SYSTEM_SECONDS=%S
PERF_MAX_RSS_KB=%M
PERF_VOLUNTARY_CONTEXT_SWITCHES=%w
PERF_INVOLUNTARY_CONTEXT_SWITCHES=%c" \
      "${RUN_CMD[@]}" 2> "$TIMING_LOG" | tee "$VERIFICATION_LOG"
  else
    echo "Timing capture not available; running without timing."
    "${RUN_CMD[@]}" | tee "$VERIFICATION_LOG"
    : > "$TIMING_LOG"
  fi

  if ! grep -q "PASSED" "$VERIFICATION_LOG"; then
    echo "ERROR: ODBC suite did not report a passed run."
    exit 1
  fi

  PERF_ELAPSED_SECONDS="$(awk -F= '/^PERF_ELAPSED_SECONDS=/{print $2}' "$TIMING_LOG" | tail -n 1)"
  PERF_CPU_USER_SECONDS="$(awk -F= '/^PERF_CPU_USER_SECONDS=/{print $2}' "$TIMING_LOG" | tail -n 1)"
  PERF_CPU_SYSTEM_SECONDS="$(awk -F= '/^PERF_CPU_SYSTEM_SECONDS=/{print $2}' "$TIMING_LOG" | tail -n 1)"
  PERF_MAX_RSS_KB="$(awk -F= '/^PERF_MAX_RSS_KB=/{print $2}' "$TIMING_LOG" | tail -n 1)"
  PERF_VOLUNTARY_CONTEXT_SWITCHES="$(awk -F= '/^PERF_VOLUNTARY_CONTEXT_SWITCHES=/{print $2}' "$TIMING_LOG" | tail -n 1)"
  PERF_INVOLUNTARY_CONTEXT_SWITCHES="$(awk -F= '/^PERF_INVOLUNTARY_CONTEXT_SWITCHES=/{print $2}' "$TIMING_LOG" | tail -n 1)"

  PERF_ELAPSED_SECONDS="${PERF_ELAPSED_SECONDS:-0}"
  PERF_CPU_USER_SECONDS="${PERF_CPU_USER_SECONDS:-0}"
  PERF_CPU_SYSTEM_SECONDS="${PERF_CPU_SYSTEM_SECONDS:-0}"
  PERF_MAX_RSS_KB="${PERF_MAX_RSS_KB:-0}"
  PERF_VOLUNTARY_CONTEXT_SWITCHES="${PERF_VOLUNTARY_CONTEXT_SWITCHES:-0}"
  PERF_INVOLUNTARY_CONTEXT_SWITCHES="${PERF_INVOLUNTARY_CONTEXT_SWITCHES:-0}"

  echo "ODBC gate perf snapshot: elapsed_seconds=$PERF_ELAPSED_SECONDS max_rss_kb=$PERF_MAX_RSS_KB"
  if (( TIMING_AVAILABLE == 1 )); then
    if [[ ! -f "$BASELINE_FILE" ]]; then
      echo "timestamp,elapsed_seconds,max_rss_kb,cpu_user_seconds,cpu_system_seconds,voluntary_ctxsw,involuntary_ctxsw,command" \
        > "$BASELINE_FILE"
    fi
    echo "$TS,$PERF_ELAPSED_SECONDS,$PERF_MAX_RSS_KB,$PERF_CPU_USER_SECONDS,$PERF_CPU_SYSTEM_SECONDS,$PERF_VOLUNTARY_CONTEXT_SWITCHES,$PERF_INVOLUNTARY_CONTEXT_SWITCHES,\"${RUN_CMD[*]}\"" \
      >> "$BASELINE_FILE"

    cat > "$SNAPSHOT_FILE" <<JSON
{
  "timestamp": "$TS",
  "command": "${RUN_CMD[*]}",
  "elapsed_seconds": "$PERF_ELAPSED_SECONDS",
  "max_rss_kb": "$PERF_MAX_RSS_KB",
  "cpu_user_seconds": "$PERF_CPU_USER_SECONDS",
  "cpu_system_seconds": "$PERF_CPU_SYSTEM_SECONDS",
  "voluntary_context_switches": "$PERF_VOLUNTARY_CONTEXT_SWITCHES",
  "involuntary_context_switches": "$PERF_INVOLUNTARY_CONTEXT_SWITCHES"
}
JSON

    if [[ $(wc -l < "$BASELINE_FILE") -ge 3 ]]; then
      python3 - "$BASELINE_FILE" "$TS" "$elapsed_threshold" "$rss_threshold" <<'PY'
import csv
import sys

path, current_ts = sys.argv[1], sys.argv[2]
elapsed_threshold = float(sys.argv[3])
rss_threshold = float(sys.argv[4])

with open(path, "r", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

if len(rows) < 2:
    print("Perf baseline exists, but no prior sample is available for regression comparison.")
    raise SystemExit(0)

current = rows[-1]
previous = rows[-2]

def to_float(v):
    try:
        return float(v)
    except (TypeError, ValueError):
        return 0.0

curr_elapsed = to_float(current["elapsed_seconds"])
curr_rss = to_float(current["max_rss_kb"])
prev_elapsed = to_float(previous["elapsed_seconds"])
prev_rss = to_float(previous["max_rss_kb"])

if prev_elapsed > 0 and curr_elapsed > (prev_elapsed * elapsed_threshold):
    print(
        f"FAIL: elapsed regression detected. current={curr_elapsed:.3f}s baseline={prev_elapsed:.3f}s "
        f"threshold={elapsed_threshold:.2f}x"
    )
    raise SystemExit(1)

if prev_rss > 0 and curr_rss > (prev_rss * rss_threshold):
    print(
        f"FAIL: max RSS regression detected. current={curr_rss:.0f}KB baseline={prev_rss:.0f}KB "
        f"threshold={rss_threshold:.2f}x"
    )
    raise SystemExit(1)

elapsed_ratio = curr_elapsed / prev_elapsed if prev_elapsed > 0 else 0.0
rss_ratio = curr_rss / prev_rss if prev_rss > 0 else 0.0
print(
    f"Perf trend check passed vs prior sample {previous['timestamp']} -> {current_ts}: "
    f"elapsed_ratio={elapsed_ratio:.2f}x rss_ratio={rss_ratio:.2f}x"
)
PY
    fi
  else
    echo "TIMING_CAPTURE_UNAVAILABLE; perf baseline checks skipped."
  fi

  if [[ ${#RUN_CMD[@]} -eq 1 ]]; then
    export ODBC_009_SMOKE_BINARY="${RUN_CMD[0]}"
  else
    unset ODBC_009_SMOKE_BINARY
  fi

  if [[ -n "$bi_smoke_cmd" ]]; then
    echo "Running BI smoke command: $bi_smoke_cmd"
    if ! eval "$bi_smoke_cmd"; then
      echo "ERROR: BI smoke command failed."
      exit 1
    fi
    echo "BI smoke command completed."
  else
    if [[ "$mandatory_bi_smoke" == "1" ]]; then
      echo "ERROR: BI smoke command is not configured but mandatory."
      echo "Set ODBC_009_BI_SMOKE_CMD to a connector-compatible smoke script."
      exit 1
    fi
    echo "BI smoke command not configured; running placeholder-only checks."
  fi

  echo "ODBC-009 gate checks passed."
  cp "$VERIFICATION_LOG" "$LATEST_LOG"
} | tee "$RUN_LOG"
