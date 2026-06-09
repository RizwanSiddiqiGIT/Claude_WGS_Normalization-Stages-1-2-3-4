---
name: github-setup-known-issues-best-practices
metadata: 
  node_type: memory
  tags: 
    - github
    - git
    - version-control
    - insight
    - best-practice
  date: 2026-06-08
  status: active
  originSessionId: 06adf67b-8daa-4ab7-98a8-694fe1141efa
---

# GitHub — Insights, Solutions & Best Practices

## Current setup (verified 2026-06-08, corrected)
- **GitHub user:** `RizwanSiddiqiGIT`
- **Canonical Claude repo:** `Claude_WGS_Normalization-Stages-1-2-3-4`
  → `https://github.com/RizwanSiddiqiGIT/Claude_WGS_Normalization-Stages-1-2-3-4.git` ✅ **(corrected 2026-06-08)**
- **Repos live in WSL — not Windows/Drive.** Neither `G:\My Drive\Coding\Claude` nor the Obsidian vault (`C:\...\.claude\...\memory`) is a git repo.
- **`gh` CLI:** NOT installed (Windows or WSL). Operations use plain `git` over HTTPS.

| WSL path | Role |
|----------|------|
| `/home/rayzw/Claude_WGS_Normalization-Stages-1-2-3-4` | **ACTIVE CANONICAL** — `main` on correct remote, 59 tracked files. Last commit `a512031` 2026-06-08 16:03. ✅ Remote URL corrected to `Claude_WGS_...` (was pointing to `WGS_...`). |
| `/home/rayzw/WGS_Normalization-Stages-1-2-3-4` | Older clone of **different** remote (`WGS_...` without Claude prefix) — consider retiring. |
| `/home/rayzw/wgs-metabolic-pipeline` | Separate project — origin = `openai-codex.git` fork, upstream = `wgs-metabolic-pipeline.git` (Codex agent) |

## ✅ Already good
- `.gitignore` excludes genomic data: `*.bam *.bai *.sam *.cram *.fq.gz *.fastq.gz *.vcf *.vcf.gz *.tfrecord*` + dirs `variants_output/ qc/ logs/ tmp/`. (`*.vcf.gz` also covers `*.g.vcf.gz`.)
- **No data files tracked** (verified). 59 tracked files = scripts + docs only. 👍

## ⚠️ Known issues & solutions

### 1. Vault ↔ repo duplication (STALE) — feeds Stage 2
The Obsidian vault (Windows) and the repo (WSL) each carry their **own** `MEMORY.md` / `ISSUE_LOG.md`. **This session's restructure edited the VAULT only — the repo copies are now stale and lack the new `Insights/` + per-stage `Pipeline/` notes.** Until the SSOT location is decided (Stage 2), either mirror changes manually or pick one canonical home. See [[CLAUDE_SESSION_START]].

### 2. `.gitattributes` MISSING → CRLF/BOM breaks shell scripts in WSL
Windows/PowerShell authoring can inject CRLF or a UTF-8 BOM, making WSL bash fail with `bad interpreter: /bin/bash^M` or an unrecognized `#!`. We hit BOM issues this session. **Solution — add `.gitattributes`:**
```gitattributes
* text=auto eol=lf
*.sh  text eol=lf
*.py  text eol=lf
*.md  text eol=lf
*.gz  binary
*.png binary
```
Author scripts as **UTF-8 without BOM** (PowerShell `-Encoding ascii` or `utf8NoBOM`). Note: adding this later triggers a one-time renormalization diff.

### 3. Reference genome not ignored
`.gitignore` lacks FASTA/index patterns. The 3 GB reference would be tracked if copied into a repo dir. **Solution — add:**
```gitignore
*.fa
*.fai
*.dict
*.fa.*
ref_genome/
```

### 4. Two clones of the same repo
`Claude_WGS_...` and `WGS_...` track the same remote → easy to edit the wrong one. **Solution:** treat `Claude_WGS_...` as canonical; archive the other once confirmed it isn't ahead.

### 5. Uncommitted work in active repo (2026-06-08)
Pending: modified `*.py`, a deleted `config.env`, and untracked `claude_*.md` docs. Review and commit deliberately — **don't `git add .`** next to large outputs.

## 📋 Standing best practices
- **Never commit genomic data.** GitHub limits: 100 MB/file hard reject, 50 MB warning, repo ideally < 1 GB. Keep `.gitignore` ahead of new output types.
- **No secrets in git.** Ignore `.env`, tokens, `settings.local.json`. If one is committed, **rotate it** — deletion doesn't purge history.
- **Commit hygiene:** small focused commits; imperative messages ("Add Stage 4 normalization"); end Claude-authored commits with the `Co-Authored-By: Claude` trailer.
- **Branch before non-trivial work on `main`;** push only when the user asks.
- **`git status` before every commit;** `git pull` before push; never blind `git add .`.
- **Verify which clone** you're in before committing (`git -C <path> ...` or `git remote -v`).

## 🔗 Connection to Stage 2 (multi-agent SSOT)
The repo is the natural cross-agent home (Codex already uses an `openai-codex` fork here). When the canonical KB location is chosen, the repo-root convention files — `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md` — should be **thin pointers** into the knowledge base.

## ▶️ Recommended actions (need go-ahead)
1. **Remote corrected ✅** — local clone now points to `Claude_WGS_Normalization-Stages-1-2-3-4`. See [[ISSUE_LOG#ISSUE-013]].
2. Add `.gitattributes` (LF) + extend `.gitignore` (`*.fa`, `ref_genome/`) to the active repo.
3. Retire the `/home/rayzw/WGS_Normalization-Stages-1-2-3-4` clone (wrong remote).
4. Resolve vault ↔ repo SSOT (Stage 2) — and decide whether the vault itself should be git-backed.
5. Optionally install `gh` for easier PR/issue workflows.
