---
name: bqsr-why-we-skip-it-with-deepvariant
metadata: 
  node_type: memory
  tags: 
    - decision
    - bqsr
    - variant-calling
    - gatk
    - deepvariant
    - insight
  date: 2026-06-08
  status: active
  originSessionId: 06adf67b-8daa-4ab7-98a8-694fe1141efa
---

# Decision: Skip BQSR (because we use DeepVariant)

**Decision:** No BQSR step between MarkDuplicates and variant calling.

## Why
1. **DeepVariant doesn't need it.** It's a CNN trained on millions of labeled alignments and learns base-quality error patterns internally (effectively implicit recalibration). BQSR matters for **GATK HaplotypeCaller**, which uses raw base qualities directly in PairHMM likelihoods.
2. **BQSR has a circular dependency.** It recalibrates using *known* sites (dbSNP/Mills); for novel/rare/de-novo variants it can mislabel real ALT bases as "errors" — worse for a single individual.
3. **Marginal gains for single samples.** BQSR helps most in large cohorts; for one 30x WGS sample the benefit is small and the mis-training risk is real.
4. **Clean input.** PCR-free library, 1.34% duplication → little systematic amplification noise to correct → [[Insights/MGI-DNBSEQ-Platform]].

## When BQSR WOULD be added
- Switching to **GATK HaplotypeCaller** (then effectively mandatory).
- **Clinical / regulatory** SOP compliance (audit trail).
- **GIAB benchmarking** — run with/without and compare F1.

## If added (reference)
```bash
gatk BaseRecalibrator -I Rizwan_processed.bam -R ref.fa \
  --known-sites dbSNP_b151.vcf.gz --known-sites Mills_1000G_indels.vcf.gz \
  -O recal.table
gatk ApplyBQSR -I Rizwan_processed.bam --bqsr-recal-file recal.table \
  -O Rizwan_recalibrated.bam
```
~30–45 min; quality gain likely small for DeepVariant (validate to confirm).
