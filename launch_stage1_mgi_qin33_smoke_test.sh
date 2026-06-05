#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

SMOKE_ROOT="${TMP_DIR}/stage1_mgi_qin33_smoke_test"
SMOKE_INPUT="${SMOKE_ROOT}/input"
SMOKE_OUTPUT="${SMOKE_ROOT}/fastq"
SMOKE_QC="${SMOKE_ROOT}/qc"
SMOKE_LOGS="${SMOKE_ROOT}/logs"
SMOKE_TMP="${SMOKE_ROOT}/tmp"

rm -rf "${SMOKE_ROOT}"
mkdir -p "${SMOKE_INPUT}" "${SMOKE_OUTPUT}" "${SMOKE_QC}" "${SMOKE_LOGS}" "${SMOKE_TMP}"

python3 - "${SMOKE_INPUT}/R1.fq.gz" "${SMOKE_INPUT}/R2.fq.gz" <<'PY'
import gzip
import sys

r1_path, r2_path = sys.argv[1], sys.argv[2]
adapter_r1 = "AAGTCGGAGGCCAAGCGGTCTTAGGAAGACAA"
adapter_r2 = "AAGTCGGATCGTAGCCATGTCGTTCTGTGAGCCAAGGAGTTG"

with gzip.open(r1_path, "wt") as r1, gzip.open(r2_path, "wt") as r2:
    for i in range(1, 101):
        name = f"E250168373L1C001R000000{i:05d}"
        seq1 = ("ACGT" * 30) + adapter_r1[:20] + ("G" * 10)
        seq2 = ("TGCA" * 30) + adapter_r2[:20] + ("G" * 10)
        qual1 = "I" * len(seq1)
        qual2 = "I" * len(seq2)
        r1.write(f"@{name}/1\n{seq1}\n+\n{qual1}\n")
        r2.write(f"@{name}/2\n{seq2}\n+\n{qual2}\n")
PY

RUN_ID="mgi_qin33_smoke_$(date +%Y%m%d_%H%M%S)"
LOG="${SMOKE_LOGS}/stage1_mgi_qin33_smoke_${RUN_ID}.log"

{
  echo "======================================================================"
  echo " STAGE 1 MGI QIN33 SMOKE TEST"
  echo " Run ID: ${RUN_ID}"
  echo " Started: $(date)"
  echo "======================================================================"
  BASE_DIR="${SMOKE_ROOT}" \
  LOGS_DIR="${SMOKE_LOGS}" \
  QC_DIR="${SMOKE_QC}" \
  TMP_DIR="${SMOKE_TMP}" \
  RAW_FASTQ_R1="${SMOKE_INPUT}/R1.fq.gz" \
  RAW_FASTQ_R2="${SMOKE_INPUT}/R2.fq.gz" \
  TRIMMED_FASTQ_R1="${SMOKE_OUTPUT}/R1_trimmed.fastq.gz" \
  TRIMMED_FASTQ_R2="${SMOKE_OUTPUT}/R2_trimmed.fastq.gz" \
  THREADS=2 \
  FASTP_THREADS=2 \
  STAGE1_RUN_ID="${RUN_ID}" \
  ./stage1_mgi_qin33_preprocess.sh
  echo "======================================================================"
  echo " STAGE 1 MGI QIN33 SMOKE TEST COMPLETE"
  echo " Finished: $(date)"
  echo " Outputs: ${SMOKE_ROOT}"
  echo "======================================================================"
} | tee "${LOG}"
