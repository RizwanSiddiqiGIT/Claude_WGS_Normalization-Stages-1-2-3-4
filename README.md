# WGS Normalization Stages 1-2-3-4

This repository owns the upstream WGS production stages that create the filtered VCF consumed by the downstream annotation and functional panel repository.

It intentionally does not store FASTQ, BAM, VCF, reference FASTA, DeepVariant tensors, or other large data files.

## Scope

Pipeline stages:

1. Quality control and FASTQ preprocessing
2. Alignment and duplicate marking
3. DeepVariant variant calling
4. VCF normalization and filtering

Downstream handoff output:

```text
/home/rayzw/DNA/hg38/variants_output/Rizwan_filtered.vcf.gz
/home/rayzw/DNA/hg38/variants_output/Rizwan_filtered.vcf.gz.tbi
```

The downstream stages 5-7 annotation/panel repo should consume only the filtered VCF and its index.

## Environment Rules

- Run inside WSL Ubuntu.
- Keep scripts, temp files, BAMs, tensors, and VCF outputs on native Linux paths under `/home/rayzw/DNA`.
- Do not use `/mnt/c` for active pipeline work.
- Chromosome names are numeric/no-prefix: `1`, `2`, `17`, `X`, `Y`, `M`; never `chr1`.
- Use DeepVariant `1.6.0` for MGI DNBSEQ compatibility.
- Pre-create output directories before launching Docker containers.

## Quick Start

```bash
cd /home/rayzw/WGS_Normalization-Stages-1-2-3-4
./preflight_software.sh
./preflight_data.sh
./stage1_qc_preprocess.sh
./stage2_align_markdup.sh
./stage3_deepvariant_calling.sh
./stage4_normalize_filter.sh
```

Run stages one at a time until data paths have been fully validated.

