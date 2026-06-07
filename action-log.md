# Pipeline Action Log

---

## 2026-06-06

### Repo forked and renamed
- Forked `RizwanSiddiqiGIT/WGS_Normalization-Stages-1-2-3-4` into `RizwanSiddiqiGIT/Claude_WGS_Normalization-Stages-1-2-3-4` via GitHub API (same-account fork workaround: cloned original, repointed remote, pushed to new repo).

### Pipeline state audit
- BAM at `/home/rayzw/DNA-Linux/hg38/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.bam` failed `samtools index` with CRC32 mismatch at offset 29,541,646,138 — corrupted during prior WSL transfer.
- FASTQ R1 and R2 copies in `/home/rayzw/DNA-Linux/hg38/` also failed `bgzip -t` at ~6 GB — same root cause (Windows to WSL copy corruption via /mnt/ bridge).
- D: drive originals (`/mnt/d/DNA/`) verified intact via `bgzip -t`: R1 OK, R2 OK.
- D: drive `sorted_hg38.bam` passes `samtools quickcheck` but is a different sample (Rizwan, chr-prefixed ref) — not suitable for this pipeline.

### Config path fix
- Corrected `REF_FA` in `config_bam_input.env`: was `/home/rayzw/DNA/ref_genome/` — changed to `/home/rayzw/DNA-Linux/ref_genome/` (actual location of reference FASTA).

### Deleted corrupted WSL FASTQ copies
- Removed `/home/rayzw/DNA-Linux/hg38/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq.gz` (corrupted at ~6 GB)
- Removed `/home/rayzw/DNA-Linux/hg38/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq.gz` (corrupted at ~6 GB)
- Source files on D: drive confirmed clean before deletion.

### WSL /mnt/ bridge corruption identified
- `rsync --checksum` from `/mnt/d/DNA/` to `/home/rayzw/DNA-Linux/hg38/` produced a corrupt R1 copy at offset 1,631,281,920 — consistent across multiple attempts.
- Root cause: WSL VirtioFS `/mnt/d/` bridge silently corrupts data during large sequential reads.
- Fix: use PowerShell `Copy-Item "D:\..." "\\wsl.localhost\Ubuntu\..."` which bypasses the bridge and writes via native Windows file APIs directly to the WSL ext4 filesystem.
- R1 re-copied via `Copy-Item` — `bgzip -t` passed.
- R2 re-copied via `Copy-Item` — verification pending.

### Next step
- Verify R2 integrity after `Copy-Item` transfer, then proceed to Stage 1 (fastp QC/trimming).
