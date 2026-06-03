# Stage 4 To Stage 5 Handoff

This file defines the boundary between this repository and the downstream annotation/panel repository.

## Producer

Repository:

```text
WGS_Normalization-Stages-1-2-3-4
```

Final stage:

```text
Stage 4 - VCF normalization and filtering
```

## Consumer

Downstream repository:

```text
wgs-metabolic-pipeline
```

First downstream stage:

```text
Stage 5 - VEP annotation with CADD/REVEL
```

## Required Handoff Files

```text
/home/rayzw/DNA/hg38/variants_output/Rizwan_filtered.vcf.gz
/home/rayzw/DNA/hg38/variants_output/Rizwan_filtered.vcf.gz.tbi
```

## Reference Contract

The filtered VCF must be based on:

```text
/home/rayzw/DNA/ref_genome/Homo_sapiens.GRCh38.dna.primary_assembly.fa
```

Chromosome naming must remain numeric/no-prefix:

```text
1, 2, 3, ..., 22, X, Y, M
```

Do not emit `chr1`, `chrX`, or `chrM`.

## Validation

Before handing off to Stage 5:

```bash
bcftools index --stats /home/rayzw/DNA/hg38/variants_output/Rizwan_filtered.vcf.gz
bcftools view -h /home/rayzw/DNA/hg38/variants_output/Rizwan_filtered.vcf.gz | grep '^##reference'
tabix -l /home/rayzw/DNA/hg38/variants_output/Rizwan_filtered.vcf.gz | head
```

