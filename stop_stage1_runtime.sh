#!/bin/bash
set -euo pipefail

patterns=(
  "stage1_qc_preprocess"
  "FastQCApplication"
  "fastp"
  "multiqc"
)

for pattern in "${patterns[@]}"; do
  pkill -f "${pattern}" 2>/dev/null || true
done

echo "Stage 1 runtime processes stopped if they were present."
