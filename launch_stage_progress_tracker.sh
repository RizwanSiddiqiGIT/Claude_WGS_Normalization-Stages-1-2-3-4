#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

STAGE="${1:-stage1}"
INTERVAL="${PROGRESS_INTERVAL_SECONDS:-60}"
PROGRESS_DIR="${BASE_DIR}/progress"
mkdir -p "${PROGRESS_DIR}" "${LOGS_DIR}"

case "${STAGE}" in
  stage1)
    latest_log="$(find "${LOGS_DIR}" -maxdepth 1 -type f -name 'stage1_real_*.log' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)"
    if [ -z "${latest_log}" ]; then
      latest_log="${LOGS_DIR}/stage1_real_missing.log"
      printf 'No stage1_real_*.log file found yet.\n' > "${latest_log}"
    fi
    output="${PROGRESS_DIR}/stage1_progress.html"
    nohup python3 ./progress_tracker.py \
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
      --interval "${INTERVAL}" \
      > "${PROGRESS_DIR}/stage1_progress_tracker.log" 2>&1 &
    echo "PID=$!"
    echo "HTML=${output}"
    echo "LOG=${PROGRESS_DIR}/stage1_progress_tracker.log"
    ;;
  *)
    echo "Unknown stage: ${STAGE}"
    echo "Currently supported: stage1"
    exit 1
    ;;
esac

