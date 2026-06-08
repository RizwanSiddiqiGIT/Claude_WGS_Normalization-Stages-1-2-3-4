# Stage 3: DeepVariant Model Comparison Trial & Production Plan

**Date:** 2026-06-08  
**Approach:** Docker (gcr.io/deepvariant-docker/deepvariant)  
**Sequencing Platform:** MGI/DNBSEQ (DNA Nanoball)  
**Input:** Rizwan_processed.bam (58GB, 761,990,484 reads)  

---

## Strategy

### Phase 1: Trial Run (Model Comparison) ✅ NEXT
Test **three DeepVariant models** on **chr22 region** (~9.8M reads, 730MB) to determine which performs best for our MGI/DNBSEQ data:

1. **Model 1: Generic DeepVariant WGS** (default, Illumina-trained)
2. **Model 2: MGI WGS-PCR trained** (if available from MGI repo)
3. **Model 3: MGI PCR-free trained** (if available from MGI repo)

**Rationale:**
- Generic WGS is broadly validated but designed for Illumina
- MGI-trained models are platform-optimized but may require custom setup
- Testing on chr22 is fast (~15-30 min per model) vs full BAM (8-12 hours)
- Allows selection of best model before committing to production run

### Phase 2: Full Production Run 🚀 AFTER MODEL SELECTION
Once best model is selected, run on complete BAM (58GB):

- Expected duration: 8-12 hours
- Output: Rizwan_raw_variants.vcf.gz (~2-5GB)
- Output: Rizwan_raw_variants.g.vcf.gz (detailed GVCF)

### Phase 3: Binary Installation (Optional)
After selecting the best model, optionally install that specific DeepVariant version as binary for future runs:

- Performance gain: ~5-10% faster than Docker
- One-time installation cost: ~30-45 minutes
- Only worth doing if variant calling becomes routine

---

## Phase 1: Trial Run (Model Comparison)

### Step 1: Pull Docker Image
```bash
docker pull gcr.io/deepvariant-docker/deepvariant:latest
```

**Expected:** ~2-3 minutes (depends on internet speed, image is ~3GB)

### Step 2: Run Model 1 (Generic WGS) on chr22
```bash
bash /tmp/stage3_model_comparison_test.sh
```

**Script does:**
- Extracts chr22 region from Rizwan_processed.bam
- Runs DeepVariant with `--model_type=WGS`
- Outputs VCF and gVCF
- Records runtime and variant count
- Compares against Models 2 & 3

**Expected Output:**
- Variants called: ~50,000-100,000 on chr22 (~1-2% of full genome)
- Runtime: 15-30 minutes
- File size: ~50-100MB VCF

### Step 3: Download MGI Models (If Pursuing Further)

If comparing against MGI-trained models:
```bash
git clone https://github.com/MGI-tech-bioinformatics/DeepVariant
# Download model checkpoints from releases
```

**MGI Models Available:**
- `mgi_wgs_pcr_model.ckpt` (for PCR-based library prep)
- `mgi_pcr_free_model.ckpt` (for PCR-free library prep)

**Library Detection for Rizwan data:**
- From BAM header: `LB:DNB_Library1`
- Library name suggests MGI DNB library
- Prep type: Unknown (PCR-based vs PCR-free)
- **Assumption:** Likely PCR-based (default for most WGS)

### Step 4: Compare Results
```
Comparison Metrics:
┌────────────────────┬──────────────┬────────────────┐
│ Model              │ Chr22 Variants│ Runtime (approx)│
├────────────────────┼──────────────┼────────────────┤
│ Generic WGS        │ XX,XXX       │ ~20 min        │
│ MGI WGS-PCR        │ XX,XXX       │ ~20 min        │
│ MGI PCR-free       │ XX,XXX       │ ~20 min        │
└────────────────────┴──────────────┴────────────────┘

Selection Criteria:
- Variant count closest to expected (~1-2% of full genome)
- Fastest runtime
- Highest sensitivity for true variants
```

---

## Phase 2: Full Production Run

### Once Best Model Selected:

```bash
# Edit script to use selected model
vi /tmp/stage3_docker_production.sh

# Add customized model line if not generic WGS:
# --customized_model=/path/to/selected/model.ckpt

# Launch production run
bash /tmp/stage3_docker_production.sh
```

**⚠️ BEFORE LAUNCHING:**
- [ ] Disable Windows sleep (Settings → System → Power → Sleep → Never)
- [ ] Confirm 682GB disk space available
- [ ] Verify WSL Ubuntu is responsive
- [ ] Ensure 8-12 hour uninterrupted availability

**Expected Output:**
```
/home/rayzw/DNA-Linux/hg38/variants_output/
├── Rizwan_raw_variants.vcf.gz          (2-5 GB)
├── Rizwan_raw_variants.vcf.gz.tbi      (index)
├── Rizwan_raw_variants.g.vcf.gz        (detailed gVCF)
└── Rizwan_raw_variants.g.vcf.gz.tbi    (index)
```

---

## Phase 3: Binary Installation (Optional)

After variant calling completes and we're satisfied with results:

### If we want to install binary version for future runs:

```bash
# Download selected DeepVariant version
cd /home/rayzw/opt
wget https://github.com/google/deepvariant/releases/download/[VERSION]/deepvariant-[VERSION]-linux-x86_64.tar.gz
tar -xzf deepvariant-[VERSION]-linux-x86_64.tar.gz

# Update PATH for future use
echo "export PATH=/home/rayzw/opt/deepvariant/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc

# Verify
run_deepvariant --version
```

**Benefits:**
- ~5-10% faster than Docker
- No Docker image pull needed
- Direct system integration

**Cost:**
- 30-45 minutes installation time
- Only worth if variant calling becomes routine (e.g., multiple samples)

---

## Timeline

| Phase | Task | Duration | Notes |
|-------|------|----------|-------|
| 1a | Pull Docker image | 2-3 min | One-time |
| 1b | Run Model 1 test | 15-30 min | chr22 only |
| 1c | Compare results | 5 min | Decision point |
| 2a | Launch prod run | 0 min | Script setup |
| 2b | Production execution | 8-12 hours | Full BAM |
| 2c | Validate output | 10 min | VCF checks |
| 3a | (Optional) Binary install | 30-45 min | If pursuing further |

---

## Commands Quick Reference

### Trial Run (Model Comparison)
```bash
bash /tmp/stage3_model_comparison_test.sh
```

### Production Run (Docker)
```bash
bash /tmp/stage3_docker_production.sh
```

### Check Progress
```bash
# Monitor Docker container
docker ps

# Check output size
ls -lh /home/rayzw/DNA-Linux/hg38/variants_output/

# View variant count (once VCF created)
bcftools view -H /home/rayzw/DNA-Linux/hg38/variants_output/Rizwan_raw_variants.vcf.gz | wc -l
```

### Post-Production Validation
```bash
# Check VCF header
bcftools view -h /home/rayzw/DNA-Linux/hg38/variants_output/Rizwan_raw_variants.vcf.gz | head -20

# Count variants by type
bcftools stats /home/rayzw/DNA-Linux/hg38/variants_output/Rizwan_raw_variants.vcf.gz | grep "^SN"

# Create checksums
md5sum /home/rayzw/DNA-Linux/hg38/variants_output/Rizwan_raw_variants.vcf.gz > checksums.md5
sha256sum /home/rayzw/DNA-Linux/hg38/variants_output/Rizwan_raw_variants.vcf.gz > checksums.sha256
```

---

## Documentation

- **ISSUE-011:** WSL path translation issue (documented in ISSUE_LOG.md)
- **Memory Note:** DeepVariant for MGI/DNBSEQ requires platform-specific model testing
- **Context:** Rizwan data is MGI/DNBSEQ (DNA Nanoball), not Illumina

---

## Status

✅ **Ready to begin Phase 1: Trial Run (Model Comparison)**

**Next Action:** Run `bash /tmp/stage3_model_comparison_test.sh`

