#!/bin/bash
set -u

cd "$(dirname "${BASH_SOURCE[0]}")"
source ./config.env

PASS=0
FAIL=0
WARN=0

pass() { echo "[PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN + 1)); }

check_command() {
  local name="$1"
  local required="$2"
  local path
  path="$(command -v "${name}" 2>/dev/null || true)"
  if [ -n "${path}" ]; then
    pass "command ${name}: ${path}"
  elif [ "${required}" = "required" ]; then
    fail "command ${name}: missing"
  else
    warn "optional command ${name}: missing"
  fi
}

check_executable() {
  local label="$1"
  local path="$2"
  if [ -x "${path}" ]; then
    pass "${label}: ${path}"
  else
    fail "${label}: missing or not executable at ${path}"
  fi
}

echo "======================================================================"
echo " WGS NORMALIZATION STAGES 1-4 SOFTWARE PREFLIGHT"
echo "======================================================================"

check_command "${FASTQC_BIN}" required
check_command "${MULTIQC_BIN}" required
check_command "${FASTP_BIN}" required
check_command "${BWA_MEM2_BIN}" required
check_command "${PARALLEL_BIN}" required
check_command "${DOCKER_BIN}" required
check_executable "samtools" "${SAMTOOLS_BIN}"
check_executable "bcftools" "${BCFTOOLS_BIN}"
check_executable "tabix" "${TABIX_BIN}"
check_executable "java" "${JAVA_BIN}"

if [ -s "${PICARD_JAR}" ]; then
  pass "Picard jar: ${PICARD_JAR}"
else
  fail "Picard jar missing: ${PICARD_JAR}"
fi

if "${DOCKER_BIN}" version >/dev/null 2>&1; then
  pass "Docker daemon reachable via ${DOCKER_BIN}"
  if "${DOCKER_BIN}" image inspect "${DEEPVARIANT_IMAGE}" >/dev/null 2>&1; then
    pass "Docker image present: ${DEEPVARIANT_IMAGE}"
  else
    warn "Docker image not present locally: ${DEEPVARIANT_IMAGE}"
  fi
else
  warn "Docker daemon not reachable via ${DOCKER_BIN}; start Docker Desktop before Stage 3"
fi

if bash -n ./*.sh >/dev/null 2>&1; then
  pass "all shell scripts parse"
else
  fail "one or more shell scripts fail bash -n"
fi

echo "======================================================================"
echo " SUMMARY: pass=${PASS} warn=${WARN} fail=${FAIL}"
echo "======================================================================"

[ "${FAIL}" -eq 0 ]
