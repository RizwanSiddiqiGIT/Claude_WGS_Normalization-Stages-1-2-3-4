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
- Follow-up: The preflight now reports this as "Docker daemon not reachable" rather than incorrectly implying the DeepVariant image is missing.

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

### Stage 1 needs a tiny end-to-end test before real FASTQs

- Symptom: After reinstall, production FASTQ paths may be missing even when Stage 1 software is installed.
- Fix applied: Added `launch_stage1_smoke_test.sh`.
- Behavior: Creates tiny synthetic paired FASTQs under `/home/rayzw/DNA/hg38/tmp/stage1_smoke_test`, then runs FastQC, fastp, FastQC again on trimmed reads, and MultiQC.
- Purpose: Verifies all Stage 1 software without touching real WGS input data.
- Latest result: Passed end-to-end with 100 synthetic read pairs retained after fastp.
- Bug found and fixed: Initial synthetic FASTQ generator had sequence/quality length mismatch, which fastp correctly rejected. The generator now derives quality string length from sequence length.

### Stage 1 final FASTQ corruption after direct writes

- Symptom: Stage 2 failed with `gzread ... incorrect data check`; repeated `gzip -t` checks showed final trimmed FASTQs were not trustworthy.
- Raw FASTQ gzip checks passed, so the issue was in the generated Stage 1 outputs, not the source FASTQs.
- Fix applied: Recreated `stage1_qc_preprocess.sh` so final FASTQs are never written directly. The script now writes paired fastp outputs into a run-specific temp directory, runs full `gzip -t` checks on both temp FASTQs, backs up old finals, then promotes verified files into the final paths.
- Stage 1 now records run-specific fastp reports and symlinks `fastp.html` / `fastp.json` to the latest report.
- Use `check_stage1_trimmed_integrity.sh` for sequential integrity checks before Stage 2.
- `config.env` now supports environment overrides for input/output paths so smoke tests can execute the production Stage 1 script on synthetic FASTQs without touching real data.
- The Google Doc context for MGI DNBSEQ-T7 recommends `PL:ILLUMINA` in read-group metadata for downstream GATK compatibility. `config.env` now defaults Stage 2 `READ_GROUP` to `PL:ILLUMINA` while keeping DNB library naming in `LB`.
- If the user explicitly chooses to proceed despite raw `.fq.gz` CRC-check failures, use `ASSUME_RAW_FASTQ_VALID=1` or `run_stage1_real_assume_fastq_valid.sh`. This skips only the raw-input gzip gate; Stage 1 must still validate generated trimmed FASTQs before promotion.
- When using the uncompressed FASTQs extracted from the problematic gzip archives, launch Stage 1 with `run_stage1_real_uncompressed_fastq.sh`. The uncompressed files live inside same-named folders on `/mnt/d/DNA`, and sampled/full-line-count checks showed both are structurally valid.
- Current safer path: use `prepare_stage1_uncompressed_fastq_local.sh` to stage uncompressed FASTQs into native WSL storage under `/home/rayzw/DNA/hg38/raw_uncompressed`, then run `run_stage1_real_uncompressed_fastq_local.sh`. This avoids heavy FastQC/fastp reads directly through `/mnt/d`.
- As of 2026-06-04, `/mnt/d/DNA` had uncompressed R2 as a `.fq` folder/file, but uncompressed R1 was absent. The local prep script therefore creates local uncompressed R1 from `/mnt/d/DNA/...25.1.fq.gz` when the uncompressed R1 folder is missing, then copies uncompressed R2 as-is.
- Avoid passing complex Linux expressions through PowerShell/WSL directly. Put logic into repo scripts and invoke them with `wsl -d Ubuntu --exec /path/to/script.sh`; otherwise PowerShell may consume pipes, redirects, quotes, parentheses, or heredocs before WSL sees them.
- Stage 1 FASTQ path is currently de-prioritized. The WSL-local uncompressed R1 failed FastQC with `SequenceFormatException: Midline ... didn't start with '+' at 478330863`, meaning R1 is structurally malformed. Do not use that R1 directly for fastp/alignment. If FASTQ recovery is ever needed, only use a pair-aware repair workflow that streams R1/R2 together, validates each 4-line record, drops malformed pairs from both files, writes synchronized repaired FASTQs, and logs all dropped pairs.
- Current active pivot: use the hg38 BAM copied into native WSL storage at `/home/rayzw/DNA-Linux/hg38/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.bam`. Initial `samtools quickcheck` passed. Header reports coordinate sort (`SO:coordinate`), numeric/no-`chr` GRCh38-style contigs, read group `SM:SQE38K22`, `PL:ILLUMINA`, alignment by `bwa-mem2`, sorting by `samtools`, and duplicate-marking provenance from `sambamba markdup`.
- Follow-up BAM indexing failed despite `samtools quickcheck` passing: `samtools index` reported `BGZF decode jobs returned error 1 for block offset 26584396449`. Treat this BAM as suspect/corrupted until a clean index can be produced from a verified source copy. `quickcheck` alone is not sufficient for this file.

### Static progress tracking

- Need: View stage progress in a browser without running a local server/port.
- Fix applied: Added `progress_tracker.py` and `launch_stage_progress_tracker.sh`.
- Behavior: Rewrites an HTML file every 60 seconds; the page includes a meta-refresh tag.
- Stage 1 page: `/home/rayzw/DNA/hg38/progress/stage1_progress.html`.
- The same pattern can be duplicated for Stage 2, Stage 3, and Stage 4 by changing log paths, watched output folders, expected files, and process patterns.

### Stage 2 reference convention

- Important: The older pipeline context requires numeric/no-`chr` chromosome names.
- The E: drive FASTA `/mnt/e/Health/Rizwan/Files/fasta/HG38/hg38_v0_Homo_sapiens_assembly38.fasta` was found, but its headers start with `chr1`, so it should not be used blindly for this numeric pipeline.
- Stage 2 production should use the Ensembl-style GRCh38 primary assembly reference at `/home/rayzw/DNA/ref_genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa`, with numeric contig names.
- Added `launch_stage2_smoke_test.sh` to validate `bwa-mem2`, `samtools`, and Picard with a tiny numeric-reference FASTA before the full reference is restored.
- Latest result: `launch_stage2_smoke_test.sh` passed end-to-end after adjusting for Picard's index naming. Picard writes `sample.bai` for `sample.bam`, not always `sample.bam.bai`.
- Added `prepare_stage2_reference.sh` to download Ensembl release 115 GRCh38 primary assembly, verify numeric/no-`chr` contigs, create `.fai`, and create the `bwa-mem2` index.
- Stage 2 mini-trial probing found `bwa-mem2` repeatedly stalls on real read pairs around 3751-4000, while classic `bwa mem` aligns the same block successfully. Production Stage 2 now uses classic `bwa mem`; keep `bwa-mem2` installed for reference/smoke testing but do not use it for this production sample unless the issue is resolved.
- Stage 2 Picard MarkDuplicates uses `READ_NAME_REGEX=null` because the MGI-style read names do not match Picard's optical duplicate parser. This avoids noisy parser warnings; duplicate marking still runs, but optical duplicate detection is not inferred from tile/x/y coordinates.

## Current Software Status

As of the latest software preflight after reinstall:

- `fastqc`: installed
- `multiqc`: installed
- `fastp`: installed
- `bwa-mem2`: installed
- `bwa`: installed
- `parallel`: installed
- `samtools`: installed
- `bcftools`: installed
- `tabix`: installed
- `java`: installed
- `picard.jar`: `/home/rayzw/tools/picard/picard.jar`
- `docker.exe`: works if Docker Desktop is running
- `google/deepvariant:1.6.0`: pulled locally

## Git Hygiene Rule

- Whenever code, config, scripts, or context files are changed, update local git and the remote GitHub repo after verification. Prefer a focused commit message describing the pipeline decision/change, then push to `main` unless the user has asked for a branch. Do not leave important operational fixes only in the local worktree.
- For any command or pipeline step expected to run longer than 5 minutes, include status-update support: either launch/update the relevant progress HTML tracker, write to a clear latest-log symlink, or provide periodic status checks with command/log paths. Long-running jobs should not be left silent.

## Notes To Add Later

- Exact reference FASTA source path once copied into `/home/rayzw/DNA/ref_genome`.
- Whether Docker Desktop WSL integration gets enabled, which would allow switching `DOCKER_BIN` back to `docker`.

## Data Location Notes

- Real FASTQ files are stored on Windows `D:\DNA`, visible inside WSL as `/mnt/d/DNA`.
- Current paired FASTQs:
  - `/mnt/d/DNA/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq.gz`
  - `/mnt/d/DNA/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq.gz`
- For production, prefer copying or staging active working files into native WSL storage under `/home/rayzw/DNA` before heavy repeated processing, unless space constraints require reading from `/mnt/d/DNA`.

## Reference Strategy Notes

- For rebuilding BAMs from fresh FASTQs, prefer the NCBI GRCh38 full-plus-decoy analysis reference:
  `/home/rayzw/DNA/ref_genome/GRCh38_full_plus_hs38d1/GCA_000001405.15_GRCh38_full_plus_hs38d1_analysis_set.fna`.
- Source download location used locally:
  `/mnt/d/DNA/fai/GCA_000001405.15_GRCh38_full_plus_hs38d1_analysis_set.fna.gz`.
- This reference has `chr`-prefixed names, includes `chrM`, `chrEBV`, ALT/random/unplaced contigs, and hs38d1 decoys. It was the closest match to the sequencing.com BAM dictionary after `chr` normalization.
- Keep downstream contig-name translation as a VCF-stage concern if needed; do not custom-rename the alignment reference unless a specific downstream tool requires it.
