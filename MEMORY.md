# Memory Index

> **Auto-loaded each session.** First action: open [[CLAUDE_SESSION_START]] for the current-state on-ramp, then read only task-relevant notes. Full vault map: [[HOME]].

## 🚦 Start Here
- [[CLAUDE_SESSION_START]] — current state, critical rules, routing (**READ FIRST**)
- [[HOME]] — vault map & navigation
- [[PROJECT_PATHS]] — every file/path (Claude Code, Windows, WSL)
- [[ISSUE_LOG]] — all issues (currently **ISSUE-013**)

## 🔴 MANDATORY — Document Issues
Every time something goes wrong or behaves unexpectedly, do this AUTOMATICALLY, before proceeding:
1. **STOP** and document — don't just fix and move on.
2. Add an entry to [[ISSUE_LOG]] (template: [[Templates/Issue-Template]]) — **ISSUE-NNN** (increment; current: **013**), with Issue → Cause → Solution → Future Instruction.
3. Update [[CLAUDE_SESSION_START]] / this file if it creates a new standing rule.
4. Update the relevant Tool / Pipeline / Insight note.
5. Tell the user: "Documenting as ISSUE-NNN."

**Non-negotiable.** Small issues count — patterns only emerge from complete logs.

## 🟡 MANDATORY — Document Insights
On any new behavioural / architectural / tool / design discovery (not just failures): add or extend a note under `Insights/` and link it from [[CLAUDE_SESSION_START]]. Label **INSIGHT** vs **ISSUE** so they stay distinct. Be proactive — you have note-making power; use it.

## 📂 Vault Map
- **Pipeline:** [[Pipeline/Stage1-Overview]] · [[Pipeline/Stage2-MarkDuplicates]] · [[Pipeline/Stage3-VariantCalling]] · [[Pipeline/Stage4-Normalization]] · [[Pipeline/Hardware-Optimization]]
- **Insights:** [[Insights/DeepVariant]] · [[Insights/MGI-DNBSEQ-Platform]] · [[Insights/BQSR-Decision]] · [[Insights/Claude-Code-Environment]] · [[Insights/GitHub]]
- **Procedures:** [[Procedures/Preflight-Check-Routine]] · [[Procedures/Phase-Metrics-Reference]]
- **Quality:** [[Quality/Stage2-Postflight-Check]] · [[Quality/BAM-Integrity-Registry]]
- **Tools:** [[Tools/BWA-MEM2]] · [[Tools/fastp]]
- **Reference:** [[Reference/WSL-Execution]] · [[Reference/Process-Daemon]] · [[PROJECT_PATHS]]
- **Obsidian app:** `memory\Obsidian\Obsidian.exe` (vault = this dir; `Ctrl+T` → Issue-Template)

## 🧬 Pipeline State (one-liner)
Stage 1 ✅ · Stage 2 ✅ · **Stage 3 🔄 (chr22 validated; full run pending)** · Stage 4 ⏳
→ detail in [[CLAUDE_SESSION_START]] + per-stage notes.

## 🔑 Top Standing Rules (full list in [[CLAUDE_SESSION_START]])
- WSL: Bash tool `wsl -d Ubuntu -- bash -c "..."` (clean); PowerShell warns on CWD but runs → [[Insights/Claude-Code-Environment]]
- Long jobs >30 min → disable Windows sleep → [[ISSUE_LOG#ISSUE-009]]
- Background procs: `setsid ... < /dev/null & disown` + `pgrep` pre-check → [[Reference/Process-Daemon]]
- DeepVariant: `--model_type=WGS`, v1.10.0 → [[Insights/DeepVariant]]
