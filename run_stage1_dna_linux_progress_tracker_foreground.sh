#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

BASE_DIR_DNA_LINUX="/home/rayzw/DNA-Linux/hg38"
LOGS_DIR="${BASE_DIR_DNA_LINUX}/logs"
QC_DIR="${BASE_DIR_DNA_LINUX}/qc"
FASTQ_DIR="${BASE_DIR_DNA_LINUX}/fastq"
PROGRESS_DIR="${BASE_DIR_DNA_LINUX}/progress"
INTERVAL="${PROGRESS_INTERVAL_SECONDS:-60}"

mkdir -p "${PROGRESS_DIR}" "${LOGS_DIR}"

latest_log="$(readlink -f "${LOGS_DIR}/stage1_dna_linux_latest.log" 2>/dev/null || true)"
if [ -z "${latest_log}" ] || [ ! -s "${latest_log}" ]; then
  latest_log="$(find "${LOGS_DIR}" -maxdepth 1 -type f -name 'stage1_dna_linux_uncompressed_*.log' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)"
fi
if [ -z "${latest_log}" ]; then
  latest_log="${LOGS_DIR}/stage1_dna_linux_missing.log"
  printf 'No stage1_dna_linux log file found yet.\n' > "${latest_log}"
fi

output="${PROGRESS_DIR}/stage1_progress.html"

exec python3 ./progress_tracker.py \
  --stage "Stage 1 FASTQ QC And Preprocessing" \
  --log "${latest_log}" \
  --output "${output}" \
  --watch "${QC_DIR}" \
  --watch "${FASTQ_DIR}" \
  --expect "${FASTQ_DIR}/R1_trimmed.fastq.gz" \
  --expect "${FASTQ_DIR}/R2_trimmed.fastq.gz" \
  --expect "${QC_DIR}/multiqc_report.html" \
  --pattern "stage1_qc_preprocess" \
  --pattern "fastqc" \
  --pattern "fastp" \
  --pattern "multiqc" \
  --interval "${INTERVAL}"
