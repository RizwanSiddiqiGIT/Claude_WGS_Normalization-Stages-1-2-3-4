#!/bin/bash
set -euo pipefail

# Stage 1 MGI qin33
# Major difference from the original Stage 1: this fork uses an MGI-aware
# fastp profile from the reference document: explicit Phred+33 handling,
# MGI adapter sequences, poly-G trimming, and BBTools paired validation before
# any trimmed FASTQ is promoted for alignment.

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

RUN_ID="${STAGE1_RUN_ID:-$(date +%Y%m%d_%H%M%S)}"
FASTQ_DIR="$(dirname "${TRIMMED_FASTQ_R1}")"
STAGE1_TMP_DIR="${TMP_DIR}/stage1_mgi_qin33_${RUN_ID}"
TMP_R1="${STAGE1_TMP_DIR}/R1_trimmed.fastq.gz"
TMP_R2="${STAGE1_TMP_DIR}/R2_trimmed.fastq.gz"
REPORT_HTML="${QC_DIR}/fastp_mgi_qin33_${RUN_ID}.html"
REPORT_JSON="${QC_DIR}/fastp_mgi_qin33_${RUN_ID}.json"
LATEST_HTML="${QC_DIR}/fastp_mgi_qin33.html"
LATEST_JSON="${QC_DIR}/fastp_mgi_qin33.json"
BACKUP_DIR="${FASTQ_DIR}/previous_stage1_mgi_qin33_${RUN_ID}"

MGI_ADAPTER_R1="${MGI_ADAPTER_R1:-AAGTCGGAGGCCAAGCGGTCTTAGGAAGACAA}"
MGI_ADAPTER_R2="${MGI_ADAPTER_R2:-AAGTCGGATCGTAGCCATGTCGTTCTGTGAGCCAAGGAGTTG}"
MGI_QUALIFIED_PHRED="${MGI_QUALIFIED_PHRED:-15}"
MGI_LENGTH_REQUIRED="${MGI_LENGTH_REQUIRED:-36}"
MGI_TRIM_POLY_G="${MGI_TRIM_POLY_G:-1}"
REFORMAT_BIN="${REFORMAT_BIN:-reformat.sh}"

mkdir -p "${QC_DIR}" "${FASTQ_DIR}" "${LOGS_DIR}" "${STAGE1_TMP_DIR}"

verify_raw_fastq() {
  local path="$1"
  if [ "${ASSUME_RAW_FASTQ_VALID}" = "1" ]; then
    echo "[WARN] Skipping raw FASTQ validation for ${path} because ASSUME_RAW_FASTQ_VALID=1"
    return 0
  fi
  case "${path}" in
    *.gz)
      gzip -t "${path}"
      ;;
    *)
      python3 ./validate_fastq_structure_full.py "${path}"
      ;;
  esac
}

echo "======================================================================"
echo " STAGE 1 MGI QIN33 FASTQ QC AND PREPROCESSING"
echo " Run ID: ${RUN_ID}"
echo " Raw R1: ${RAW_FASTQ_R1}"
echo " Raw R2: ${RAW_FASTQ_R2}"
echo " Temp R1: ${TMP_R1}"
echo " Temp R2: ${TMP_R2}"
echo " Final R1: ${TRIMMED_FASTQ_R1}"
echo " Final R2: ${TRIMMED_FASTQ_R2}"
echo " MGI adapter R1: ${MGI_ADAPTER_R1}"
echo " MGI adapter R2: ${MGI_ADAPTER_R2}"
echo " Qualified Phred: ${MGI_QUALIFIED_PHRED}"
echo " Length required: ${MGI_LENGTH_REQUIRED}"
echo "======================================================================"

echo "[1/8] Verifying raw FASTQ input containers"
verify_raw_fastq "${RAW_FASTQ_R1}"
verify_raw_fastq "${RAW_FASTQ_R2}"

echo "[2/8] Running raw FastQC"
"${FASTQC_BIN}" "${RAW_FASTQ_R1}" "${RAW_FASTQ_R2}" -o "${QC_DIR}" -t "${THREADS}"

echo "[3/8] Running MGI/qin33 fastp paired-end filtering into temp files"
FASTP_ARGS=(
  -i "${RAW_FASTQ_R1}"
  -I "${RAW_FASTQ_R2}"
  -o "${TMP_R1}"
  -O "${TMP_R2}"
  --adapter_sequence "${MGI_ADAPTER_R1}"
  --adapter_sequence_r2 "${MGI_ADAPTER_R2}"
  --qualified_quality_phred "${MGI_QUALIFIED_PHRED}"
  --length_required "${MGI_LENGTH_REQUIRED}"
  -w "${FASTP_THREADS}"
  --html "${REPORT_HTML}"
  --json "${REPORT_JSON}"
)
if [ "${MGI_TRIM_POLY_G}" = "1" ]; then
  FASTP_ARGS+=(--trim_poly_g)
fi
"${FASTP_BIN}" "${FASTP_ARGS[@]}"

echo "[4/8] Verifying trimmed FASTQ gzip integrity before promotion"
gzip -t "${TMP_R1}"
gzip -t "${TMP_R2}"

echo "[5/8] Verifying trimmed FASTQ paired structure and qin33 characters"
python3 ./validate_paired_fastq_qin33.py "${TMP_R1}" "${TMP_R2}"

echo "[6/8] Backing up existing final trimmed FASTQs if present"
mkdir -p "${BACKUP_DIR}"
if [ -e "${TRIMMED_FASTQ_R1}" ]; then
  mv "${TRIMMED_FASTQ_R1}" "${BACKUP_DIR}/R1_trimmed.fastq.gz"
fi
if [ -e "${TRIMMED_FASTQ_R2}" ]; then
  mv "${TRIMMED_FASTQ_R2}" "${BACKUP_DIR}/R2_trimmed.fastq.gz"
fi

echo "[7/8] Promoting verified temp FASTQs into final paths"
mv "${TMP_R1}" "${TRIMMED_FASTQ_R1}"
mv "${TMP_R2}" "${TRIMMED_FASTQ_R2}"
ln -sfn "${REPORT_HTML}" "${LATEST_HTML}"
ln -sfn "${REPORT_JSON}" "${LATEST_JSON}"
ln -sfn "${REPORT_HTML}" "${QC_DIR}/fastp.html"
ln -sfn "${REPORT_JSON}" "${QC_DIR}/fastp.json"

echo "[8/8] Running final FastQC and MultiQC"
"${FASTQC_BIN}" "${TRIMMED_FASTQ_R1}" "${TRIMMED_FASTQ_R2}" -o "${QC_DIR}" -t "${THREADS}"
"${MULTIQC_BIN}" "${QC_DIR}" -o "${QC_DIR}" --force

rmdir "${STAGE1_TMP_DIR}" 2>/dev/null || true

echo "======================================================================"
echo " STAGE 1 MGI QIN33 COMPLETE"
echo " R1: ${TRIMMED_FASTQ_R1}"
echo " R2: ${TRIMMED_FASTQ_R2}"
echo " Backup directory: ${BACKUP_DIR}"
echo " fastp HTML: ${REPORT_HTML}"
echo " fastp JSON: ${REPORT_JSON}"
echo "======================================================================"
