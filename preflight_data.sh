#!/bin/bash
set -u

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

PASS=0
FAIL=0
WARN=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN + 1)); }

check_file() {
  local label="$1"
  local path="$2"
  if [ -s "${path}" ]; then
    pass "${label}: ${path}"
  else
    fail "${label}: missing or empty at ${path}"
  fi
}

check_output_parent() {
  local label="$1"
  local path="$2"
  local parent
  parent="$(dirname "${path}")"
  if [ -d "${parent}" ] && [ -w "${parent}" ]; then
    pass "${label} parent writable: ${parent}"
  elif [ -d "${parent}" ]; then
    fail "${label} parent exists but is not writable: ${parent}"
  else
    warn "${label} parent missing; script will create if permitted: ${parent}"
  fi
}

echo "======================================================================"
echo " WGS NORMALIZATION STAGES 1-4 DATA PREFLIGHT"
echo "======================================================================"

check_file "reference FASTA" "${REF_FA}"
if [ -s "${REF_FA}.fai" ]; then
  pass "reference FASTA index: ${REF_FA}.fai"
else
  warn "reference FASTA index missing; stage scripts can create it: ${REF_FA}.fai"
fi

check_file "raw FASTQ R1" "${RAW_FASTQ_R1}"
check_file "raw FASTQ R2" "${RAW_FASTQ_R2}"

check_output_parent "trimmed FASTQ R1" "${TRIMMED_FASTQ_R1}"
check_output_parent "trimmed FASTQ R2" "${TRIMMED_FASTQ_R2}"
check_output_parent "processed BAM" "${PROCESSED_BAM}"
check_output_parent "raw VCF" "${RAW_VCF}"
check_output_parent "filtered VCF" "${FILTERED_VCF}"

echo "======================================================================"
echo " SUMMARY: pass=${PASS} warn=${WARN} fail=${FAIL}"
echo "======================================================================"

[ "${FAIL}" -eq 0 ]

