#!/bin/bash
set -euo pipefail

R1="${1:-/home/rayzw/DNA-Linux/hg38/tmp/stage1_20260604_223304/R1_trimmed.fastq.gz}"
R2="${2:-/home/rayzw/DNA-Linux/hg38/tmp/stage1_20260604_223304/R2_trimmed.fastq.gz}"
LOGS_DIR="/home/rayzw/DNA-Linux/hg38/logs"

mkdir -p "${LOGS_DIR}"

LOG="${LOGS_DIR}/stage1_trimmed_reformat_validation_$(date +%Y%m%d_%H%M%S).log"
LATEST_LOG="${LOGS_DIR}/stage1_trimmed_reformat_validation_latest.log"
DISCARD_DIR="/home/rayzw/DNA-Linux/hg38/tmp/reformat_discard_$(date +%Y%m%d_%H%M%S)"
ln -sfn "${LOG}" "${LATEST_LOG}"
mkdir -p "${DISCARD_DIR}"

cleanup() {
  rm -rf "${DISCARD_DIR}"
}
trap cleanup EXIT

{
  echo "======================================================================"
  echo " STAGE 1 TRIMMED FASTQ VALIDATION WITH BBTOOLS REFORMAT"
  echo " Started: $(date)"
  echo " R1: ${R1}"
  echo " R2: ${R2}"
  echo "======================================================================"
  test -r "${R1}"
  test -r "${R2}"
  ls -lh "${R1}" "${R2}"
  reformat.sh \
    in1="${R1}" \
    in2="${R2}" \
    out1="${DISCARD_DIR}/R1.discard.fastq" \
    out2="${DISCARD_DIR}/R2.discard.fastq" \
    verifypaired=t \
    overwrite=t
  echo "======================================================================"
  echo " REFORMAT VALIDATION COMPLETE"
  echo " Finished: $(date)"
  echo "======================================================================"
} >> "${LOG}" 2>&1
