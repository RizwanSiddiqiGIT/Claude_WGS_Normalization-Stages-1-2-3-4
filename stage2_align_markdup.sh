#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

mkdir -p "${BASE_DIR}" "${LOGS_DIR}" "${TMP_DIR}"

echo "[STAGE 2] Alignment and duplicate marking"

if [ ! -s "${REF_FA}.fai" ]; then
  echo "[INFO] Creating FASTA index: ${REF_FA}.fai"
  "${SAMTOOLS_BIN}" faidx "${REF_FA}"
fi

"${BWA_MEM2_BIN}" mem \
  -t "${THREADS}" \
  -R "${READ_GROUP}" \
  "${REF_FA}" \
  "${TRIMMED_FASTQ_R1}" \
  "${TRIMMED_FASTQ_R2}" \
  | "${SAMTOOLS_BIN}" sort -@ "${SORT_THREADS}" -o "${SORTED_BAM}"

"${JAVA_BIN}" -Xmx64g -jar "${PICARD_JAR}" MarkDuplicates \
  I="${SORTED_BAM}" \
  O="${PROCESSED_BAM}" \
  M="${DUP_METRICS}" \
  CREATE_INDEX=true \
  VALIDATION_STRINGENCY=LENIENT

"${SAMTOOLS_BIN}" flagstat "${PROCESSED_BAM}" > "${LOGS_DIR}/Rizwan_processed.flagstat.txt"

echo "[STAGE 2 COMPLETE] ${PROCESSED_BAM}"

