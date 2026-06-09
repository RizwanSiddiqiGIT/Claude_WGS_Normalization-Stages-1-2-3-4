---
name: wgs-stage-2-markduplicates
metadata: 
  node_type: memory
  tags: 
    - pipeline
    - wgs
    - stage2
  date: 2026-06-08
  status: complete
  originSessionId: 06adf67b-8daa-4ab7-98a8-694fe1141efa
---

# WGS Stage 2 — Picard MarkDuplicates

**Status:** ✅ Complete (2026-06-08 14:23 EDT)
**Input:** `Rizwan_sorted.bam` (55G, Stage 1 output)
**Output:** `Rizwan_processed.bam` (58G) + `Rizwan_processed.bam.bai` (8.7M) + `dup_metrics.txt`

## Result
| Metric | Value |
|--------|-------|
| Read pairs examined | 351,326,005 |
| **PERCENT_DUPLICATION** | **1.34%** (0.013408) |
| Optical duplicates | 0 (Picard default regex doesn't parse MGI read names) |
| Library | DNB_Library1 |
| Duration | ~3.5 h |

→ 1.34% dup = PCR-free classification: [[Insights/MGI-DNBSEQ-Platform]].

## Command
```bash
picard MarkDuplicates I=Rizwan_sorted.bam O=Rizwan_processed.bam \
  M=dup_metrics.txt CREATE_INDEX=true VALIDATION_STRINGENCY=LENIENT
```

## Gotchas
- Index was created as `Rizwan_processed.bai`; tools expect `Rizwan_processed.bam.bai` → **symlinked**.
- Phase metric: track **"Written X records"** during marking, NOT "Read X records" (goes stale) → [[Procedures/Phase-Metrics-Reference]] (Stage 2).
- Many short-lived threads restarting during the run = normal Picard behaviour.

## Quality / integrity
→ [[Quality/Stage2-Postflight-Check]] · [[Quality/BAM-Integrity-Registry]]

## Next
→ [[Pipeline/Stage3-VariantCalling]]
