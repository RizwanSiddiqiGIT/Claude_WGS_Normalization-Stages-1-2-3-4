# Memory Index

## How Issues Are Documented
Every issue gets logged in [ISSUE_LOG.md](ISSUE_LOG.md) with: Issue → Cause → Solution → Future Instruction.
**Read ISSUE_LOG.md at the start of any session involving this pipeline.**

## Claude Self-Instruction: When Any Issue Occurs
**MANDATORY — do this AUTOMATICALLY every single time something goes wrong or an unexpected behavior is found:**
1. **STOP IMMEDIATELY** and document it — do not just fix and move on
2. **Add a new entry to ISSUE_LOG.md** using the structure in Templates/Issue-Template.md:
   - ISSUE-NNN (increment from last entry, current: ISSUE-011)
   - Issue: what went wrong / symptom
   - Cause: root cause analysis
   - Solution: exact commands or code that fixed it
   - Future Instruction: one clear rule Claude must follow going forward
3. Update MEMORY.md Quick Reference if the issue produces a new standing rule
4. Update the relevant Tool or Pipeline note if the issue affects a specific tool
5. **Report to user:** "Documenting as ISSUE-NNN" so user knows tracking is happening

**RULE:** Do NOT skip this even for "small" issues — patterns only emerge from complete logs. **This is non-negotiable.** Every issue must be logged before proceeding.

**Reminder:** You have been given the power to make notes on your own — USE IT proactively.

## Quick Reference

- [WSL command execution](Reference/WSL-Execution.md) — always write scripts first, pass to WSL via PowerShell; never inline complex bash in `wsl -d Ubuntu -- bash -c`
- [BWA-MEM2 daemon execution](Reference/Process-Daemon.md) — always use `setsid ... < /dev/null & disown`; `nohup` alone is NOT sufficient from Claude's Bash tool
- **Windows sleep kills WSL** — for any step > 30 min, remind user to disable sleep before launching (Settings → System → Power → Sleep → Never)
- [Issue Log](ISSUE_LOG.md) — full structured log of all issues (ISSUE-001 through ISSUE-010)
- **Background task management** — prevent duplicate long-running processes with `pgrep` pre-checks or lock files
- **DeepVariant for MGI/DNBSEQ data** — Rizwan data is MGI sequencer (DNB_Library1). Use platform-specific trained models from MGI GitHub repo, not generic WGS. Test three models: (1) Generic DeepVariant WGS, (2) MGI WGS-PCR trained, (3) MGI PCR-free trained. Choose based on validation set comparison, then use for production.

## Pipeline State

- WGS pipeline Stage 1 prereqs — ref_genome was deleted 2026-06-07; read `~/DNA-Linux/STAGE1_RESTART_CONTEXT.md` before running Stage 1 (download + re-index both references first)
- **Stage 1: COMPLETE ✅ (2026-06-08 09:55 EDT)**
  - Output: `/home/rayzw/DNA-Linux/hg38/Rizwan_sorted.bam` (55G) + `.bai`
  - Quality validated: 92.4% reads mapped, 761.99M alignment lines
  
- **Stage 2: READY FOR LAUNCH ✅**
  - Pre-flight check: ALL PASSED (15/15 checks)
  - Quick test (chr22): SUCCESS — Picard MarkDuplicates works, BAM index created, 1.32% dup rate
  - Ready to run: `bash stage2_full_run.sh`
  - Expected duration: 2-3 hours (Picard MarkDuplicates on 55GB BAM)
  - Output: `/home/rayzw/DNA-Linux/hg38/Rizwan_processed.bam` + metrics
