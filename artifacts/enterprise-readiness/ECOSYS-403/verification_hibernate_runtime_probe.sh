#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
LOG_FILE="${SCRIPT_DIR}/verification_hibernate_runtime_probe.log"
LATEST_LOG="${SCRIPT_DIR}/latest_runtime_probe.log"
TMP_DIR="$(mktemp -d)"
RUNTIME_URL="${SCRATCHBIRD_JDBC_RUNTIME_URL:-jdbc:scratchbird://127.0.0.1:13092/main?sslmode=disable&allow_insecure=true}"
RUNTIME_USER="${SCRATCHBIRD_JDBC_RUNTIME_USER:-sb_admin}"
RUNTIME_PASSWORD="${SCRATCHBIRD_JDBC_RUNTIME_PASSWORD:-SbAdmin_Compat1!}"
EXTRA_CP="${SCRATCHBIRD_JDBC_PROBE_CLASSPATH:-}"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

exec > >(tee "${LOG_FILE}") 2>&1

echo "ECOSYS-403 Hibernate/JDBC runtime probe"
echo "root: ${ROOT_DIR}"
echo "runtime_url: ${RUNTIME_URL}"
echo

if ! command -v javac >/dev/null 2>&1 || ! command -v java >/dev/null 2>&1; then
  echo "[fail] java/javac runtime not available"
  cp "${LOG_FILE}" "${LATEST_LOG}"
  exit 1
fi

cat > "${TMP_DIR}/ScratchBirdJdbcProbe.java" <<'JAVA'
import java.sql.Connection;
import java.sql.DriverManager;

public final class ScratchBirdJdbcProbe {
    public static void main(String[] args) throws Exception {
        String url = args[0];
        String user = args[1];
        String password = args[2];
        try (Connection connection = DriverManager.getConnection(url, user, password)) {
            System.out.println("jdbc_runtime_probe_connected=true");
        }
    }
}
JAVA

javac "${TMP_DIR}/ScratchBirdJdbcProbe.java"

CP="${TMP_DIR}"
if [[ -n "${EXTRA_CP}" ]]; then
  CP="${CP}:${EXTRA_CP}"
fi

echo "[step] DriverManager runtime probe"
set +e
java -cp "${CP}" ScratchBirdJdbcProbe "${RUNTIME_URL}" "${RUNTIME_USER}" "${RUNTIME_PASSWORD}"
STATUS=$?
set -e

if [[ ${STATUS} -eq 0 ]]; then
  echo "[pass] JDBC runtime probe succeeded"
else
  echo "[blocked] JDBC runtime probe failed (likely missing ScratchBird JDBC driver on classpath or runtime endpoint mismatch)"
  if [[ -z "${EXTRA_CP}" ]]; then
    echo "[hint] set SCRATCHBIRD_JDBC_PROBE_CLASSPATH to include the built ScratchBird JDBC driver jar"
  fi
fi

cp "${LOG_FILE}" "${LATEST_LOG}"
exit ${STATUS}
