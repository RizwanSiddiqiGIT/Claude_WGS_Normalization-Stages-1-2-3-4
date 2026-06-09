---
name: claude-session-start-read-first
metadata: 
  node_type: memory
  tags: 
    - claude
    - session-start
    - on-ramp
  date: 2026-06-08
  status: active
  originSessionId: 06adf67b-8daa-4ab7-98a8-694fe1141efa
---

# 🚦 Claude Session Start — Read This First

> Curated on-ramp for every new session. [[MEMORY]] (auto-loaded) points here.
> Read this, then open only the notes relevant to the current task.

---

## 📍 Current State (2026-06-08)

| Item | Status |
|------|--------|
| **Active stage** | Stage 3 — DeepVariant variant calling |
| **Stage 3** | chr22 validation ✅ done · **full-BAM production run NOT yet launched** |
| **Active BAM** | `/home/rayzw/DNA-Linux/hg38/Rizwan_processed.bam` (58G) + `.bam.bai` |
| **Reference** | `/home/rayzw/DNA-Linux/ref_genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa` |
| **Chosen tool** | DeepVariant 1.10.0 · `--model_type=WGS` · `--num_shards=24` |
| **Stages 1 & 2** | ✅ Complete |
| **Stage 4** | ⏳ Pending (normalization + filtering) |

→ Full detail: [[Pipeline/Stage3-VariantCalling]]

---

## ⚠️ Critical Standing Rules

1. **Log every ISSUE _and_ INSIGHT before moving on** — protocol in [[MEMORY]]. ISSUE_LOG is at **ISSUE-012**.
2. **WSL execution:** the **Bash tool** runs `wsl -d Ubuntu -- bash -c "..."` cleanly; **PowerShell** prints a harmless `Failed to translate 'G:\...'` CWD warning but still runs. Keep Linux paths *inside* the quoted `bash -c` string. → [[Insights/Claude-Code-Environment]]
3. **Long jobs (>30 min):** remind user to disable Windows sleep — sleep kills WSL → [[ISSUE_LOG#ISSUE-009]].
4. **Background procs:** `setsid ... < /dev/null & disown`; pre-check with `pgrep` to avoid duplicates → [[Reference/Process-Daemon]].
5. **Pre-flight check before every stage** → [[Procedures/Preflight-Check-Routine]].

---

## 🗺️ Where Things Live

- **Vault map:** [[HOME]]
- **All issues:** [[ISSUE_LOG]] · **Path map:** [[PROJECT_PATHS]]
- **Pipeline:** [[Pipeline/Stage1-Overview]] · [[Pipeline/Stage2-MarkDuplicates]] · [[Pipeline/Stage3-VariantCalling]] · [[Pipeline/Stage4-Normalization]]
- **Insights:** [[Insights/DeepVariant]] · [[Insights/MGI-DNBSEQ-Platform]] · [[Insights/BQSR-Decision]] · [[Insights/Claude-Code-Environment]] · [[Insights/GitHub]]
- **Trustworthy metrics per phase:** [[Procedures/Phase-Metrics-Reference]]

---

## ▶️ Likely Next Action

Pre-flight check, then **launch the full-BAM Stage 3 production run** (DeepVariant 1.10.0, WGS, chromosome-wide — reuse `run_deepvariant_chr22_gpu_test.sh`, drop `--regions=22`, output to `variants_output/`). Expected ~45 min – 2 h on GPU. If a production VCF already exists on disk, proceed to [[Pipeline/Stage4-Normalization]] instead. **Verify on disk before assuming state.**
