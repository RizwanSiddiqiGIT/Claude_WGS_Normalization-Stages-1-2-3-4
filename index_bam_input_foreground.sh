#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config_bam_input.env

mkdir -p "${LOGS_DIR}"

LOG="${LOGS_DIR}/bam_input_index_$(date +%Y%m%d_%H%M%S).log"
LATEST_LOG="${LOGS_DIR}/bam_input_index_latest.log"
ln -sfn "${LOG}" "${LATEST_LOG}"

{
  echo "======================================================================"
  echo " BAM INPUT INDEXING"
  echo " Started: $(date)"
  echo " BAM: ${PROCESSED_BAM}"
  echo "======================================================================"
  "${SAMTOOLS_BIN}" quickcheck -v "${PROCESSED_BAM}"
  "${SAMTOOLS_BIN}" index -@ "${THREADS}" "${PROCESSED_BAM}"
  ls -lh "${PROCESSED_BAM}" "${PROCESSED_BAM}.bai"
  echo "======================================================================"
  echo " BAM INPUT INDEXING COMPLETE"
  echo " Finished: $(date)"
  echo "======================================================================"
} >> "${LOG}" 2>&1
