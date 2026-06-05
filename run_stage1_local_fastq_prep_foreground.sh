#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

mkdir -p "${LOGS_DIR}"

RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG="${LOGS_DIR}/stage1_local_fastq_prep_${RUN_ID}.log"
LATEST_LOG="${LOGS_DIR}/stage1_local_fastq_prep_latest.log"

ln -sfn "${LOG}" "${LATEST_LOG}"

{
  echo "======================================================================"
  echo " STAGE 1 LOCAL FASTQ PREP LAUNCHER"
  echo " Launcher PID: $$"
  echo " Log: ${LOG}"
  echo " Started: $(date)"
  echo "======================================================================"
  ./prepare_stage1_uncompressed_fastq_local.sh
  echo "======================================================================"
  echo " STAGE 1 LOCAL FASTQ PREP FINISHED"
  echo " Finished: $(date)"
  echo "======================================================================"
} >> "${LOG}" 2>&1
