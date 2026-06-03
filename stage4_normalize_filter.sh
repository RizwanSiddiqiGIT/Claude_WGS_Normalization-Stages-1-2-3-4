#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

mkdir -p "${VARIANTS_DIR}" "${LOGS_DIR}"

echo "[STAGE 4] VCF normalization and filtering"

if [ ! -s "${REF_FA}.fai" ]; then
  echo "[INFO] Creating FASTA index: ${REF_FA}.fai"
  "${SAMTOOLS_BIN}" faidx "${REF_FA}"
fi

"${BCFTOOLS_BIN}" norm \
  -f "${REF_FA}" \
  -m -both \
  "${RAW_VCF}" \
  -O z \
  -o "${NORM_VCF}"

"${TABIX_BIN}" -f -p vcf "${NORM_VCF}"

"${BCFTOOLS_BIN}" filter \
  -i 'FILTER="PASS" && (TYPE="snp" || TYPE="indel")' \
  -s LowQual \
  "${NORM_VCF}" \
  -O z \
  -o "${FILTERED_VCF}"

"${TABIX_BIN}" -f -p vcf "${FILTERED_VCF}"

echo "[STAGE 4 COMPLETE] ${FILTERED_VCF}"

