#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

INTERVAL="${PROGRESS_INTERVAL_SECONDS:-60}"
PROGRESS_DIR="${BASE_DIR}/progress"
mkdir -p "${PROGRESS_DIR}" "${LOGS_DIR}"

latest_log="$(find "${LOGS_DIR}" -maxdepth 1 -type f \( -name 'stage1_real_*.log' -o -name 'stage1_real_uncompressed_*.log' -o -name 'stage1_real_uncompressed_local_*.log' \) -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)"
if [ -z "${latest_log}" ]; then
  latest_log="${LOGS_DIR}/stage1_real_missing.log"
  printf 'No Stage 1 real-run log file found yet.\n' > "${latest_log}"
fi

output="${PROGRESS_DIR}/stage1_progress.html"

exec python3 ./progress_tracker.py \
  --stage "Stage 1 FASTQ QC And Preprocessing" \
  --log "${latest_log}" \
  --output "${output}" \
  --watch "${QC_DIR}" \
  --watch "$(dirname "${TRIMMED_FASTQ_R1}")" \
  --expect "${TRIMMED_FASTQ_R1}" \
  --expect "${TRIMMED_FASTQ_R2}" \
  --expect "${QC_DIR}/multiqc_report.html" \
  --pattern "stage1_qc_preprocess" \
  --pattern "fastqc" \
  --pattern "fastp" \
  --pattern "multiqc" \
  --interval "${INTERVAL}"
