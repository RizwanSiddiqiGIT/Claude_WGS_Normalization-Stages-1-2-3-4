#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

BASE_DIR_DNA_LINUX="${STAGE1_MGI_QIN33_BASE_DIR:-/home/rayzw/DNA-Linux/hg38}"
LOGS_DIR_DNA_LINUX="${STAGE1_MGI_QIN33_LOGS_DIR:-${BASE_DIR_DNA_LINUX}/logs}"
QC_OUT_DIR="${STAGE1_MGI_QIN33_QC_DIR:-${BASE_DIR_DNA_LINUX}/qc_mgi_qin33}"
FASTQ_OUT_DIR="${STAGE1_MGI_QIN33_FASTQ_DIR:-${BASE_DIR_DNA_LINUX}/fastq_mgi_qin33}"
PROGRESS_DIR="${STAGE1_MGI_QIN33_PROGRESS_DIR:-${BASE_DIR_DNA_LINUX}/progress}"
LOG_PATH="${LOG:-${LOGS_DIR_DNA_LINUX}/stage1_mgi_qin33_latest.log}"

mkdir -p "${PROGRESS_DIR}"

python3 ./progress_tracker.py \
  --stage "Stage 1 MGI qin33 FASTQ QC And Preprocessing" \
  --log "${LOG_PATH}" \
  --output "${PROGRESS_DIR}/stage1_mgi_qin33_progress.html" \
  --watch "${QC_OUT_DIR}" \
  --watch "${FASTQ_OUT_DIR}" \
  --expect "${FASTQ_OUT_DIR}/R1_trimmed.fastq.gz" \
  --expect "${FASTQ_OUT_DIR}/R2_trimmed.fastq.gz" \
  --expect "${QC_OUT_DIR}/multiqc_report.html" \
  --pattern "stage1_mgi_qin33" \
  --pattern "fastqc" \
  --pattern "fastp" \
  --pattern "multiqc" \
  --interval 60
