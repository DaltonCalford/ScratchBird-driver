#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PY_DRIVER_DIR="${ROOT_DIR}/tracks/alpha/drivers/python"
DIALECT_DIR="${ROOT_DIR}/tracks/alpha/integrations/scratchbird-sqlalchemy-dialect"
LOG_FILE="${SCRIPT_DIR}/verification_sqlalchemy_runtime_probe.log"
LATEST_LOG="${SCRIPT_DIR}/latest_runtime_probe.log"
VENV_DIR="${SCRATCHBIRD_SQLALCHEMY_PROBE_VENV:-/tmp/sb_ecosys402_probe_venv}"
RUNTIME_DSN="${SCRATCHBIRD_SQLALCHEMY_URL:-scratchbird://sb_admin:SbAdmin_Compat1!@127.0.0.1:13092/main?sslmode=require&binaryTransfer=true}"

exec > >(tee "${LOG_FILE}") 2>&1

echo "ECOSYS-402 SQLAlchemy runtime probe"
echo "root: ${ROOT_DIR}"
echo "python driver: ${PY_DRIVER_DIR}"
echo "dialect: ${DIALECT_DIR}"
echo "venv: ${VENV_DIR}"
echo

if ! command -v python3 >/dev/null 2>&1; then
  echo "[fail] python3 runtime not available"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

python3 -m venv "${VENV_DIR}"
source "${VENV_DIR}/bin/activate"
python -m pip install --quiet --upgrade pip
python -m pip install --quiet sqlalchemy
python -m pip install --quiet -e "${PY_DRIVER_DIR}"
python -m pip install --quiet -e "${DIALECT_DIR}"

echo "[step] live connect + SELECT 1"
set +e
python - <<PY
from sqlalchemy import create_engine, text
engine = create_engine(${RUNTIME_DSN@Q})
with engine.connect() as conn:
    value = conn.execute(text("SELECT 1")).scalar_one()
print(f"runtime_sqlalchemy_select_one={value}")
PY
STATUS=$?
set -e

if [[ ${STATUS} -eq 0 ]]; then
  echo "[pass] SQLAlchemy runtime probe succeeded"
else
  echo "[blocked] SQLAlchemy runtime probe failed (likely TLS endpoint mismatch or runtime DSN mismatch)"
fi

cp "${LOG_FILE}" "${LATEST_LOG}"
exit ${STATUS}
