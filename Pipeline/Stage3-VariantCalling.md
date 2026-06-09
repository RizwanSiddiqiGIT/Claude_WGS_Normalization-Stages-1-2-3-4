---
name: wgs-stage-3-deepvariant-variant-calling
metadata: 
  node_type: memory
  tags: 
    - pipeline
    - wgs
    - stage3
    - deepvariant
  date: 2026-06-08
  status: in-progress
  originSessionId: 06adf67b-8daa-4ab7-98a8-694fe1141efa
---

# WGS Stage 3 — DeepVariant Variant Calling

**Status:** 🔄 chr22 validation ✅ done — **full-BAM production run NOT yet launched.**

## Config (decided)
| Item | Value |
|------|-------|
| Tool | DeepVariant **1.10.0** (`:latest-gpu`) → [[Insights/DeepVariant]] |
| model_type | **WGS** (PCR/PCR-free deprecated → [[ISSUE_LOG#ISSUE-012]]) |
| Shards | 24 |
| Ref | `/home/rayzw/DNA-Linux/ref_genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa` |
| BAM | `/home/rayzw/DNA-Linux/hg38/Rizwan_processed.bam` (58G) |
| BQSR | skipped by design → [[Insights/BQSR-Decision]] |

## chr22 validation (complete)
| Metric | Value |
|--------|-------|
| VCF records | 117,107 (2.1M) |
| gVCF records | 901,684 (11M) |
| SNPs / indels / PASS | 85,723 / 31,295 / 67,310 |
| Output | `variants_test/model_1_generic_wgs_chr22_gpu/` |

## Three phases & metrics
1. **make_examples** — 24 shards, CPU-bound, longest (~3 m chr22). Track `Shard [X/24]`.
2. **call_variants** — GPU, ~1–2 m chr22.
3. **postprocess_variants** — <20 s, emits VCF.

→ [[Procedures/Phase-Metrics-Reference]] (Stage 3).

## Canonical run script
`/home/rayzw/DNA-Linux/hg38/run_deepvariant_chr22_gpu_test.sh` — parameterized (host→container mapping, GPU env vars, pre-flight). **Production:** same script, drop `--regions=22`, output → `variants_output/`.

## ⏭️ Next action
Pre-flight check → launch full-BAM production run. Expected ~45 m – 2 h (GPU). Remind user to disable Windows sleep → [[ISSUE_LOG#ISSUE-009]].

## ⚠️ Failed approach (don't repeat)
`--model_type=WGS_PCR` / `PCR_FREE` → rejected by DeepVariant → [[ISSUE_LOG#ISSUE-012]].

## Next stage
→ [[Pipeline/Stage4-Normalization]]
