#!/bin/bash
set -euo pipefail

SOURCE_R1="/mnt/d/DNA/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq"
SOURCE_R1_GZ="/mnt/d/DNA/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq.gz"
SOURCE_R2="/mnt/d/DNA/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq"
TARGET_DIR="/home/rayzw/DNA/hg38/raw_uncompressed"
TARGET_R1="${TARGET_DIR}/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq"
TARGET_R2="${TARGET_DIR}/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq"

copy_if_needed() {
  local source_file="$1"
  local target_file="$2"
  local label="$3"
  local source_size
  local target_size

  source_size="$(stat -c '%s' "${source_file}")"
  if [ -f "${target_file}" ]; then
    target_size="$(stat -c '%s' "${target_file}")"
    if [ "${source_size}" = "${target_size}" ]; then
      echo "[OK] ${label} already exists locally with matching byte size: ${target_file}"
      return
    fi
    echo "[WARN] ${label} local file exists but size differs; replacing it."
    rm -f "${target_file}"
  fi

  echo "[COPY] ${label}"
  echo "       From: ${source_file}"
  echo "       To:   ${target_file}"
  if command -v rsync >/dev/null 2>&1; then
    rsync --info=progress2 --human-readable "${source_file}" "${target_file}"
  else
    cp "${source_file}" "${target_file}"
  fi

  target_size="$(stat -c '%s' "${target_file}")"
  if [ "${source_size}" != "${target_size}" ]; then
    echo "[ERROR] ${label} size mismatch after copy."
    echo "        Source bytes: ${source_size}"
    echo "        Target bytes: ${target_size}"
    exit 1
  fi
  echo "[OK] ${label} copied with matching byte size."
}

decompress_if_needed() {
  local source_gz="$1"
  local target_file="$2"
  local label="$3"

  if [ -f "${target_file}" ]; then
    echo "[OK] ${label} already exists locally: ${target_file}"
    return
  fi

  echo "[DECOMPRESS] ${label}"
  echo "             From: ${source_gz}"
  echo "             To:   ${target_file}"
  gzip -dc "${source_gz}" > "${target_file}.partial"
  mv "${target_file}.partial" "${target_file}"
  echo "[OK] ${label} decompressed into local uncompressed FASTQ."
}

echo "======================================================================"
echo " STAGE 1 LOCAL UNCOMPRESSED FASTQ PREP"
echo " Started: $(date)"
echo " Target directory: ${TARGET_DIR}"
echo "======================================================================"

mkdir -p "${TARGET_DIR}"

echo "[1/4] Confirming source FASTQs exist"
if [ ! -r "${SOURCE_R1}" ]; then
  echo "[WARN] Uncompressed R1 source was not found; will create it from the R1 .fq.gz file."
  test -r "${SOURCE_R1_GZ}"
else
  test -r "${SOURCE_R1}"
fi
test -r "${SOURCE_R2}"

echo "[2/4] Checking available WSL storage"
df -h /home/rayzw

echo "[3/4] Copying R1/R2 into native WSL storage if needed"
if [ -r "${SOURCE_R1}" ]; then
  copy_if_needed "${SOURCE_R1}" "${TARGET_R1}" "R1 uncompressed FASTQ"
else
  decompress_if_needed "${SOURCE_R1_GZ}" "${TARGET_R1}" "R1 uncompressed FASTQ"
fi
copy_if_needed "${SOURCE_R2}" "${TARGET_R2}" "R2 uncompressed FASTQ"

echo "[4/4] Sampling copied files for FASTQ structure and base qualities"
cd "$(dirname "${BASH_SOURCE[0]}")"
python3 ./check_uncompressed_fastq_quality.py "${TARGET_R1}" 1000000
python3 ./check_uncompressed_fastq_quality.py "${TARGET_R2}" 1000000

echo "======================================================================"
echo " STAGE 1 LOCAL UNCOMPRESSED FASTQ PREP COMPLETE"
echo " Finished: $(date)"
echo " Local R1: ${TARGET_R1}"
echo " Local R2: ${TARGET_R2}"
echo "======================================================================"
