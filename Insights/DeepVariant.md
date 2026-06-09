---
name: deepvariant-model-version-gpu
metadata: 
  node_type: memory
  tags: 
    - tool
    - deepvariant
    - variant-calling
    - stage3
    - insight
  date: 2026-06-08
  status: active
  originSessionId: 06adf67b-8daa-4ab7-98a8-694fe1141efa
---

# DeepVariant — Insights

## Model type: use `WGS` (PCR/PCR-free is deprecated)
- Valid `--model_type` values (current releases): `WGS | WES | PACBIO | ONT_R104 | HYBRID_PACBIO_ILLUMINA | MASSEQ | RNASEQ`.
- Old `WGS_PCR` / `PCR_FREE` model types were **removed** (1.9+). The single `WGS` model learns the error profile from data channels and handles both PCR and PCR-free libraries.
- For this MGI/DNBSEQ PCR-free sample → **`--model_type=WGS`**. See [[Insights/MGI-DNBSEQ-Platform]] and [[ISSUE_LOG#ISSUE-012]].
- A true MGI-trained model (if ever needed) is a custom checkpoint via `--customized_model=/path` — **not** a `model_type` — and must be validated against a truth set first.

## Version: use 1.10.0 (1.9.0 = fallback; avoid 1.6.0)
Source: chr22 version comparison (`~/WGS_Normalization-Stages-1-2-3-4/DEEPVARIANT_CHR22_VERSION_COMPARISON_REPORT.md`).
- **1.9.0 ≈ 1.10.0**: identical VCF (117,107) & gVCF (901,684) counts; composition differs by 1 SNP / 1 indel (noise).
- **1.10.0 wins on ops**: newest, canonical GPU image, and splits `NoCall` out of `RefCall` (better FILTER semantics — same underlying genotypes: 31,736 RefCall + 18,061 NoCall ≈ 1.9.0's 49,767 RefCall).
- **1.6.0 is an outlier**: +2,993 VCF records, +2,456 indels, fewer no-calls. More ≠ better without a truth set → likely lower precision. Don't use without GIAB validation.
- **Pin by digest** for production:
  `gcr.io/deepvariant-docker/deepvariant@sha256:78fb1bb960f3b74a4308b62ba8b6232723d4c75e16a4a50f0d810d7086467dd1`

## chr22 validation (Model 1, Generic WGS, 1.10.0)
VCF 117,107 (2.1M) · gVCF 901,684 (11M) · SNPs 85,723 · indels 31,295 · PASS 67,310.
Output: `variants_test/model_1_generic_wgs_chr22_gpu/`.

## Canonical run script
`/home/rayzw/DNA-Linux/hg38/run_deepvariant_chr22_gpu_test.sh` — parameterized format (host→container path mapping, GPU env vars, file + GPU pre-flight checks, intermediate/logging dirs). **Reuse this structure** for the full-BAM run (drop `--regions=22`, point output at `variants_output/`).

## GPU / Docker
- Driver works in WSL (nvidia-smi OK; RTX 3080 Ti, 12 GB).
- `--gpus all -e NVIDIA_VISIBLE_DEVICES=all` works with the `:latest-gpu` image.
- Runtime/phase (chr22): make_examples ~3 m (CPU, longest) · call_variants ~1–2 m (GPU) · postprocess <20 s.
- Note: `nvidia-container-toolkit` was not in apt repos earlier; GPU still functioned via the image's bundled CUDA. → [[ISSUE_LOG#ISSUE-011]] context.

## Related decisions
- BQSR before calling? **No, by design** → [[Insights/BQSR-Decision]].
- Phase metrics to trust → [[Procedures/Phase-Metrics-Reference]] (Stage 3).
