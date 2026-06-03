#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

mkdir -p "${VARIANTS_DIR}" "${LOGS_DIR}" "${TMP_DIR}"

echo "[STAGE 3] DeepVariant 1.6.0 variant calling"
echo "[STAGE 3a] make_examples with ${DEEPVARIANT_SHARDS} shards"

seq 0 "$((DEEPVARIANT_SHARDS - 1))" | "${PARALLEL_BIN}" -j "${DEEPVARIANT_SHARDS}" \
  "${DOCKER_BIN} run --rm \
    -v /home/rayzw/DNA:/home/rayzw/DNA \
    ${DEEPVARIANT_IMAGE} \
    /opt/deepvariant/bin/make_examples \
    --mode calling \
    --ref ${REF_FA} \
    --reads ${PROCESSED_BAM} \
    --examples ${MAKE_EXAMPLES_PATTERN} \
    --task {}"

echo "[STAGE 3b] call_variants"
"${DOCKER_BIN}" run --rm \
  --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility \
  -v /home/rayzw/DNA:/home/rayzw/DNA \
  "${DEEPVARIANT_IMAGE}" \
  /opt/deepvariant/bin/call_variants \
  --outfile "${CALLS_TFRECORD}" \
  --examples "${MAKE_EXAMPLES_PATTERN}" \
  --checkpoint /opt/deepvariant/models/deepvariant/1.6.0/DeepVariant-inception_v3-1.6.0+data-wgs_standard

echo "[STAGE 3c] postprocess_variants"
"${DOCKER_BIN}" run --rm \
  -v /home/rayzw/DNA:/home/rayzw/DNA \
  "${DEEPVARIANT_IMAGE}" \
  /opt/deepvariant/bin/postprocess_variants \
  --ref "${REF_FA}" \
  --infile "${CALLS_TFRECORD}" \
  --outfile "${RAW_VCF}" \
  --cpus="${DEEPVARIANT_CPUS}"

echo "[STAGE 3 COMPLETE] ${RAW_VCF}"

