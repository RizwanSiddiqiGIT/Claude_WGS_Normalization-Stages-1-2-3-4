#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

TEST_ROOT="${BASE_DIR}/tmp/stage2_smoke_test"
REF="${TEST_ROOT}/ref/stage2_numeric_test.fa"
READ_DIR="${TEST_ROOT}/reads"
OUT_DIR="${TEST_ROOT}/output"
LOG_DIR="${TEST_ROOT}/logs"

R1="${READ_DIR}/stage2_smoke_R1.fastq.gz"
R2="${READ_DIR}/stage2_smoke_R2.fastq.gz"
SORTED="${OUT_DIR}/stage2_smoke_sorted.bam"
PROCESSED="${OUT_DIR}/stage2_smoke_processed.bam"
PROCESSED_INDEX="${OUT_DIR}/stage2_smoke_processed.bai"
DUP_METRICS_TEST="${OUT_DIR}/stage2_smoke_dup_metrics.txt"
FLAGSTAT="${OUT_DIR}/stage2_smoke_processed.flagstat.txt"

echo "======================================================================"
echo " STAGE 2 SMOKE TEST"
echo " This creates a tiny numeric reference and synthetic paired reads."
echo " It runs bwa-mem2, samtools sort/index, Picard MarkDuplicates, and flagstat."
echo " Test root: ${TEST_ROOT}"
echo "======================================================================"

rm -rf "${TEST_ROOT}"
mkdir -p "$(dirname "${REF}")" "${READ_DIR}" "${OUT_DIR}" "${LOG_DIR}"

echo "[1/7] Creating tiny numeric-reference FASTA"
cat > "${REF}" <<'EOF'
>1
ACGTGATCGTACGTTAGCCTAGGCTAACGTACGATCGATCGTACCTAGGCTAAGCTTAGCTAGGATCCGTATGCATGCATGCATGCATGCATGCATGCATGCA
>2
TGCATGCATGCATGCATGCATGCATGCATGCATACGGATCCTAGCTAAGCTTAGCCTAGGTACGATCGATCGTACGTTAGCCTAGGCTAACGTACGATCACGT
EOF

echo "[2/7] Indexing tiny reference"
"${SAMTOOLS_BIN}" faidx "${REF}"
"${BWA_MEM2_BIN}" index "${REF}" > "${LOG_DIR}/bwa_index.log" 2>&1

echo "[3/7] Creating synthetic paired FASTQs"
read1_seq="ACGTGATCGTACGTTAGCCTAGGCTAACGTACGATCGATCGTACCTAGGCTAAGCTTAGCTAGGATCCGTA"
read2_seq="TACGGATCCTAGCTAAGCTTAGCCTAGGTACGATCGATCGTACGTTAGCCTAGGCTAACGTACGATCACGT"
read1_qual="$(printf '%*s' "${#read1_seq}" '' | tr ' ' 'I')"
read2_qual="$(printf '%*s' "${#read2_seq}" '' | tr ' ' 'I')"

{
  for i in $(seq 1 200); do
    printf '@stage2_smoke_%04d/1\n%s\n+\n%s\n' "${i}" "${read1_seq}" "${read1_qual}"
  done
} | gzip -c > "${R1}"

{
  for i in $(seq 1 200); do
    printf '@stage2_smoke_%04d/2\n%s\n+\n%s\n' "${i}" "${read2_seq}" "${read2_qual}"
  done
} | gzip -c > "${R2}"

echo "[4/7] Aligning with bwa-mem2 and sorting with samtools"
"${BWA_MEM2_BIN}" mem \
  -t 4 \
  -R "${READ_GROUP}" \
  "${REF}" \
  "${R1}" \
  "${R2}" \
  2> "${LOG_DIR}/bwa_mem.log" \
  | "${SAMTOOLS_BIN}" sort -@ 2 -o "${SORTED}"

"${SAMTOOLS_BIN}" index "${SORTED}"

echo "[5/7] Running Picard MarkDuplicates"
"${JAVA_BIN}" -Xmx2g -jar "${PICARD_JAR}" MarkDuplicates \
  I="${SORTED}" \
  O="${PROCESSED}" \
  M="${DUP_METRICS_TEST}" \
  CREATE_INDEX=true \
  VALIDATION_STRINGENCY=LENIENT \
  > "${LOG_DIR}/picard_markduplicates.log" 2>&1

echo "[6/7] Running samtools flagstat"
"${SAMTOOLS_BIN}" flagstat "${PROCESSED}" > "${FLAGSTAT}"

echo "[7/7] Verifying expected outputs"
for output in \
  "${REF}" \
  "${REF}.fai" \
  "${R1}" \
  "${R2}" \
  "${SORTED}" \
  "${SORTED}.bai" \
  "${PROCESSED}" \
  "${PROCESSED_INDEX}" \
  "${DUP_METRICS_TEST}" \
  "${FLAGSTAT}"; do
  if [ ! -s "${output}" ]; then
    echo "[FAIL] Missing expected output: ${output}"
    exit 1
  fi
  echo "[PASS] ${output}"
done

echo "======================================================================"
echo " STAGE 2 SMOKE TEST COMPLETE"
echo " Processed BAM: ${PROCESSED}"
echo " Flagstat: ${FLAGSTAT}"
echo " Logs: ${LOG_DIR}"
echo "======================================================================"
