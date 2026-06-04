#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

PROBE_DIR="${TMP_DIR}/stage2_bwa_probe"
mkdir -p "${PROBE_DIR}"

for range in "3001 3500" "3501 4000" "3001 3250" "3251 3500" "3501 3750" "3751 4000"; do
  set -- ${range}
  start="$1"
  end="$2"

  ./probe_stage2_bwa_ranges.py "${start}" "${end}" >/dev/null

  sam="${PROBE_DIR}/${start}_${end}.sam"
  err="${PROBE_DIR}/${start}_${end}.err"

  set +e
  timeout 180 "${BWA_MEM2_BIN}" mem -t 1 -R "${READ_GROUP}" "${REF_FA}" \
    "${PROBE_DIR}/R1_${start}_${end}.fq.gz" \
    "${PROBE_DIR}/R2_${start}_${end}.fq.gz" \
    > "${sam}" 2> "${err}"
  rc="$?"
  set -e

  printf 'RANGE=%s-%s EXIT=%s SIZE=%s\n' "${start}" "${end}" "${rc}" "$(stat -c %s "${sam}")"
  tail -n 6 "${err}"
done
