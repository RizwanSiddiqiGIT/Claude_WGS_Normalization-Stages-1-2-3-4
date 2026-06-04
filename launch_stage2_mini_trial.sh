#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

TRIAL_READS="${TRIAL_READS:-250000}"
TRIAL_DIR="${TMP_DIR}/stage2_mini_trial"
TRIAL_FASTQ_R1="${TRIAL_DIR}/R1_trial.fastq.gz"
TRIAL_FASTQ_R2="${TRIAL_DIR}/R2_trial.fastq.gz"
TRIAL_SORTED_BAM="${TRIAL_DIR}/stage2_trial_sorted.bam"
TRIAL_PROCESSED_BAM="${TRIAL_DIR}/stage2_trial_processed.bam"
TRIAL_DUP_METRICS="${TRIAL_DIR}/stage2_trial_dup_metrics.txt"
TRIAL_FLAGSTAT="${TRIAL_DIR}/stage2_trial_processed.flagstat.txt"
TRIAL_LOG="${LOGS_DIR}/stage2_mini_trial_$(date +%Y%m%d_%H%M%S).log"
TRIAL_LINES=$((TRIAL_READS * 4))

mkdir -p "${TRIAL_DIR}" "${LOGS_DIR}"

{
  echo "======================================================================"
  echo " STAGE 2 MINI TRIAL"
  echo " Reads per mate: ${TRIAL_READS}"
  echo " Trial directory: ${TRIAL_DIR}"
  echo "======================================================================"

  echo "[1/5] Creating small FASTQ slices from real Stage 1 outputs"
  set +o pipefail
  gzip -cd "${TRIMMED_FASTQ_R1}" | head -n "${TRIAL_LINES}" | gzip -c > "${TRIAL_FASTQ_R1}"
  gzip -cd "${TRIMMED_FASTQ_R2}" | head -n "${TRIAL_LINES}" | gzip -c > "${TRIAL_FASTQ_R2}"
  set -o pipefail

  echo "[2/5] Aligning trial reads with bwa"
  "${BWA_BIN}" mem \
    -t "${THREADS}" \
    -R "${READ_GROUP}" \
    "${REF_FA}" \
    "${TRIAL_FASTQ_R1}" \
    "${TRIAL_FASTQ_R2}" \
    | "${SAMTOOLS_BIN}" sort -@ "${SORT_THREADS}" -o "${TRIAL_SORTED_BAM}"

  echo "[3/5] Marking duplicates with Picard"
  "${JAVA_BIN}" -Xmx8g -jar "${PICARD_JAR}" MarkDuplicates \
    I="${TRIAL_SORTED_BAM}" \
    O="${TRIAL_PROCESSED_BAM}" \
    M="${TRIAL_DUP_METRICS}" \
    CREATE_INDEX=true \
    READ_NAME_REGEX=null \
    VALIDATION_STRINGENCY=LENIENT

  echo "[4/5] Creating alignment summary"
  "${SAMTOOLS_BIN}" flagstat "${TRIAL_PROCESSED_BAM}" > "${TRIAL_FLAGSTAT}"

  echo "[5/5] Verifying outputs"
  test -s "${TRIAL_PROCESSED_BAM}"
  test -s "${TRIAL_DUP_METRICS}"
  test -s "${TRIAL_FLAGSTAT}"

  echo "======================================================================"
  echo " STAGE 2 MINI TRIAL COMPLETE"
  echo " Processed BAM: ${TRIAL_PROCESSED_BAM}"
  echo " Flagstat: ${TRIAL_FLAGSTAT}"
  echo " Log: ${TRIAL_LOG}"
  echo "======================================================================"
} 2>&1 | tee "${TRIAL_LOG}"
