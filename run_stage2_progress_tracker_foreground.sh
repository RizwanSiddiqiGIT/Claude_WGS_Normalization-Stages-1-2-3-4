#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

INTERVAL="${PROGRESS_INTERVAL_SECONDS:-60}"
PROGRESS_DIR="${BASE_DIR}/progress"
mkdir -p "${PROGRESS_DIR}" "${LOGS_DIR}"

latest_log="$(find "${LOGS_DIR}" -maxdepth 1 -type f -name 'stage2_real_*.log' -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-)"
if [ -z "${latest_log}" ]; then
  latest_log="${LOGS_DIR}/stage2_real_missing.log"
  printf 'No stage2_real_*.log file found yet.\n' > "${latest_log}"
fi

output="${PROGRESS_DIR}/stage2_progress.html"

exec python3 ./progress_tracker.py \
  --stage "Stage 2 Alignment And Duplicate Marking" \
  --log "${latest_log}" \
  --output "${output}" \
  --watch "${BASE_DIR}" \
  --expect "${PROCESSED_BAM}" \
  --expect "${PROCESSED_BAM%.bam}.bai" \
  --expect "${DUP_METRICS}" \
  --expect "${LOGS_DIR}/Rizwan_processed.flagstat.txt" \
  --pattern "stage2_align_markdup" \
  --pattern "bwa mem" \
  --pattern "samtools sort" \
  --pattern "MarkDuplicates" \
  --expected-reads 757618350 \
  --interval "${INTERVAL}"
