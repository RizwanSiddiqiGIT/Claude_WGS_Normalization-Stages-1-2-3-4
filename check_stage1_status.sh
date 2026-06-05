#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

echo "======================================================================"
echo " STAGE 1 STATUS"
echo "======================================================================"

echo "[Processes]"
ps -eo pid,ppid,etime,%cpu,%mem,rss,cmd \
  | grep -E 'stage1_qc_preprocess|fastqc|fastp|multiqc|progress_tracker.py' \
  | grep -v grep || true

echo
echo "[Latest Stage 1 logs]"
find "${LOGS_DIR}" -maxdepth 1 -type f \( -name 'stage1_real_*.log' -o -name 'stage1_real_uncompressed_*.log' \) -printf '%T@ %p\n' 2>/dev/null \
  | sort -n \
  | tail -n 5 || true

latest_log="$(readlink -f "${LOGS_DIR}/stage1_real_latest.log" 2>/dev/null || true)"
if [ -n "${latest_log}" ] && [ -s "${latest_log}" ]; then
  echo
  echo "[Tail: ${latest_log}]"
  tail -n 80 "${latest_log}"
fi

echo
echo "[Stage 1 outputs]"
ls -lh "${TRIMMED_FASTQ_R1}" "${TRIMMED_FASTQ_R2}" "${QC_DIR}/multiqc_report.html" 2>/dev/null || true

echo
echo "[Progress page]"
ls -lh "${BASE_DIR}/progress/stage1_progress.html" 2>/dev/null || true
