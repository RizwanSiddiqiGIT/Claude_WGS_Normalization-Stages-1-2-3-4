#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

BASE_DIR_DNA_LINUX="/home/rayzw/DNA-Linux/hg38"
RAW_R1="${BASE_DIR_DNA_LINUX}/raw_uncompressed/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq"
RAW_R2="${BASE_DIR_DNA_LINUX}/raw_uncompressed/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq"

LOGS_DIR_DNA_LINUX="${BASE_DIR_DNA_LINUX}/logs"
FASTQ_OUT_DIR="${BASE_DIR_DNA_LINUX}/fastq"
QC_OUT_DIR="${BASE_DIR_DNA_LINUX}/qc"
TMP_OUT_DIR="${BASE_DIR_DNA_LINUX}/tmp"

mkdir -p "${LOGS_DIR_DNA_LINUX}" "${FASTQ_OUT_DIR}" "${QC_OUT_DIR}" "${TMP_OUT_DIR}"

RUN_ID="$(date +%Y%m%d_%H%M%S)"
LOG="${LOGS_DIR_DNA_LINUX}/stage1_dna_linux_uncompressed_${RUN_ID}.log"
LATEST_LOG="${LOGS_DIR_DNA_LINUX}/stage1_dna_linux_latest.log"
PID_FILE="${LOGS_DIR_DNA_LINUX}/stage1_dna_linux.pid"

{
  echo "$$" > "${PID_FILE}"
  ln -sfn "${LOG}" "${LATEST_LOG}"
  echo "======================================================================"
  echo " STAGE 1 DNA-LINUX UNCOMPRESSED FASTQ LAUNCHER"
  echo " Launcher PID: $$"
  echo " Started: $(date)"
  echo " Log: ${LOG}"
  echo " Raw R1: ${RAW_R1}"
  echo " Raw R2: ${RAW_R2}"
  echo "======================================================================"
  test -r "${RAW_R1}"
  test -r "${RAW_R2}"
  if ! pgrep -f "progress_tracker.py.*stage1_dna_linux" >/dev/null 2>&1; then
    ./run_stage1_dna_linux_progress_tracker_foreground.sh &
    echo "Progress tracker PID: $!"
  else
    echo "Progress tracker already appears to be running."
  fi
  BASE_DIR="${BASE_DIR_DNA_LINUX}" \
  LOGS_DIR="${LOGS_DIR_DNA_LINUX}" \
  QC_DIR="${QC_OUT_DIR}" \
  TMP_DIR="${TMP_OUT_DIR}" \
  RAW_FASTQ_R1="${RAW_R1}" \
  RAW_FASTQ_R2="${RAW_R2}" \
  TRIMMED_FASTQ_R1="${FASTQ_OUT_DIR}/R1_trimmed.fastq.gz" \
  TRIMMED_FASTQ_R2="${FASTQ_OUT_DIR}/R2_trimmed.fastq.gz" \
  ASSUME_RAW_FASTQ_VALID=1 \
  STAGE1_RUN_ID="${RUN_ID}" \
  ./stage1_qc_preprocess.sh
  echo "======================================================================"
  echo " STAGE 1 DNA-LINUX UNCOMPRESSED FASTQ FINISHED"
  echo " Finished: $(date)"
  echo "======================================================================"
} >> "${LOG}" 2>&1
