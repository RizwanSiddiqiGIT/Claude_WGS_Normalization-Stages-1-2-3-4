#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

mkdir -p "${LOGS_DIR}" "${BASE_DIR}"

LOG="${LOGS_DIR}/stage2_real_$(date +%Y%m%d_%H%M%S).log"
PID_FILE="${LOGS_DIR}/stage2_real.pid"
LATEST_LOG="${LOGS_DIR}/stage2_real_latest.log"

{
  echo "$$" > "${PID_FILE}"
  ln -sfn "${LOG}" "${LATEST_LOG}"
  echo "======================================================================"
  echo " STAGE 2 REAL RUN LAUNCHER"
  echo " Launcher PID: $$"
  echo " Log: ${LOG}"
  echo " Started: $(date)"
  echo "======================================================================"
  ./stage2_align_markdup.sh
  echo "======================================================================"
  echo " STAGE 2 REAL RUN FINISHED"
  echo " Finished: $(date)"
  echo "======================================================================"
} >> "${LOG}" 2>&1
