#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

echo "======================================================================"
echo " STAGE 2 STATUS"
echo "======================================================================"

echo "[Processes]"
ps -eo pid,ppid,etime,%cpu,%mem,rss,cmd \
  | grep -E 'stage2_align_markdup|bwa mem|samtools sort|MarkDuplicates|progress_tracker.py' \
  | grep -v grep || true

echo
echo "[Latest Stage 2 logs]"
find "${LOGS_DIR}" -maxdepth 1 -type f -name 'stage2_real_*.log' -printf '%T@ %p\n' 2>/dev/null \
  | sort -n \
  | tail -n 5 || true

latest_log="$(find "${LOGS_DIR}" -maxdepth 1 -type f -name 'stage2_real_*.log' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)"
if [ -n "${latest_log}" ]; then
  echo
  echo "[Tail: ${latest_log}]"
  tail -n 60 "${latest_log}"
fi

if [ -s "${LOGS_DIR}/stage2_real.pid" ]; then
  echo
  echo "[Recorded Stage 2 PID]"
  cat "${LOGS_DIR}/stage2_real.pid"
fi

echo
echo "[Outputs]"
ls -lh "${SORTED_BAM}" "${PROCESSED_BAM}" "${DUP_METRICS}" "${LOGS_DIR}/Rizwan_processed.flagstat.txt" 2>/dev/null || true

echo
echo "[Progress files]"
ls -lh "${BASE_DIR}/progress/stage2_progress.html" "${BASE_DIR}/progress/stage2_progress_tracker.log" 2>/dev/null || true
