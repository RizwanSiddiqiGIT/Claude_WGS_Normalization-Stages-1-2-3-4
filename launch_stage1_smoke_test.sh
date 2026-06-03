#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

TEST_ROOT="${BASE_DIR}/tmp/stage1_smoke_test"
RAW_DIR="${TEST_ROOT}/raw_fastq"
TRIM_DIR="${TEST_ROOT}/trimmed_fastq"
QC_DIR_TEST="${TEST_ROOT}/qc"
LOG_DIR="${TEST_ROOT}/logs"

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

echo "[2/6] Running FastQC on raw synthetic FASTQs"
"${FASTQC_BIN}" "${R1}" "${R2}" -o "${QC_DIR_TEST}" -t 2 > "${LOG_DIR}/fastqc_raw.log" 2>&1

echo "[3/6] Running fastp adapter/quality preprocessing"
"${FASTP_BIN}" \
  -i "${R1}" \
  -I "${R2}" \
  -o "${TRIM_R1}" \
  -O "${TRIM_R2}" \
  -q 30 \
  -l 50 \
  -w 2 \
  --detect_adapter_for_pe \
  --html "${QC_DIR_TEST}/fastp_smoke.html" \
  --json "${QC_DIR_TEST}/fastp_smoke.json" \
  > "${LOG_DIR}/fastp.log" 2>&1

echo "[4/6] Running FastQC on trimmed synthetic FASTQs"
"${FASTQC_BIN}" "${TRIM_R1}" "${TRIM_R2}" -o "${QC_DIR_TEST}" -t 2 > "${LOG_DIR}/fastqc_trimmed.log" 2>&1

echo "[5/6] Running MultiQC over smoke-test QC folder"
"${MULTIQC_BIN}" "${QC_DIR_TEST}" -o "${QC_DIR_TEST}" -n "stage1_smoke_multiqc_report.html" > "${LOG_DIR}/multiqc.log" 2>&1

echo "[6/6] Verifying expected outputs"
for output in \
  "${R1}" \
  "${R2}" \
  "${TRIM_R1}" \
  "${TRIM_R2}" \
  "${QC_DIR_TEST}/fastp_smoke.html" \
  "${QC_DIR_TEST}/fastp_smoke.json" \
  "${QC_DIR_TEST}/stage1_smoke_multiqc_report.html"; do
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
echo " MultiQC report: ${QC_DIR_TEST}/stage1_smoke_multiqc_report.html"
echo " Logs: ${LOG_DIR}"
echo "======================================================================"
