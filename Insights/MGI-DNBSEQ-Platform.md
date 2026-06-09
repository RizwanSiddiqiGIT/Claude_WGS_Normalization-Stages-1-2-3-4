---
name: mgi-dnbseq-platform-pcr-status-implications
metadata: 
  node_type: memory
  tags: 
    - platform
    - mgi
    - dnbseq
    - sequencing
    - sample
    - insight
  date: 2026-06-08
  status: active
  originSessionId: 06adf67b-8daa-4ab7-98a8-694fe1141efa
---

# MGI / DNBSEQ Platform Notes

**Sample:** Muhammad Siddiqi · 30x WGS · MGI DNBSEQ · library `DNB_Library1`.

## Is MGI PCR-based? Two separate stages — different answers:
1. **Sequencing chemistry / clustering = NOT PCR.** DNBSEQ forms **DNA Nanoballs** via **Rolling Circle Amplification (RCA)** — isothermal, *linear* amplification from one circular template, so errors don't compound exponentially. Fundamentally different from Illumina bridge PCR. This is a fixed platform property (low dup, low amplification error).
2. **Library prep = depends on the kit.** This is what "PCR vs PCR-free" actually refers to. MGI sells both PCR and PCR-free (MGIEasy PCR-Free) kits.

## This sample is PCR-free (evidence)
From `dup_metrics.txt` (Stage 2):
- **PERCENT_DUPLICATION = 0.013408 (1.34%)** across 351,326,005 read pairs.
- 1.34% is squarely PCR-free territory (PCR libraries run ~5–25%).
- Optical-dupes = 0 is partly a Picard default-regex artifact for MGI read names — don't over-read it; the 1.34% total is the solid signal.

## Implications
- DeepVariant **`--model_type=WGS`** (handles PCR-free; PCR/PCR-free model types deprecated) → [[Insights/DeepVariant]], [[ISSUE_LOG#ISSUE-012]].
- Clean input supports **skipping BQSR** → [[Insights/BQSR-Decision]].
