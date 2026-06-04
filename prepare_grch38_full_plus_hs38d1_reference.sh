#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

SOURCE_GZ="${SOURCE_GZ:-/mnt/d/DNA/fai/GCA_000001405.15_GRCh38_full_plus_hs38d1_analysis_set.fna.gz}"
SOURCE_FAI="${SOURCE_FAI:-/mnt/d/DNA/fai/GCA_000001405.15_GRCh38_full_plus_hs38d1_analysis_set.fna.fai}"
TARGET_DIR="${DNA_ROOT}/ref_genome/GRCh38_full_plus_hs38d1"
TARGET_GZ="${TARGET_DIR}/GCA_000001405.15_GRCh38_full_plus_hs38d1_analysis_set.fna.gz"
TARGET_FA="${TARGET_DIR}/GCA_000001405.15_GRCh38_full_plus_hs38d1_analysis_set.fna"
TARGET_DICT="${TARGET_FA%.fna}.dict"
LOG="${LOGS_DIR}/prepare_grch38_full_plus_hs38d1_$(date +%Y%m%d_%H%M%S).log"

mkdir -p "${TARGET_DIR}" "${LOGS_DIR}"

{
  echo "======================================================================"
  echo " GRCh38 FULL PLUS HS38D1 REFERENCE PREP"
  echo " Started: $(date)"
  echo " Source gzip: ${SOURCE_GZ}"
  echo " Target FASTA: ${TARGET_FA}"
  echo "======================================================================"

  echo "[1/8] Verifying source gzip exists and passes gzip integrity"
  test -s "${SOURCE_GZ}"
  gzip -t "${SOURCE_GZ}"

  echo "[2/8] Copying gzip into native WSL reference directory"
  if [ ! -s "${TARGET_GZ}" ]; then
    cp "${SOURCE_GZ}" "${TARGET_GZ}.tmp"
    mv "${TARGET_GZ}.tmp" "${TARGET_GZ}"
  else
    echo "[INFO] Target gzip already exists: ${TARGET_GZ}"
  fi
  gzip -t "${TARGET_GZ}"

  echo "[3/8] Decompressing FASTA if needed"
  if [ ! -s "${TARGET_FA}" ]; then
    gzip -cd "${TARGET_GZ}" > "${TARGET_FA}.tmp"
    mv "${TARGET_FA}.tmp" "${TARGET_FA}"
  else
    echo "[INFO] Target FASTA already exists: ${TARGET_FA}"
  fi

  echo "[4/8] Creating samtools FASTA index"
  "${SAMTOOLS_BIN}" faidx "${TARGET_FA}"

  echo "[5/8] Comparing native .fai to downloaded .fai"
  if [ -s "${SOURCE_FAI}" ]; then
    cmp -s "${SOURCE_FAI}" "${TARGET_FA}.fai"
    echo "[PASS] Native .fai matches downloaded .fai"
  else
    echo "[WARN] Source .fai not found, skipping cmp: ${SOURCE_FAI}"
  fi

  echo "[6/8] Creating Picard/GATK sequence dictionary"
  if [ ! -s "${TARGET_DICT}" ]; then
    "${JAVA_BIN}" -jar "${PICARD_JAR}" CreateSequenceDictionary \
      R="${TARGET_FA}" \
      O="${TARGET_DICT}"
  else
    echo "[INFO] Picard/GATK sequence dictionary already exists: ${TARGET_DICT}"
  fi

  echo "[7/8] Creating classic bwa index"
  if [ ! -s "${TARGET_FA}.bwt" ] || [ ! -s "${TARGET_FA}.sa" ]; then
    "${BWA_BIN}" index "${TARGET_FA}"
  else
    echo "[INFO] Classic bwa index already exists for: ${TARGET_FA}"
  fi

  echo "[8/8] Creating bwa-mem2 index"
  if [ ! -s "${TARGET_FA}.bwt.2bit.64" ] || [ ! -s "${TARGET_FA}.0123" ]; then
    "${BWA_MEM2_BIN}" index "${TARGET_FA}"
  else
    echo "[INFO] bwa-mem2 index already exists for: ${TARGET_FA}"
  fi

  echo "======================================================================"
  echo " GRCh38 FULL PLUS HS38D1 REFERENCE PREP COMPLETE"
  echo " Finished: $(date)"
  echo " FASTA: ${TARGET_FA}"
  echo " FAI: ${TARGET_FA}.fai"
  echo " DICT: ${TARGET_DICT}"
  echo " Log: ${LOG}"
  echo "======================================================================"
} 2>&1 | tee "${LOG}"
