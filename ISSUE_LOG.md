# Issue Log — WGS Pipeline & Claude Code Sessions

Structured documentation of every issue encountered, its cause, solution, and reuse instruction.
Format: Issue → Cause → Solution → Future Instruction

---

## Index (12 issues)

| ID | One-line summary | Category |
|----|------------------|----------|
| ISSUE-001 | Inline WSL bash via PowerShell corrupts paths/output | WSL exec |
| ISSUE-002 | VirtioFS corrupts large (>20–30 GB) file transfers | Filesystem |
| ISSUE-003 | BWA killed by SIGHUP from Claude heredoc — use `setsid` | Process mgmt |
| ISSUE-004 | Incomplete SAM (4% of reads) accepted as complete | Validation |
| ISSUE-005 | Step scripts referenced wrong config filename after rename | Scripting |
| ISSUE-006 | FastQC `-t` is file-level parallelism, not per-file threads | Tool behavior |
| ISSUE-007 | fastp uses `-w`, not `--threads` | Tool CLI |
| ISSUE-008 | bash+jq progress updater failed silently — use Python | Monitoring |
| ISSUE-009 | Windows sleep kills WSL — disable for >30 min jobs | Persistence |
| ISSUE-010 | Redundant parallel `sha256sum` processes on same file | Bg tasks |
| ISSUE-011 | PowerShell WSL path-translation fails on `G:\` (spaces) | WSL/Windows |
| ISSUE-012 | DeepVariant `WGS_PCR`/`PCR_FREE` model_type deprecated | Variant calling |
| ISSUE-013 | Local clone `Claude_WGS_...` pointed to wrong GitHub remote | GitHub |

> **Kept as a single file by design** — many notes deep-link `[[ISSUE_LOG#ISSUE-NNN]]`; splitting would break those anchors. Split into `Issues/ISSUE-0XX-to-0YY.md` batches only past ~20 entries, updating cross-refs at the same time.

---

## ISSUE-001: WSL Complex Commands Break via PowerShell Inline

**Encountered:** 2026-06-07, Session 1
**Category:** Claude Code / WSL execution

### Issue
Running multi-line bash commands inline via `wsl -d Ubuntu -- bash -c "..."` caused path corruption, special characters being interpreted by Windows layer, and tool output being injected mid-string.

### Cause
PowerShell processes the string before handing it to WSL. Backtick-quoted paths, special characters (`$`, `\t`, `&`), and multi-line strings are all partially interpreted by the Windows/PowerShell shell layer before reaching bash inside WSL.

### Solution
Always write the bash logic to a script file first (via the Write tool to `\\wsl.localhost\Ubuntu\home\rayzw\tmp\script.sh`), then invoke it cleanly:
```powershell
wsl -d Ubuntu -- bash /home/rayzw/tmp/script.sh
```

### Future Instruction
> **BEFORE running any multi-line or complex bash in WSL:** write it as a script file first. Never use inline `-c "..."` for anything beyond a single simple command. See `feedback_wsl_execution.md`.

---

## ISSUE-002: Large File Transfer Corruption via VirtioFS

**Encountered:** 2026-06-07, Session 1
**Category:** WSL filesystem / data integrity

### Issue
Transferring 35GB and 36GB FASTQ files from Windows (`/mnt/c/`, `/mnt/d/`) to WSL using `rsync` or `cp` caused CRC32 checksum mismatches. Corruption appeared at varying offsets (29.5GB+). Files failed `bgzip -t` integrity checks.

### Cause
WSL's VirtioFS bridge corrupts data during large sequential reads through the `/mnt/` mount layer. The filesystem bridge has known data integrity issues with files above ~20-30GB in size.

### Solution
Bypass VirtioFS entirely by using PowerShell's `Copy-Item` via the `\\wsl.localhost\Ubuntu\` UNC path (native Windows file APIs):
```powershell
Copy-Item "C:\Users\rayzw\Downloads\file.fq.gz" `
  "\\wsl.localhost\Ubuntu\home\rayzw\DNA-Linux\hg38\file.fq.gz"
```
Verify with three-layer check: Windows SHA256 → WSL `bgzip -t` → WSL SHA256 comparison.

### Future Instruction
> **For any file >10GB transfer from Windows to WSL:** always use `Copy-Item` via `\\wsl.localhost\Ubuntu\...` path. Never use `rsync /mnt/...` or `cp /mnt/...` for large files. Always run `bgzip -t` + SHA256 after transfer.

---

## ISSUE-003: BWA-MEM2 Killed Silently When Launched via Claude Bash Tool

**Encountered:** 2026-06-08, Session 2
**Category:** Process management / long-running tools

### Issue
BWA-MEM2 launched with `nohup bash script.sh &` from inside a Claude Code Bash tool heredoc died silently within seconds. SAM file stayed at 0 bytes. No error in dmesg, no OOM messages. Process appeared alive for ~15 seconds then vanished.

### Cause
Claude's Bash tool runs each heredoc in a subprocess. When that subprocess exits at the end of the heredoc, it sends SIGHUP to its entire process group. `nohup` protects against SIGHUP from terminal hangup, but NOT from process group termination when the parent bash exits. The process was being killed before BWA even finished loading the reference index (~15-20 seconds).

### Solution
Use `setsid` to create a fully detached new process session, combined with `disown`:
```bash
setsid bash /home/rayzw/tmp/run_bwa.sh \
  < /dev/null \
  >> /path/to/bwa.log \
  2>&1 &
BWA_PID=$!
disown $BWA_PID
```
Then verify survival in a **separate** Bash tool call (new heredoc):
```bash
ps aux | grep bwa-mem2 | grep -v grep
```

### Future Instruction
> **For ANY long-running process launched from Claude Code (BWA, samtools sort, DeepVariant, etc.):** always use `setsid ... < /dev/null >> log 2>&1 & disown $!`. Never rely on `nohup` alone. Always verify survival in a separate tool call after a 15-30 second wait. See `bwa_daemon_execution.md`.

---

## ISSUE-004: BWA-MEM2 Alignment Produced Incomplete SAM (4% of Reads)

**Encountered:** 2026-06-08, Session 2
**Category:** Pipeline correctness / data validation

### Issue
First BWA run (using `-t 22 -K 200000000`) ran for ~7 minutes and produced a 13GB SAM file. This appeared successful but was actually only 4% complete — 32M alignment lines instead of the expected 760M.

### Cause
Two separate problems:
1. Process was killed mid-run (ISSUE-003 above — setsid not used)
2. Original thread/batch settings (`-t 22 -K 200M`) may contribute to memory pressure over long runs

No SAM completeness check was performed before proceeding.

### Solution
1. Fix process detachment (ISSUE-003)
2. Reduce to `-t 16 -K 100000000` for stability on this hardware
3. Always validate SAM before advancing to Step 6:
```bash
ALIGN_LINES=$(wc -l < aligned.sam)
HEADER_LINES=$(grep "^@" aligned.sam | wc -l)
ACTUAL=$(( ALIGN_LINES - HEADER_LINES ))
echo "Alignment lines: $ACTUAL (expected ~760,000,000)"
[ $ACTUAL -lt 700000000 ] && echo "INCOMPLETE — re-run BWA" || echo "OK"
```

### Future Instruction
> **After BWA completes:** always run the SAM completeness check before creating the BWA_ALIGN checkpoint or proceeding to Step 6. For 30x WGS expect ~760M alignment lines. A file size of 13GB is a red flag (full SAM should be 120-150GB). Add this check to `claude_stage1_step05_bwa_align.sh`.

---

## ISSUE-005: All Stage 1 Step Scripts Referenced Wrong Config Filename

**Encountered:** 2026-06-08, Session 2
**Category:** Pipeline scripting / refactoring errors

### Issue
After copying the pipeline to `Claude_WGS_Normalization-Stages-1-2-3-4/` and renaming files with `claude_` prefix, all 7 step scripts still contained `source ./config.env` but the file had been renamed to `claude_config.env`. Pipeline failed immediately on every restart with `config.env: No such file or directory`.

### Cause
The copy-and-rename script (`copy_and_rename.sh`) renamed the config file but did not update the `source` references inside the step scripts. The `sed` pattern used didn't match the full bash path expansion syntax `$(dirname "${BASH_SOURCE[0]}")/config.env`.

### Solution
Bulk-fix with correct escaping:
```bash
for script in claude_stage1_step*.sh; do
  sed -i 's|source "\$(dirname "\${BASH_SOURCE\[0\]}")/config.env"|source "$(dirname "${BASH_SOURCE[0]}")/claude_config.env"|g' "$script"
done
```

### Future Instruction
> **After any rename/copy refactor:** immediately run `grep -r "config.env" *.sh` to verify all references were updated. Add a post-rename validation step to `copy_and_rename.sh` that greps for stale filenames and exits with error if any are found.

---

## ISSUE-006: FastQC -t Flag Misunderstood as Per-File Threading

**Encountered:** 2026-06-07, Session 1
**Category:** Tool behavior / optimization

### Issue
FastQC was configured with `-t 12` expecting 12 threads per file. htop showed only 2-3 threads. Initial conclusion was a threading bug.

### Cause
FastQC's `-t` flag controls **file-level parallelism** (how many files to process simultaneously), NOT internal threads per file. FastQC processes each individual file mostly single-threaded. It is I/O-bound, not CPU-bound.

### Solution
Run FastQC on R1 and R2 **in parallel** as separate processes (each with `-t 6` to allow up to 6 simultaneous files per process), rather than trying to thread a single file:
```bash
fastqc -t 6 R1.fastq.gz -o qc/ &
fastqc -t 6 R2.fastq.gz -o qc/ &
wait
```

### Future Instruction
> **FastQC is I/O-bound and single-threaded per file.** Don't waste time trying to optimize `-t` for single large files. Always run R1 and R2 as parallel background processes and `wait` for both. CPU utilization will look low — that is normal and expected.

---

## ISSUE-007: fastp Uses -w Flag, Not --threads

**Encountered:** 2026-06-07, Session 1
**Category:** Tool CLI / scripting

### Issue
fastp was called with `--threads 20`, producing `undefined option: --threads` error.

### Cause
fastp uses `-w` (worker threads), not `--threads`. Unlike most tools that accept long-form flags, fastp's thread flag is short-form only.

### Solution
```bash
fastp -w 20 ...   # correct
fastp --threads 20  # WRONG — will error
```

### Future Instruction
> **Always use `-w N` for fastp threading**, never `--threads`. Verify fastp flags with `fastp --help | grep -i thread` before scripting.

---

## ISSUE-008: Progress File Went Stale (bash + jq approach failed silently)

**Encountered:** 2026-06-07, Session 1
**Category:** Pipeline monitoring / progress tracking

### Issue
The bash+jq progress updater (`update_stage1_progress.sh`) failed silently — errors were redirected to `/dev/null`. Dashboard showed no progress despite pipeline running.

### Cause
Complex bash string interpolation combined with jq JSON queries is fragile. Variable escaping issues, no atomic writes, and silent error suppression meant failures were invisible.

### Solution
Replace entirely with Python (`claude_progress_update.py`):
- Native `json` library (no jq dependency)
- Atomic writes via temp-file-then-rename
- Explicit exception handling with stderr output
- Auto-complete previous step when new step starts (prevents dual "running" states)

### Future Instruction
> **Never use bash+jq for JSON manipulation in pipeline scripts.** Always use Python with the native `json` library. Always use atomic writes (write to `.tmp` then `os.rename()`). Never redirect errors to `/dev/null` in progress updaters.

---

## ISSUE-009: samtools sort killed by Windows sleep / WSL restart

**Encountered:** 2026-06-08, Session 2
**Category:** Pipeline / Process persistence

### Issue
`samtools sort` started at 04:12 EDT on an 84 GB unsorted BAM. By 09:21 EDT (5 hours later), no samtools process was running, no sorted BAM existed, and `dmesg` showed only boot-time entries — confirming WSL had been fully restarted. The daemon log ended abruptly at the "Sorting BAM…" line with no error or completion message.

### Cause
Windows went to sleep overnight (machine was unattended 04:12–09:21 EDT). When Windows enters S3/S4 sleep or hibernate, WSL is terminated. All processes inside WSL — including those launched with `setsid` and `disown` — are killed immediately. `setsid` protects against SIGHUP from a parent shell exiting, but **cannot** protect against the host OS killing the entire WSL VM.

### Solution
Re-launched a targeted sort daemon that:
1. Skips SAM→BAM re-conversion (unsorted `aligned.bam` survived on disk)
2. Runs `samtools sort -@ 16 -m 3G` (48 GB total buffer, fits in 62 GB available RAM)
3. Creates `.checkpoint_SAM_TO_BAM` on success
4. Auto-chains to Step 7 (BAM indexing)

Launch command:
```bash
setsid bash /home/rayzw/tmp/daemon_sort.sh \
  < /dev/null >> /home/rayzw/DNA-Linux/hg38/logs/stage1_sort_daemon.log 2>&1 &
SORT_PID=$!
echo $SORT_PID > /home/rayzw/tmp/sort_daemon.pid
disown $SORT_PID
```

### Future Instruction
> **For any pipeline step expected to run more than 30 minutes, remind the user to disable Windows sleep before launching** (Settings → System → Power → Sleep → Never). `setsid` alone cannot protect against the host OS killing WSL. If Windows may sleep, the step will need to be re-run from the last successful file on disk.

---

## ISSUE-010: Multiple Redundant SHA256 Processes Computing Same File in Parallel

**Encountered:** 2026-06-08, Session 2
**Category:** Claude Code / Background task management

### Issue
While computing integrity checksums for Stage 2 output BAM (58 GB file), multiple `sha256sum` processes were spawned simultaneously via separate Bash background tasks. By the time the issue was caught, **3 separate SHA256 processes were running in parallel**, all computing the same checksum. Each process was consuming 100% CPU and I/O bandwidth, resulting in:
- Wasted computational resources
- Prolonged completion time (each waiting for the others' I/O)
- No benefit (computing the same hash 3 times produces 1 result)

### Cause
Insufficient tracking of spawned background tasks. Each time a checksum computation appeared to be incomplete or the output was unclear, a new background task was launched without verifying whether a previous one was still running. No central registry of active background tasks was maintained.

Timeline:
1. Launched `bb38tbymq` (checksum computation) — waiting for result
2. Spawned `b0h2z7ek3` (get final checksums) — thinking previous had finished
3. Spawned `blyt22hsm` (compute and store) — trying again after unclear output
4. Spawned `b21zrbrzj` (SHA256 hash direct) — one more retry
5. All 4 were running in parallel on the same 58GB file

### Solution
1. **Immediate:** Kill all redundant processes:
```bash
pkill -9 -f sha256sum
ps aux | grep sha256sum | grep -v grep  # verify clean
```

2. **Prevention:** Establish background task tracking rules:
   - Check for running processes **before** spawning a new background task
   - Use a centralized log file to track which computation is in progress
   - Include a timeout/timeout-with-retry mechanism instead of spawn-if-unclear pattern
   - Example:
```bash
# Check if SHA256 is already running
if pgrep -f "sha256sum.*Rizwan_processed.bam" > /dev/null; then
    echo "SHA256 already computing, waiting..."
    wait
else
    echo "Starting SHA256..."
    sha256sum ... &
fi
```

3. **Better approach:** Use atomic file locking for single-execution:
```bash
LOCK_FILE="/tmp/bam_checksum.lock"
if mkdir "$LOCK_FILE" 2>/dev/null; then
    trap "rmdir $LOCK_FILE" EXIT
    sha256sum /path/to/bam > result.txt
else
    echo "Checksum already running..."
    wait
fi
```

### Future Instruction
> **For any long-running background computation (checksums, sorting, variant calling):** ALWAYS check if the process is already running before spawning a new one. Use `pgrep -f "pattern"` to verify clean state. Better yet, implement a `.lock` file or semaphore to prevent duplicate launches. Never retry by spawning — poll the result file and wait for completion instead. Add a pre-flight check to `claude_progress_update.py` and any daemon launcher.

---

---

## ISSUE-011: WSL Path Translation Failure from PowerShell with Spaces in Path

**Encountered:** 2026-06-08, Session 3
**Category:** WSL / Windows integration / Build/Installation

### Issue
Attempting to install DeepVariant binary via `wsl -d Ubuntu -- bash install_script.sh` failed repeatedly with error: `wsl: Failed to translate 'G:\My Drive\Coding\Claude'`. The issue occurred when:
- Running wsl commands from PowerShell with working directory "G:\My Drive\Coding\Claude" (contains spaces)
- Running from Git Bash (wsl command translates paths incorrectly)
- Running from native Windows Bash

All attempts to invoke WSL failed with path translation errors, blocking binary installation.

### Cause
WSL's path translator attempts to convert the current working directory from Windows format to WSL format. The path "G:\My Drive\Coding\Claude" contains:
- Spaces (My Drive)
- Mixed path separators
- User context information

The translator fails when:
1. PowerShell invokes `wsl` with working directory containing spaces
2. Git Bash invokes `wsl` (uses different path context)
3. Bash tool context differs from PowerShell context

WSL succeeds only when invoked from contexts that properly escape or don't rely on working directory translation.

### Solution
**Don't rely on binary installation when working directory has spaces.** Use one of:
1. **Docker (Recommended):** `docker run gcr.io/deepvariant-docker/deepvariant:latest` — no path translation issues
2. **Explicit absolute paths:** Write install script to WSL filesystem first, then execute
3. **Change working directory:** Move to path without spaces before invoking wsl commands
4. **Use `-e` flag:** `wsl -d Ubuntu -e bash -c "commands"` (partial success)

For DeepVariant specifically: Use Docker image instead of binary when path translation blocks installation.

### Future Instruction
> **For any large binary installations from Windows with complex path names:** Use Docker instead of trying to install binaries via WSL when you encounter path translation errors. Docker avoids the entire path translation layer and is faster to deploy. If binary installation is mandatory, change working directory to a simple path (e.g., C:\Temp) with no spaces before invoking wsl commands. **IMPORTANT: Document installation/build issues immediately as you encounter them — do NOT skip "small" issues.**

> **Update (2026-06-08):** The **Bash tool** (Git Bash) invokes WSL cleanly with `wsl -d Ubuntu -- bash -c "..."` — no CWD-translation error — and is now the preferred path for WSL commands from Claude. PowerShell still works but prints the (harmless) translate warning. Keep Linux paths inside the quoted `bash -c` string. See [[Insights/Claude-Code-Environment]].

---

## ISSUE-012: DeepVariant `--model_type=WGS_PCR` and `PCR_FREE` Not Valid in Current Releases

**Encountered:** 2026-06-08, Session 3
**Category:** Tool / Variant calling / Model selection

### Issue
Attempted to run variant calling with `--model_type=WGS_PCR` (for MGI WGS-PCR library model). Docker rejected the flag:
```
FATAL Flags parsing error: flag --model_type=WGS_PCR: value should be one of 
<WGS|WES|PACBIO|ONT_R104|HYBRID_PACBIO_ILLUMINA|MASSEQ|RNASEQ>
```

The goal was to benchmark three model types: Generic WGS vs MGI WGS-PCR trained vs MGI PCR-free trained. This failed completely — the latter two model types do not exist as valid `model_type` values in current DeepVariant releases (1.6.0, 1.9.0, 1.10.0).

### Cause
DeepVariant **deprecated the PCR/PCR-free model distinction** in the evolution from 1.6 → 1.9 → 1.10 line. The single `WGS` model now handles both PCR and PCR-free libraries by learning the error signature directly from the data channels (base quality, GQ, etc.) rather than requiring pre-declaration.

The confusion stems from:
1. Old DeepVariant releases (pre-1.8) had explicit `WGS_PCR` and `PCR_FREE` model types
2. Current releases (1.9+) unified into a single `WGS` model
3. MGI-specific **trained models** (custom checkpoints) exist but are accessed via `--customized_model=/path/to/checkpoint`, NOT via `model_type` flag
4. The MEMORY.md standing rule referenced testing "MGI WGS-PCR trained" and "MGI PCR-free trained" as separate `model_type` options — this is outdated

### Solution
1. **For the Rizwan sample (PCR-free library):** Use `--model_type=WGS` — the current unified model handles PCR-free input correctly
2. **If true MGI-trained models are needed later:** Source from MGI's GitHub repository (e.g., `github.com/MGI-tech-bioinformatics/DeepVariant`) and invoke as custom checkpoint via `--customized_model=/path/to/mgi_model_checkpoint` (requires validation on a truth set before production use)
3. **For this session:** Abandon the three-model benchmark plan. Use `WGS` model on chr22 for validation, then proceed to full 58 GB production run.

### Future Instruction
> **DeepVariant `model_type` currently supports:** `WGS | WES | PACBIO | ONT_R104 | HYBRID_PACBIO_ILLUMINA | MASSEQ | RNASEQ`. The PCR/PCR-free distinction is **deprecated and removed** — do not attempt `--model_type=WGS_PCR` or `PCR_FREE`. Use `WGS` for all Illumina-like libraries (including MGI DNBSEQ). Only use `--customized_model` if deploying MGI's own trained checkpoints from their GitHub, and validate against a truth set first. Update MEMORY.md to remove the "test three models" rule.

---

---

## ISSUE-013: Local Git Clone Pointed to Wrong Remote

**Encountered:** 2026-06-08, Session 3
**Category:** GitHub / Git configuration

### Issue
The local clone at `/home/rayzw/Claude_WGS_Normalization-Stages-1-2-3-4` (named with `Claude_` prefix) had its `origin` remote pointing to `https://github.com/RizwanSiddiqiGIT/WGS_Normalization-Stages-1-2-3-4.git` — the repo *without* the `Claude_` prefix. This caused:
1. Incorrect repository identification in documentation
2. Confusion about which repo is canonical for Claude workflows
3. Risk of pushing to the wrong remote if not verified

### Cause
The local clone was created or initialized with the wrong remote URL. Git allows any clone name and any remote URL independently — the `Claude_WGS_...` directory name does not constrain which repo it points to.

### Solution
Updated the local clone's remote URL:
```bash
git -C /home/rayzw/Claude_WGS_Normalization-Stages-1-2-3-4 \
  remote set-url origin \
  https://github.com/RizwanSiddiqiGIT/Claude_WGS_Normalization-Stages-1-2-3-4.git
```

Verified:
```bash
git -C /home/rayzw/Claude_WGS_Normalization-Stages-1-2-3-4 remote -v
# Now correctly shows: https://github.com/RizwanSiddiqiGIT/Claude_WGS_Normalization-Stages-1-2-3-4.git
```

### Future Instruction
> **Before using a local repo, always verify the remote URL matches the intended GitHub repository.** Use `git -C <path> remote -v` to confirm. The directory name is not authoritative — check the actual remote. Document the canonical repo URL in memory / CLAUDE.md. When setting up new clones, use explicit `git clone <url>` rather than renaming or reassigning remotes later.

---

*Last updated: 2026-06-08*
*Add new issues at the bottom with incremented ISSUE-NNN ID.*
