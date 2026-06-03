# Local Operational Context

Consult this file before changing scripts, installing tools, or running the stages 1-4 WGS normalization pipeline. Add a short entry whenever a new issue is found and fixed, so the same pathway is not repeated.

## Current Host Profile

- Host: Windows 11 Pro with WSL2.
- Current WSL distro observed by `lsb_release`: Ubuntu 26.04 LTS, codename `resolute`.
- Historical pipeline docs mention Ubuntu 24.04 LTS; treat that as prior context, not current package baseline.
- Kernel observed: Microsoft WSL2 kernel.
- CPU: AMD Ryzen 9 5900X, 12 physical cores / 24 threads.
- RAM: 128 GB according to prior pipeline context.
- GPU: NVIDIA GeForce RTX 3080 Ti, 12 GB VRAM according to prior pipeline context.
- DeepVariant image: `google/deepvariant:1.6.0`.
- Active repo path: `/home/rayzw/WGS_Normalization-Stages-1-2-3-4`.
- Active data workspace: `/home/rayzw/DNA`.

## Core Decision Rules

- Keep active pipeline data on native WSL/Linux paths under `/home/rayzw/DNA`.
- Avoid `/mnt/c` for heavy genomics work.
- Use `/mnt/d` only for large fast NVMe-backed source data when it cannot fit under native WSL.
- Avoid slow external drives for random-access annotation or staging.
- Chromosomes are numeric/no-prefix: `1`, `2`, `17`, `X`, `Y`, `M`; never `chr1`, `chrX`, or `chrM`.
- Use hardcoded absolute paths inside Docker command strings where path interpolation can be fragile.
- For DeepVariant 1.6.0, call direct binaries: `make_examples`, `call_variants`, and `postprocess_variants`.
- For 24-shard DeepVariant make_examples, use `make_examples.tfrecord@24.gz` plus `seq 0 23 | parallel -j 24`.
- Pre-create output directories before Docker runs.

## Stage Boundary

This repo owns stages 1-4:

1. FASTQ QC/preprocessing
2. Alignment and duplicate marking
3. DeepVariant calling
4. VCF normalization/filtering

The downstream annotation/panel repo starts at Stage 5 and consumes:

```text
/home/rayzw/DNA/hg38/variants_output/Rizwan_filtered.vcf.gz
/home/rayzw/DNA/hg38/variants_output/Rizwan_filtered.vcf.gz.tbi
```

## Known Issues And Fixes

### PowerShell/WSL quoting drift

- Symptom: Linux shell constructs such as `&&`, awk expressions, and nested quotes are intercepted by PowerShell before WSL receives them.
- Fix: Prefer checked-in scripts. For one-off commands from Codex, use simple `wsl -d Ubuntu --exec ...` calls and avoid complex nested quoting where possible.

### Root password blocks automated installs

- Symptom: `sudo apt install` prompts for a password and blocks automation.
- Fix: Use root WSL execution for package installs:

```powershell
wsl -d Ubuntu -u root --exec bash -c 'DEBIAN_FRONTEND=noninteractive apt-get install -y <packages>'
```

- Return to normal user `rayzw` for repo edits and pipeline work.

### Root-owned files after UNC edits

- Symptom: Files edited through `\\wsl.localhost\Ubuntu\...` can become root-owned.
- Fix: After UNC/apply-patch edits, repair ownership:

```powershell
wsl -d Ubuntu -u root --exec chown -R rayzw:rayzw /home/rayzw/WGS_Normalization-Stages-1-2-3-4
```

### Docker command mismatch

- Symptom: `command -v docker` may show a Windows Docker path, but running `docker` in WSL prints that Docker is not found in the distro.
- Root cause: Docker Desktop WSL integration is not exposing a native `docker` command in Ubuntu.
- Fix applied: Start Docker Desktop, then use `docker.exe` from WSL. `config.env` sets `DOCKER_BIN=docker.exe`.
- Verification:

```bash
docker.exe version
docker.exe image inspect google/deepvariant:1.6.0
```

### Docker daemon not running

- Symptom: `docker.exe version` reports the client but cannot connect to `npipe:////./pipe/docker_engine`.
- Fix applied: Start Docker Desktop from Windows, then retry from WSL.

### Missing stages 1-4 software after reinstall

- Symptom: software preflight failed for `fastqc`, `multiqc`, `fastp`, `bwa-mem2`, `parallel`, and Picard jar.
- Fix applied:

```powershell
wsl -d Ubuntu -u root --exec bash -c 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y fastqc multiqc fastp bwa-mem2 parallel'
```

Picard:

```bash
mkdir -p /home/rayzw/tools/picard
cd /home/rayzw/tools/picard
curl -fL https://github.com/broadinstitute/picard/releases/download/3.4.0/picard.jar -o picard.jar
```

### DeepVariant image missing

- Symptom: software preflight warned that `google/deepvariant:1.6.0` was not present locally.
- Fix applied:

```bash
docker.exe pull google/deepvariant:1.6.0
```

## Current Software Status

As of the latest software preflight after reinstall:

- `fastqc`: installed
- `multiqc`: installed
- `fastp`: installed
- `bwa-mem2`: installed
- `parallel`: installed
- `samtools`: installed
- `bcftools`: installed
- `tabix`: installed
- `java`: installed
- `picard.jar`: `/home/rayzw/tools/picard/picard.jar`
- `docker.exe`: works if Docker Desktop is running
- `google/deepvariant:1.6.0`: pulled locally

## Notes To Add Later

- Exact FASTQ source paths once restored.
- Exact reference FASTA source path once copied into `/home/rayzw/DNA/ref_genome`.
- Whether Docker Desktop WSL integration gets enabled, which would allow switching `DOCKER_BIN` back to `docker`.

