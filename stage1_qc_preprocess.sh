#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

RUN_ID="${STAGE1_RUN_ID:-$(date +%Y%m%d_%H%M%S)}"
FASTQ_DIR="$(dirname "${TRIMMED_FASTQ_R1}")"
STAGE1_TMP_DIR="${TMP_DIR}/stage1_${RUN_ID}"
TMP_R1="${STAGE1_TMP_DIR}/R1_trimmed.fastq.gz"
TMP_R2="${STAGE1_TMP_DIR}/R2_trimmed.fastq.gz"
REPORT_HTML="${QC_DIR}/fastp_${RUN_ID}.html"
REPORT_JSON="${QC_DIR}/fastp_${RUN_ID}.json"
LATEST_HTML="${QC_DIR}/fastp.html"
LATEST_JSON="${QC_DIR}/fastp.json"
BACKUP_DIR="${FASTQ_DIR}/previous_stage1_${RUN_ID}"

mkdir -p "${QC_DIR}" "${FASTQ_DIR}" "${LOGS_DIR}" "${STAGE1_TMP_DIR}"

echo "======================================================================"
echo " STAGE 1 FASTQ QC AND PREPROCESSING"
echo " Run ID: ${RUN_ID}"
echo " Raw R1: ${RAW_FASTQ_R1}"
echo " Raw R2: ${RAW_FASTQ_R2}"
echo " Temp R1: ${TMP_R1}"
echo " Temp R2: ${TMP_R2}"
echo " Final R1: ${TRIMMED_FASTQ_R1}"
echo " Final R2: ${TRIMMED_FASTQ_R2}"
echo "======================================================================"

echo "[1/7] Verifying raw FASTQ gzip integrity"
if [ "${ASSUME_RAW_FASTQ_VALID}" = "1" ]; then
  echo "[WARN] Skipping raw gzip integrity checks because ASSUME_RAW_FASTQ_VALID=1"
else
  gzip -t "${RAW_FASTQ_R1}"
  gzip -t "${RAW_FASTQ_R2}"
fi

echo "[2/7] Running raw FastQC"
"${FASTQC_BIN}" "${RAW_FASTQ_R1}" "${RAW_FASTQ_R2}" -o "${QC_DIR}" -t "${THREADS}"

echo "[3/7] Running fastp paired-end filtering into temp files"
"${FASTP_BIN}" \
  -i "${RAW_FASTQ_R1}" \
  -I "${RAW_FASTQ_R2}" \
  -o "${TMP_R1}" \
  -O "${TMP_R2}" \
  -q 30 \
  -l 50 \
  -w "${FASTP_THREADS}" \
  --detect_adapter_for_pe \
  --html "${REPORT_HTML}" \
  --json "${REPORT_JSON}"

echo "[4/7] Verifying trimmed FASTQ gzip integrity before promotion"
gzip -t "${TMP_R1}"
gzip -t "${TMP_R2}"

echo "[5/7] Backing up existing final trimmed FASTQs if present"
mkdir -p "${BACKUP_DIR}"
if [ -e "${TRIMMED_FASTQ_R1}" ]; then
  mv "${TRIMMED_FASTQ_R1}" "${BACKUP_DIR}/R1_trimmed.fastq.gz"
fi
if [ -e "${TRIMMED_FASTQ_R2}" ]; then
  mv "${TRIMMED_FASTQ_R2}" "${BACKUP_DIR}/R2_trimmed.fastq.gz"
fi

echo "[6/7] Promoting verified temp FASTQs into final paths"
mv "${TMP_R1}" "${TRIMMED_FASTQ_R1}"
mv "${TMP_R2}" "${TRIMMED_FASTQ_R2}"
ln -sfn "${REPORT_HTML}" "${LATEST_HTML}"
ln -sfn "${REPORT_JSON}" "${LATEST_JSON}"

echo "[7/7] Running final FastQC and MultiQC"
"${FASTQC_BIN}" "${TRIMMED_FASTQ_R1}" "${TRIMMED_FASTQ_R2}" -o "${QC_DIR}" -t "${THREADS}"
"${MULTIQC_BIN}" "${QC_DIR}" -o "${QC_DIR}" --force

rmdir "${STAGE1_TMP_DIR}" 2>/dev/null || true

echo "======================================================================"
echo " STAGE 1 COMPLETE"
echo " R1: ${TRIMMED_FASTQ_R1}"
echo " R2: ${TRIMMED_FASTQ_R2}"
echo " Backup directory: ${BACKUP_DIR}"
echo " fastp HTML: ${REPORT_HTML}"
echo " fastp JSON: ${REPORT_JSON}"
echo "======================================================================"
