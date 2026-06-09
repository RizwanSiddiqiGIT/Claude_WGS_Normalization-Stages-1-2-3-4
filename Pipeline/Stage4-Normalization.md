---
name: wgs-stage-4-normalization-filtering
metadata: 
  node_type: memory
  tags: 
    - pipeline
    - wgs
    - stage4
    - bcftools
  date: 2026-06-08
  status: pending
  originSessionId: 06adf67b-8daa-4ab7-98a8-694fe1141efa
---

# WGS Stage 4 — Variant Normalization & Filtering

**Status:** ⏳ Pending — starts once a Stage 3 production VCF exists.

## Planned steps
1. **Normalize** (left-align indels, split multiallelics):
   ```bash
   bcftools norm -f ref.fa -m -both -O z \
     -o Rizwan_norm.vcf.gz Rizwan_raw_variants.vcf.gz
   bcftools index -t Rizwan_norm.vcf.gz
   ```
2. **Filter** (PASS + quality thresholds) → `Rizwan_filtered.vcf.gz`.

## Metrics
→ [[Procedures/Phase-Metrics-Reference]] (Stage 4).

## Prerequisite
Stage 3 production VCF at `/home/rayzw/DNA-Linux/hg38/variants_output/`.

## Previous stage
← [[Pipeline/Stage3-VariantCalling]]
