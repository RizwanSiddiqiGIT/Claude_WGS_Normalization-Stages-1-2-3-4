#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

echo "======================================================================"
echo " STAGE 1 TRIMMED FASTQ INTEGRITY"
echo "======================================================================"

for label in R1 R2; do
  if [ "${label}" = "R1" ]; then
    path="${TRIMMED_FASTQ_R1}"
  else
    path="${TRIMMED_FASTQ_R2}"
  fi

  echo "[${label}] ${path}"
  ls -lh --time-style=long-iso "${path}"
  if gzip -t "${path}"; then
    echo "[PASS] ${label} gzip integrity"
  else
    echo "[FAIL] ${label} gzip integrity"
  fi
done
