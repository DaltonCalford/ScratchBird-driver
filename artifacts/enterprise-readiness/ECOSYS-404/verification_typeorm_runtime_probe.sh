#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PACKAGE_DIR="${ROOT_DIR}/tracks/alpha/integrations/scratchbird-typeorm-adapter"
LOG_FILE="${SCRIPT_DIR}/verification_typeorm_runtime_probe.log"
LATEST_LOG="${SCRIPT_DIR}/latest_runtime_probe.log"

exec > >(tee "${LOG_FILE}") 2>&1

echo "ECOSYS-404 TypeORM runtime probe"
echo "root: ${ROOT_DIR}"
echo "package: ${PACKAGE_DIR}"
echo

if ! command -v node >/dev/null 2>&1; then
  echo "[fail] node runtime not available"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
  echo "[fail] npm runtime not available"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

if [[ ! -d "${PACKAGE_DIR}" ]]; then
  echo "[fail] TypeORM adapter package not found"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

echo "[step] install temporary TypeORM package for probe"
(
  cd "${PACKAGE_DIR}"
  npm install --silent --no-save typeorm@0.3.20
)

echo "[step] runtime datasource initialization probe"
set +e
(
  cd "${PACKAGE_DIR}"
  node -e "const {DataSource}=require('typeorm'); const ds=new DataSource({type:'scratchbird',host:'127.0.0.1',port:13092,username:'sb_admin',password:'x',database:'main'}); ds.initialize().then(()=>{console.log('typeorm-runtime-ok'); return ds.destroy();}).catch(e=>{console.error(String(e && (e.stack || e.message) || e)); process.exit(1);});"
)
STATUS=$?
set -e

if [[ ${STATUS} -eq 0 ]]; then
  echo "[pass] TypeORM runtime probe succeeded"
else
  echo "[blocked] TypeORM runtime probe failed (driver type not recognized by TypeORM runtime)"
fi

cp "${LOG_FILE}" "${LATEST_LOG}"
exit ${STATUS}
