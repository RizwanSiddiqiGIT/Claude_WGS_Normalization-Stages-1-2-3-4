#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

FASTQ_R1="/home/rayzw/DNA-Linux/hg38/raw_uncompressed/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq"
LOGS_DIR="/home/rayzw/DNA-Linux/hg38/logs"
mkdir -p "${LOGS_DIR}"

LOG="${LOGS_DIR}/fastq1_full_structure_validation_$(date +%Y%m%d_%H%M%S).log"
LATEST_LOG="${LOGS_DIR}/fastq1_full_structure_validation_latest.log"
ln -sfn "${LOG}" "${LATEST_LOG}"

{
  echo "======================================================================"
  echo " FASTQ 1 FULL STRUCTURE VALIDATION"
  echo " Started: $(date)"
  echo " FASTQ: ${FASTQ_R1}"
  echo "======================================================================"
  test -r "${FASTQ_R1}"
  ls -lh "${FASTQ_R1}"
  python3 ./validate_fastq_structure_full.py \
    --progress-reads 5000000 \
    --max-bad-records 100 \
    "${FASTQ_R1}"
  echo "======================================================================"
  echo " FASTQ 1 FULL STRUCTURE VALIDATION COMPLETE"
  echo " Finished: $(date)"
  echo "======================================================================"
} >> "${LOG}" 2>&1
