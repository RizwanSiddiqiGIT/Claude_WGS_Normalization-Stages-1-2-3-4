#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

mkdir -p "${LOGS_DIR}" "${BASE_DIR}"

LOG="${LOGS_DIR}/stage2_real_$(date +%Y%m%d_%H%M%S).log"

: > "${LOG}"
setsid ./stage2_align_markdup.sh >> "${LOG}" 2>&1 < /dev/null &
PID="$!"

echo "PID=${PID}"
echo "LOG=${LOG}"
echo "PROCESSED_BAM=${PROCESSED_BAM}"
echo "DUP_METRICS=${DUP_METRICS}"
