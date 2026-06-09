# Project Paths & Repository Structure

Quick reference for all critical paths across Windows, Claude Code, and WSL environments.

---

## Claude Code Storage (Windows)

### Memory & Issue Tracking (Obsidian Vault)
```
C:\Users\rayzw\.claude\projects\G--My-Drive-Coding-Claude\memory\
├── MEMORY.md                          ← Auto-memory (persists across sessions)
├── ISSUE_LOG.md                       ← Structured issue log (ISSUE-001 through ISSUE-012+)
├── PROJECT_PATHS.md                   ← This file
├── Obsidian\
│   └── Obsidian.exe                   ← Obsidian desktop app executable
└── Templates\
    └── Issue-Template.md              ← Template for new issues (Ctrl+T in Obsidian)
```

**How to access:**
- **Obsidian (recommended):** Launch `C:\Users\rayzw\.claude\projects\G--My-Drive-Coding-Claude\memory\Obsidian\Obsidian.exe` — vault is pre-configured to this directory
- Memory updates automatically in Claude Code
- Issue tracking: Add new entries to `ISSUE_LOG.md` — use `Ctrl+T → Issue-Template` in Obsidian for pre-structured entry

### Project Metadata & Configuration
```
C:\Users\rayzw\.claude\projects\G--My-Drive-Coding-Claude\
├── .claude/
│   ├── settings.json                  ← Project-level settings
│   ├── keybindings.json               ← Custom key bindings
│   └── plans/                         ← Saved plan mode documents
├── memory/                            ← (see above)
└── 06adf67b-8daa-4ab7-98a8-694fe1-efa.jsonl (session transcript)
```

---

## Working Directory (Windows)

```
G:\My Drive\Coding\Claude\             ← Primary working directory
├── CLAUDE.md                          ← Project context & instructions
├── README.md                          ← Project overview
└── (this directory triggers WSL path translation errors due to spaces)
```

⚠️ **Note:** Avoid running WSL commands from this directory. Change to `C:\Temp\` or similar for WSL invocations.

---

## Pipeline Data & Code (WSL)

### Primary Pipeline Root
```
/home/rayzw/DNA-Linux/hg38/            ← MAIN PIPELINE DIRECTORY
├── Rizwan_processed.bam               (58G, Stage 2 output)
├── Rizwan_processed.bam.bai           (8.7M index)
├── Rizwan_processed.bam.checksums     (integrity verification)
├── Rizwan_sorted.bam                  (55G, Stage 1 output, intermediate)
├── Rizwan_sorted.bam.bai              (Stage 1 index)
│
├── dup_metrics.txt                    (Picard MarkDuplicates output)
│   └── KEY METRICS: 351.3M read pairs, 1.34% duplication (PCR-free)
│
├── variants_test/                     (Stage 3 validation runs)
│   ├── model_1_generic_wgs_chr22_gpu/
│   │   ├── variants.vcf.gz            (2.1M, 117,107 SNVs/indels)
│   │   ├── variants.vcf.gz.tbi        (22K index)
│   │   ├── variants.g.vcf.gz          (11M, 901,684 raw sites)
│   │   ├── variants.g.vcf.gz.tbi      (10K index)
│   │   ├── intermediate/              (TFRecords from make_examples)
│   │   └── logs/                      (DeepVariant run logs)
│   ├── model_2_mgi_wgs_pcr_chr22_gpu/ (attempted, failed model_type)
│   └── model_3_mgi_pcr_free_chr22_gpu/ (attempted, failed model_type)
│
├── variants_output/                   (Stage 3 production output, when ready)
│   ├── variants.vcf.gz
│   ├── variants.g.vcf.gz
│   ├── intermediate/                  (TFRecords from full BAM)
│   └── logs/
│
├── run_deepvariant_*.sh               (Stage 3 execution scripts)
│   ├── run_deepvariant_chr22_gpu_test.sh
│   ├── run_deepvariant_chr22_gpu_test_model2_mgi_wgs_pcr.sh
│   ├── run_deepvariant_chr22_gpu_test_model3_mgi_pcr_free.sh
│   └── [production versions]
│
├── logs/                              (Stage execution logs)
│   ├── stage1_progress.json
│   ├── stage2_progress.json
│   ├── stage3_progress.json
│   └── *.log files
│
├── bwa_progress.json                  (Stage 1 alignment progress)
├── stage*_progress.json               (Pipeline checkpoints)
│
├── fastq/                             (Original FASTQ files)
├── qc/                                (FastQC outputs)
├── raw_uncompressed/                  (Uncompressed FASTQ, temporary)
└── tmp/                               (Temporary files, scripts during execution)

```

### Reference Genome Directory
```
/home/rayzw/DNA-Linux/ref_genome/
├── Homo_sapiens.GRCh38.dna.primary_assembly.fa    (Primary reference)
├── Homo_sapiens.GRCh38.dna.primary_assembly.fa.fai (faidx index)
├── Homo_sapiens.GRCh38.dna.primary_assembly.fa.bwt (BWA index)
├── Homo_sapiens.GRCh38.dna.primary_assembly.fa.pac
├── Homo_sapiens.GRCh38.dna.primary_assembly.fa.ann
├── Homo_sapiens.GRCh38.dna.primary_assembly.sa
└── [other reference files]

/home/rayzw/DNA-Linux/ref_genome_hs38d1_decoy/     (NCBI decoy version, if present)
```

### Alternative/Older Paths
```
/home/rayzw/DNA/                       (Alternative root, may contain duplicates)
├── ref_genome/                        (Reference copies)
├── hg38/                              (Older pipeline outputs, may be stale)
└── [intermediate results]

/home/rayzw/Claude_WGS_Normalization-Stages-1-2-3-4/
└── (Copy of pipeline with claude_ prefix, may be outdated)

/home/rayzw/WGS_Normalization-Stages-1-2-3-4/
└── (Original pipeline copy, likely stale)
```

---

## Access Paths (Windows ↔ WSL Bridge)

### Via Windows UNC Path (PowerShell)
```powershell
# Access WSL files from Windows Explorer or PowerShell:
\\wsl.localhost\Ubuntu\home\rayzw\DNA-Linux\hg38\
\\wsl.localhost\Ubuntu\home\rayzw\DNA-Linux\ref_genome\

# Example PowerShell command:
Copy-Item "\\wsl.localhost\Ubuntu\home\rayzw\DNA-Linux\hg38\Rizwan_processed.bam" "C:\Backup\"
```

### Via WSL Path (from bash/WSL terminal)
```bash
# Direct access from WSL:
/home/rayzw/DNA-Linux/hg38/Rizwan_processed.bam
/home/rayzw/DNA-Linux/ref_genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa

# Windows paths visible as:
/mnt/c/Users/rayzw/...        (C: drive)
/mnt/d/...                    (D: drive, Ubuntu VHDX location)
/mnt/g/My\ Drive/Coding/...   (G: drive with spaces)
```

---

## Critical File Locations

### Execution Scripts
| File | Location | Purpose |
|---|---|---|
| `run_deepvariant_chr22_gpu_test.sh` | `/home/rayzw/DNA-Linux/hg38/` | Model 1 validation on chr22 |
| `install_nvidia_container_toolkit_wsl.sh` | `/home/rayzw/DNA-Linux/hg38/` | GPU setup (if needed) |
| `stage1_progress.json` | `/home/rayzw/DNA-Linux/hg38/` | Stage 1 checkpoint |
| `stage2_progress.json` | `/home/rayzw/DNA-Linux/hg38/` | Stage 2 checkpoint |

### Documentation & Context
| File | Location | Purpose |
|---|---|---|
| `CLAUDE.md` | `G:\My Drive\Coding\Claude\` | Project context & standing instructions |
| `MEMORY.md` | `C:\Users\rayzw\.claude\projects\G--My-Drive-Coding-Claude\memory\` | Auto-memory, session persistence |
| `ISSUE_LOG.md` | `C:\Users\rayzw\.claude\projects\G--My-Drive-Coding-Claude\memory\` | Structured issue tracking |
| `PROJECT_PATHS.md` | `C:\Users\rayzw\.claude\projects\G--My-Drive-Coding-Claude\memory\` | This file |
| `DEEPVARIANT_CHR22_VERSION_COMPARISON_REPORT.md` | `/home/rayzw/WGS_Normalization-Stages-1-2-3-4/` | Version benchmark results |

---

## Quick Command Cheat Sheet

### Access Memory Files
```bash
# Read current memory state
cat C:\Users\rayzw\.claude\projects\G--My-Drive-Coding-Claude\memory\MEMORY.md

# View issue log
cat C:\Users\rayzw\.claude\projects\G--My-Drive-Coding-Claude\memory\ISSUE_LOG.md

# View this file
cat C:\Users\rayzw\.claude\projects\G--My-Drive-Coding-Claude\memory\PROJECT_PATHS.md
```

### Access Pipeline Files (WSL)
```bash
# Connect to WSL
wsl -d Ubuntu

# Check current BAM
ls -lh /home/rayzw/DNA-Linux/hg38/Rizwan_processed.bam*

# View Stage 3 outputs
ls -lh /home/rayzw/DNA-Linux/hg38/variants_test/*/

# Check progress
cat /home/rayzw/DNA-Linux/hg38/stage3_progress.json | jq .
```

### Mount WSL from Windows
```powershell
# PowerShell: Open File Explorer to WSL root
explorer.exe \\wsl.localhost\Ubuntu\home\rayzw\DNA-Linux\hg38\

# Or navigate directly:
cd \\wsl.localhost\Ubuntu\home\rayzw\DNA-Linux\hg38\
dir
```

---

## Storage Summary

| Component | Size | Location | Status |
|---|---|---|---|
| MEMORY.md + ISSUE_LOG.md | ~50 KB | Claude Code local | ✅ Synced |
| Rizwan BAM (processed) | 58 GB | WSL `/home/rayzw/DNA-Linux/hg38/` | ✅ Complete |
| Reference genome | ~3 GB | WSL `/home/rayzw/DNA-Linux/ref_genome/` | ✅ Indexed |
| chr22 variant outputs | ~30 MB | WSL variants_test/ | ✅ Complete |
| Full VCF (production) | TBD | WSL variants_output/ | ⏳ Pending |

---

**Last updated:** 2026-06-08  
**Next update:** After Stage 3 production variant calling completes
