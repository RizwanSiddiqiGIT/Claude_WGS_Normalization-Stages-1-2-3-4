#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

mkdir -p "${LOGS_DIR}" "${BASE_DIR}"

RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG="${LOGS_DIR}/stage1_real_${RUN_ID}.log"
PID_FILE="${LOGS_DIR}/stage1_real.pid"
LATEST_LOG="${LOGS_DIR}/stage1_real_latest.log"

{
  echo "$$" > "${PID_FILE}"
  ln -sfn "${LOG}" "${LATEST_LOG}"
  echo "======================================================================"
  echo " STAGE 1 REAL RUN LAUNCHER"
  echo " Launcher PID: $$"
  echo " Log: ${LOG}"
  echo " Started: $(date)"
  echo "======================================================================"
  STAGE1_RUN_ID="${RUN_ID}" ./stage1_qc_preprocess.sh
  echo "======================================================================"
  echo " STAGE 1 REAL RUN FINISHED"
  echo " Finished: $(date)"
  echo "======================================================================"
} >> "${LOG}" 2>&1
