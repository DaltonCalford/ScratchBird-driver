#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="${DOTNET_HARNESS_MODE:-deterministic}"

echo "Running .NET soak/fault harness suite"
echo "mode: ${MODE}"
echo

bash "${SCRIPT_DIR}/DOTNET-101/verification_dotnet_soak.sh"
bash "${SCRIPT_DIR}/DOTNET-102/verification_dotnet_failover_soak.sh"
bash "${SCRIPT_DIR}/DOTNET-103/verification_dotnet_fault_matrix.sh"

echo
echo "[pass] .NET soak/fault harness suite completed"
