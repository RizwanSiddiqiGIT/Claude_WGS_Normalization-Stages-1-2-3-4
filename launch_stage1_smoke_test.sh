#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

TEST_ROOT="${BASE_DIR}/tmp/stage1_smoke_test"
RAW_DIR="${TEST_ROOT}/raw_fastq"
TRIM_DIR="${TEST_ROOT}/trimmed_fastq"
QC_DIR_TEST="${TEST_ROOT}/qc"
LOG_DIR="${TEST_ROOT}/logs"
WORKSPACE_DIR="${TEST_ROOT}/workspace"

R1="${RAW_DIR}/stage1_smoke_R1.fastq.gz"
R2="${RAW_DIR}/stage1_smoke_R2.fastq.gz"
TRIM_R1="${TRIM_DIR}/stage1_smoke_R1_trimmed.fastq.gz"
TRIM_R2="${TRIM_DIR}/stage1_smoke_R2_trimmed.fastq.gz"

echo "======================================================================"
echo " STAGE 1 SMOKE TEST"
echo " This creates tiny synthetic FASTQ files and runs FastQC, fastp, and MultiQC."
echo " Test root: ${TEST_ROOT}"
echo "======================================================================"

rm -rf "${TEST_ROOT}"
mkdir -p "${RAW_DIR}" "${TRIM_DIR}" "${QC_DIR_TEST}" "${LOG_DIR}"

echo "[1/6] Creating synthetic paired FASTQ input"
read1_seq="ACGTGATCGTACGTTAGCCTAGGCTAACGTACGATCGATCGTACCTAGGCTAAGCTTAGCTAGGATCCGTA"
read2_seq="TACGGATCCTAGCTAAGCTTAGCCTAGGTACGATCGATCGTACGTTAGCCTAGGCTAACGTACGATCACGT"
read1_qual="$(printf '%*s' "${#read1_seq}" '' | tr ' ' 'I')"
read2_qual="$(printf '%*s' "${#read2_seq}" '' | tr ' ' 'I')"

{
  for i in $(seq 1 100); do
    printf '@stage1_smoke_%04d/1\n' "${i}"
    printf '%s\n' "${read1_seq}"
    printf '+\n'
    printf '%s\n' "${read1_qual}"
  done
} | gzip -c > "${R1}"

{
  for i in $(seq 1 100); do
    printf '@stage1_smoke_%04d/2\n' "${i}"
    printf '%s\n' "${read2_seq}"
    printf '+\n'
    printf '%s\n' "${read2_qual}"
  done
} | gzip -c > "${R2}"

echo "[2/6] Running recreated Stage 1 script on synthetic FASTQs"
BASE_DIR="${WORKSPACE_DIR}" \
RAW_FASTQ_R1="${R1}" \
RAW_FASTQ_R2="${R2}" \
TRIMMED_FASTQ_R1="${TRIM_R1}" \
TRIMMED_FASTQ_R2="${TRIM_R2}" \
QC_DIR="${QC_DIR_TEST}" \
LOGS_DIR="${LOG_DIR}" \
TMP_DIR="${TEST_ROOT}/tmp" \
THREADS=2 \
FASTP_THREADS=2 \
STAGE1_RUN_ID="smoke" \
./stage1_qc_preprocess.sh > "${LOG_DIR}/stage1_qc_preprocess.log" 2>&1

echo "[3/6] Verifying trimmed gzip integrity"
gzip -t "${TRIM_R1}"
gzip -t "${TRIM_R2}"

echo "[4/6] Verifying fastp report outputs"
test -s "${QC_DIR_TEST}/fastp_smoke.html"
test -s "${QC_DIR_TEST}/fastp_smoke.json"

echo "[5/6] Verifying MultiQC output"
test -s "${QC_DIR_TEST}/multiqc_report.html"

echo "[6/6] Verifying expected outputs"
for output in \
  "${R1}" \
  "${R2}" \
  "${TRIM_R1}" \
  "${TRIM_R2}" \
  "${QC_DIR_TEST}/fastp_smoke.html" \
  "${QC_DIR_TEST}/fastp_smoke.json" \
  "${QC_DIR_TEST}/multiqc_report.html"; do
  if [ ! -s "${output}" ]; then
    echo "[FAIL] Missing expected output: ${output}"
    exit 1
  fi
  echo "[PASS] ${output}"
done

raw_reads="$(gzip -dc "${R1}" | awk 'END {print NR / 4}')"
trimmed_reads="$(gzip -dc "${TRIM_R1}" | awk 'END {print NR / 4}')"

echo "======================================================================"
echo " STAGE 1 SMOKE TEST COMPLETE"
echo " Raw read pairs: ${raw_reads}"
echo " Trimmed read pairs retained: ${trimmed_reads}"
echo " MultiQC report: ${QC_DIR_TEST}/multiqc_report.html"
echo " Logs: ${LOG_DIR}"
echo "======================================================================"
