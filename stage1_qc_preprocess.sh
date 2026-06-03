#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

mkdir -p "${QC_DIR}" "$(dirname "${TRIMMED_FASTQ_R1}")" "${LOGS_DIR}"

echo "[STAGE 1] FASTQ QC and preprocessing"
"${FASTQC_BIN}" "${RAW_FASTQ_R1}" "${RAW_FASTQ_R2}" -o "${QC_DIR}" -t "${THREADS}"
"${MULTIQC_BIN}" "${QC_DIR}" -o "${QC_DIR}"

"${FASTP_BIN}" \
  -i "${RAW_FASTQ_R1}" \
  -I "${RAW_FASTQ_R2}" \
  -o "${TRIMMED_FASTQ_R1}" \
  -O "${TRIMMED_FASTQ_R2}" \
  -q 30 \
  -l 50 \
  -w "${FASTP_THREADS}" \
  --detect_adapter_for_pe \
  --html "${QC_DIR}/fastp.html" \
  --json "${QC_DIR}/fastp.json"

echo "[STAGE 1 COMPLETE] ${TRIMMED_FASTQ_R1} ${TRIMMED_FASTQ_R2}"

