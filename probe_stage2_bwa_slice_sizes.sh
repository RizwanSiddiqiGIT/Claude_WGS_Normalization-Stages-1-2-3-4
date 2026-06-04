#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

PROBE_DIR="${TMP_DIR}/stage2_bwa_probe"
mkdir -p "${PROBE_DIR}"

for n in 3000 4000 5000 7500 10000; do
  lines=$((n * 4))
  r1="${PROBE_DIR}/R1_${n}.fq.gz"
  r2="${PROBE_DIR}/R2_${n}.fq.gz"
  sam="${PROBE_DIR}/${n}.sam"
  err="${PROBE_DIR}/${n}.err"

  set +o pipefail
  gzip -cd "${TRIMMED_FASTQ_R1}" | head -n "${lines}" | gzip -c > "${r1}"
  gzip -cd "${TRIMMED_FASTQ_R2}" | head -n "${lines}" | gzip -c > "${r2}"
  set -o pipefail

  start="$(date +%s)"
  set +e
  timeout 180 "${BWA_MEM2_BIN}" mem -t 1 -R "${READ_GROUP}" "${REF_FA}" "${r1}" "${r2}" > "${sam}" 2> "${err}"
  rc="$?"
  set -e
  end="$(date +%s)"

  printf 'N=%s EXIT=%s SECONDS=%s SAM_SIZE=%s\n' "${n}" "${rc}" "$((end - start))" "$(stat -c %s "${sam}")"
  tail -n 8 "${err}"
done
