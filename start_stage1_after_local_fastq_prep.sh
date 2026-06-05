#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

TARGET_R1="/home/rayzw/DNA/hg38/raw_uncompressed/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq"
TARGET_R2="/home/rayzw/DNA/hg38/raw_uncompressed/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq"
LOG="${LOGS_DIR}/stage1_after_local_prep_handoff_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "${LOGS_DIR}"

{
  echo "======================================================================"
  echo " STAGE 1 AFTER LOCAL FASTQ PREP HANDOFF"
  echo " Started: $(date)"
  echo " Waiting for local prep process to finish."
  echo "======================================================================"

  while pgrep -f "prepare_stage1_uncompressed_fastq_local.sh" >/dev/null 2>&1; do
    sleep 60
    date
  done

  echo "Prep process is no longer running; checking expected local FASTQs."
  test -r "${TARGET_R1}"
  test -r "${TARGET_R2}"
  test ! -e "${TARGET_R1}.partial"
  test ! -e "${TARGET_R2}.partial"

  echo "Local FASTQs are present. Launching Stage 1."
  ./run_stage1_real_uncompressed_fastq_local.sh

  echo "======================================================================"
  echo " STAGE 1 AFTER LOCAL FASTQ PREP HANDOFF COMPLETE"
  echo " Finished: $(date)"
  echo "======================================================================"
} >> "${LOG}" 2>&1
