#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

RUN_ID="$(date +%Y%m%d_%H%M%S)"
FASTQ_DIR="$(dirname "${TRIMMED_FASTQ_R1}")"
TMP_R1="${FASTQ_DIR}/R1_trimmed.${RUN_ID}.tmp.fastq.gz"
TMP_R2_DISCARD="${FASTQ_DIR}/R2_trimmed.${RUN_ID}.discard.fastq.gz"
LOG="${LOGS_DIR}/regenerate_r1_trimmed_${RUN_ID}.log"
HTML="${QC_DIR}/fastp_r1_regen_${RUN_ID}.html"
JSON="${QC_DIR}/fastp_r1_regen_${RUN_ID}.json"
BACKUP_R1="${TRIMMED_FASTQ_R1}.corrupt_${RUN_ID}"

mkdir -p "${FASTQ_DIR}" "${LOGS_DIR}" "${QC_DIR}"

{
  echo "======================================================================"
  echo " REGENERATE R1_TRIMMED ONLY"
  echo " Started: $(date)"
  echo " Raw R1: ${RAW_FASTQ_R1}"
  echo " Raw R2: ${RAW_FASTQ_R2}"
  echo " Temp R1: ${TMP_R1}"
  echo " Temp R2 discard: ${TMP_R2_DISCARD}"
  echo " Final R1: ${TRIMMED_FASTQ_R1}"
  echo "======================================================================"

  if [ -e "${TMP_R1}" ] || [ -e "${TMP_R2_DISCARD}" ]; then
    echo "[FAIL] Temp output already exists for run id ${RUN_ID}"
    exit 1
  fi

  echo "[1/5] Running fastp paired filtering; keeping only regenerated R1"
  "${FASTP_BIN}" \
    -i "${RAW_FASTQ_R1}" \
    -I "${RAW_FASTQ_R2}" \
    -o "${TMP_R1}" \
    -O "${TMP_R2_DISCARD}" \
    -q 30 \
    -l 50 \
    -w "${FASTP_THREADS}" \
    --detect_adapter_for_pe \
    --html "${HTML}" \
    --json "${JSON}"

  echo "[2/5] Verifying regenerated R1 gzip integrity"
  gzip -t "${TMP_R1}"

  echo "[3/5] Backing up previous R1 if present"
  if [ -e "${TRIMMED_FASTQ_R1}" ]; then
    mv "${TRIMMED_FASTQ_R1}" "${BACKUP_R1}"
    echo "Previous R1 moved to: ${BACKUP_R1}"
  fi

  echo "[4/5] Promoting regenerated R1 into place"
  mv "${TMP_R1}" "${TRIMMED_FASTQ_R1}"

  echo "[5/5] Removing discarded temporary R2 from this R1-only run"
  rm -f "${TMP_R2_DISCARD}"

  echo "======================================================================"
  echo " R1_TRIMMED REGENERATION COMPLETE"
  echo " Finished: $(date)"
  echo " New R1: ${TRIMMED_FASTQ_R1}"
  echo " Backup old R1: ${BACKUP_R1}"
  echo " Log: ${LOG}"
  echo "======================================================================"
} 2>&1 | tee "${LOG}"
