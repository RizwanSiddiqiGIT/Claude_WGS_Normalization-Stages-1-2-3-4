# Pipeline Action Log

---

## 2026-06-06

### Repo forked and renamed
- Forked `RizwanSiddiqiGIT/WGS_Normalization-Stages-1-2-3-4` into `RizwanSiddiqiGIT/Claude_WGS_Normalization-Stages-1-2-3-4` via GitHub API (same-account fork workaround: cloned original, repointed remote, pushed to new repo).

### Pipeline state audit
- BAM at `/home/rayzw/DNA-Linux/hg38/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.bam` failed `samtools index` with CRC32 mismatch at offset 29,541,646,138 — corrupted during prior WSL transfer.
- FASTQ R1 and R2 copies in `/home/rayzw/DNA-Linux/hg38/` also failed `bgzip -t` at ~6 GB — same root cause (Windows to WSL copy corruption).
- D: drive originals (`/mnt/d/DNA/`) verified intact via `bgzip -t`: R1 OK, R2 OK.
- D: drive `sorted_hg38.bam` passes `samtools quickcheck` but is a different sample (Rizwan, chr-prefixed ref) — not suitable for this pipeline.

### Config path fix
- Corrected `REF_FA` in `config_bam_input.env`: was `/home/rayzw/DNA/ref_genome/` — changed to `/home/rayzw/DNA-Linux/ref_genome/` (actual location of reference FASTA).

### Deleted corrupted WSL FASTQ copies
- Removed `/home/rayzw/DNA-Linux/hg38/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.1.fq.gz` (corrupted at ~6 GB)
- Removed `/home/rayzw/DNA-Linux/hg38/MuhammadSiddiqi-SQE38K22-30x-WGS-Sequencing_com-12-04-25.2.fq.gz` (corrupted at ~6 GB)
- Source files on D: drive confirmed clean before deletion.

### Next step
- Re-copy FASTQs from `/mnt/d/DNA/` to `/home/rayzw/DNA-Linux/hg38/` using `rsync --checksum` to prevent silent corruption on transfer.
