# 🧠 Claude Knowledge Base

> Session memory, issue log, and pipeline documentation for Claude Code + WGS pipeline work.

---

## 📋 Quick Navigation

| Section | Description |
|---------|-------------|
| [[CLAUDE_SESSION_START]] | **Read first** — current state, rules, routing |
| [[MEMORY]] | Auto-loaded session index |
| [[ISSUE_LOG]] | All issues (cause + solution + future instruction) |
| [[PROJECT_PATHS]] | Every file/path across Claude Code, Windows, WSL |

---

## 🔴 Active Right Now

- **Stage 3 — DeepVariant variant calling.** chr22 validation ✅ done; full-BAM production run pending.
- Tool: DeepVariant 1.10.0 · `--model_type=WGS` · 24 shards.
- → [[Pipeline/Stage3-VariantCalling]]

---

## 📁 Vault Structure

```
memory/
├── HOME.md                      ← You are here
├── CLAUDE_SESSION_START.md      ← Read-first on-ramp
├── MEMORY.md                    ← Auto-loaded session index
├── ISSUE_LOG.md                 ← All issues (+ index table)
├── PROJECT_PATHS.md             ← Path map
├── Pipeline/
│   ├── Stage1-Overview.md   Stage2-MarkDuplicates.md
│   ├── Stage3-VariantCalling.md   Stage4-Normalization.md
│   └── Hardware-Optimization.md
├── Insights/
│   ├── DeepVariant.md   MGI-DNBSEQ-Platform.md
│   ├── BQSR-Decision.md   Claude-Code-Environment.md
│   └── GitHub.md
├── Procedures/
│   └── Preflight-Check-Routine.md   Phase-Metrics-Reference.md
├── Quality/
│   └── Stage2-Postflight-Check.md   BAM-Integrity-Registry.md
├── Tools/
│   └── BWA-MEM2.md   fastp.md
├── Reference/
│   └── WSL-Execution.md   Process-Daemon.md
└── Templates/
    └── Issue-Template.md
```

---

## 🏷️ Tags Used

`#issue` · `#pipeline` · `#tool` · `#insight` · `#wsl` · `#claude` · `#decision` · `#resolved` · `#active`

---

## ⚡ How Claude Uses This Vault

1. Auto-loads [[MEMORY]] → opens [[CLAUDE_SESSION_START]] for current state.
2. On an **issue**: append to [[ISSUE_LOG]], update the related note, bump [[MEMORY]] if it's a new rule.
3. On an **insight**: add/extend an `Insights/` note, link it from [[CLAUDE_SESSION_START]].

*Last updated: 2026-06-08*
