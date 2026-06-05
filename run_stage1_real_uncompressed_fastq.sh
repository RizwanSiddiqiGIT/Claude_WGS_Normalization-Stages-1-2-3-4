#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

RAW_R1_UNCOMPRESSED="/mnt/d/DNA/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq"
RAW_R2_UNCOMPRESSED="/mnt/d/DNA/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq"

mkdir -p "${LOGS_DIR}" "${BASE_DIR}"

RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG="${LOGS_DIR}/stage1_real_uncompressed_${RUN_ID}.log"
PID_FILE="${LOGS_DIR}/stage1_real.pid"
LATEST_LOG="${LOGS_DIR}/stage1_real_latest.log"

{
  echo "$$" > "${PID_FILE}"
  ln -sfn "${LOG}" "${LATEST_LOG}"
  echo "======================================================================"
  echo " STAGE 1 REAL RUN LAUNCHER - UNCOMPRESSED FASTQ"
  echo " Launcher PID: $$"
  echo " Log: ${LOG}"
  echo " Started: $(date)"
  echo " Raw R1: ${RAW_R1_UNCOMPRESSED}"
  echo " Raw R2: ${RAW_R2_UNCOMPRESSED}"
  echo "======================================================================"
  RAW_FASTQ_R1="${RAW_R1_UNCOMPRESSED}" \
  RAW_FASTQ_R2="${RAW_R2_UNCOMPRESSED}" \
  ASSUME_RAW_FASTQ_VALID=1 \
  STAGE1_RUN_ID="${RUN_ID}" \
  ./stage1_qc_preprocess.sh
  echo "======================================================================"
  echo " STAGE 1 REAL RUN FINISHED"
  echo " Finished: $(date)"
  echo "======================================================================"
} >> "${LOG}" 2>&1
