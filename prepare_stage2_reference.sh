#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

REF_URL="${REF_URL:-https://ftp.ensembl.org/pub/release-115/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz}"
REF_GZ="${REF_FA}.gz"

echo "======================================================================"
echo " STAGE 2 REFERENCE PREP"
echo " Target reference: ${REF_FA}"
echo " Source URL: ${REF_URL}"
echo "======================================================================"

mkdir -p "$(dirname "${REF_FA}")" "${LOGS_DIR}"

if [ ! -s "${REF_FA}" ]; then
  if [ ! -s "${REF_GZ}" ]; then
    echo "[1/5] Downloading reference FASTA gzip"
    curl -fL "${REF_URL}" -o "${REF_GZ}"
  else
    echo "[1/5] Reference gzip already exists: ${REF_GZ}"
  fi

  echo "[2/5] Decompressing reference FASTA"
  gzip -dc "${REF_GZ}" > "${REF_FA}"
else
  echo "[1/5] Reference FASTA already exists: ${REF_FA}"
  echo "[2/5] Skipping decompression"
fi

echo "[3/5] Verifying numeric/no-chr contig naming"
first_contig="$(grep -m 1 '^>' "${REF_FA}" | sed 's/^>//' | awk '{print $1}')"
if [[ "${first_contig}" == chr* ]]; then
  echo "[FAIL] Reference starts with '${first_contig}', but this pipeline expects numeric/no-chr contigs."
  exit 1
fi
echo "[PASS] First contig is '${first_contig}'"

echo "[4/5] Creating samtools FASTA index"
"${SAMTOOLS_BIN}" faidx "${REF_FA}"

echo "[5/5] Creating bwa-mem2 index"
"${BWA_MEM2_BIN}" index "${REF_FA}" > "${LOGS_DIR}/bwa_mem2_reference_index.log" 2>&1

echo "======================================================================"
echo " STAGE 2 REFERENCE PREP COMPLETE"
echo " Reference: ${REF_FA}"
echo " FASTA index: ${REF_FA}.fai"
echo " BWA index log: ${LOGS_DIR}/bwa_mem2_reference_index.log"
echo "======================================================================"

