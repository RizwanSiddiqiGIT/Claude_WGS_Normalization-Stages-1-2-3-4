# Logging System Reference

## Overview

This WGS pipeline uses a **multi-agent knowledge logging system** to track execution, issues, and insights across runs. Each entry carries:
- **Author** (which agent discovered/tested it: Claude, Codex, etc.)
- **Confidence score** (0–10, auto-promotes at threshold)
- **Comparative metrics** (for choosing between solutions)

The system prevents repeated failures, surfaces proven patterns, and enables cross-agent learning.

---

## The Three Logs

### EXECUTION_LOG
**What was run, and did it work?**

| Field | Purpose |
|-------|---------|
| Entry ID | `EXEC-YYYY-MM-DD-HHMM-slug` (unique per run) |
| Author | Which agent ran it (Claude, Codex, etc.) |
| Procedure ID | `PROC-slug` (reused by repeats of the same procedure) |
| Status | `✅ success` · `❌ failure` · `⚠️ partial` · `❓ inconclusive` · `⏳ in-progress` |
| Duration | Run time (HHmm) |
| Metrics | input size, output size, resource peak, warnings |

**Example:**
```
EXEC-2026-06-10-1230 — Build CADD tabix index (fix)
Author: Claude
Procedure ID: PROC-cadd-tabix-index (canonical)
Status: ✅ success
Duration: 12m54s
```

---

### ISSUE_LOG
**What broke, why, and what's the fix?**

| Field | Purpose |
|-------|---------|
| Issue ID | Legacy `ISSUE-NNN` (backward compat) or new `ISSUE-YYYY-MM-DD-slug` |
| Author | Which agent hit it first |
| Fingerprint | `{tool · error_class · trigger_pattern}` — match this before creating duplicates |
| Confidence | 0–10 (starts at 0, +1 per successful fix, -1 per recurrence-after-fix) |
| Status | `provisional` · `likely-works` · `proven` · `archived` |
| Solutions | all attempts + metrics (best marked) |

**Promotion trigger:** When **confidence ≥ 9** AND **recurrence-free ≥ 30 days** → graduate to [[STANDARD_PRACTICES_LOG]]

**Example:**
```
ISSUE-2026-06-10-cadd-missing-tabix-index
Author: Claude
Fingerprint: {vep · missing-tabix-index · plugin instantiation}
Confidence: 9/10
Status: proven (eligible for standard-practice promotion)

Solution A: tabix -s 1 -b 2 -e 2 ✅ 100% success (13m build)
Solution B: tabix -p gff ❌ 0% success (silent failure)
```

---

### INSIGHTS_LOG
**What we learned, and is it still true?**

| Field | Purpose |
|-------|---------|
| Insight ID | `INS-YYYY-MM-DD-slug` |
| Author | Who discovered it |
| Confirmations | Count by which agents (Claude, Codex, etc.) |
| Confidence | 0–10 (promoted to standing rule at 3+) |
| Depends-on | Environment (VEP version, CADD format, etc.) |
| Status | `provisional` · `confirmed` · `promoted` · `⚠️ stale-reverify` |

**Promotion trigger:** When **confirmations ≥ 3** → add to [[CLAUDE_SESSION_START]] standing rules

**Example:**
```
INS-2026-06-10-vep-cache-speedup
Author: Claude
Confirmations: 0 (awaiting canonical run)
Confidence: 0/10 (expected 3–4× faster than REST, unproven)
Status: provisional

Discovery: local VEP cache (~3–4× speedup vs. REST API)
Confirm by: successful PROC-vep-cadd-annotate run
```

---

### STANDARD_PRACTICES_LOG
**How should we handle this reliably?** (graduated issues)

When an issue reaches **proven** status (confidence 9+, 30 days stable), it graduates here with:
- **Procedure** (step-by-step instructions)
- **Options evaluated** (comparative table of all solutions tried)
- **Cross-agent confirmations** (which agents tested it, when, result)

**Example:**
```
STANDARD-2026-06-10-cadd-tabix-index (graduated from ISSUE-2026-06-10-cadd-missing-tabix-index)

Procedure:
  tabix -s 1 -b 2 -e 2 whole_genome_SNVs.tsv.gz

Options evaluated:
  Option A: tabix -s 1 -b 2 -e 2
    Author: Claude | Date: 2026-06-10 | Success: 100% (1/1 runs)
    Also tested by: Codex (2026-06-15, ✅ confirmed)
    Build time: 13m | Index size: 2.7 MB | Cost: ~$0.05
  
  Option B: tabix -p gff
    Author: Claude | Date: 2026-06-10 | Success: 0%
    Why: GFF preset assumes wrong columns; silent failure
```

---

## Confidence Scoring

### ISSUE confidence (0–10)
```
baseline:      0 (new issue)
+1 per:        successful fix attempt
-1 per:        recurrence after fix (solution is suspect)
+1 per week:   stable (no recurrences in 7 days)
max:           10 (very stable)
min:           0

Thresholds:
  < 3:    ⚠️ provisional (experimental, unproven)
  3–5:    🟡 likely-works (multiple successes, watch for regression)
  6–8:    🟢 proven (stable, low recurrence)
  9–10:   ✅ archive-ready (no recurrences in 30+ days → promote to STANDARD)
```

### PROC success rate (%)
```
success_rate = (successful_runs / total_runs) × 100

60–85%:   🟡 provisional (mostly works, some failures)
85–95%:   🟢 stable (reliable, rare failures)
95%+:     ✅ proven (ready for standing practice when 5 consecutive successes)
```

### INSIGHT confirmations (0–10)
```
+2 per:        confirmation by different agent
-1 per:        environment change (dependency bump)
max:           10

0:        ❓ unproven (newly discovered)
1–2:      🟡 provisional (confirmed by 1–2 agents)
3+:       🟢 confirmed (ready to promote to standing rule in CLAUDE_SESSION_START)
⚠️:       stale-reverify (environment changed, retest needed)
```

---

## Multi-Agent Learning

Each log entry has an **Author** field. This enables:

| Use case | Example |
|----------|---------|
| **Attribution** | "Claude discovered CADD tabix issue on 2026-06-10" |
| **Cross-learning** | "Codex hit the same CADD issue independently; apply Option A" |
| **Comparative metrics** | "Claude: 13m build; Codex: 15m build (different hardware, same solution)" |
| **Causality** | "Claude-specific issue" vs. "industry-wide (multiple agents hit it)" |

**Workflow:** When one agent tests a solution, others cite it:
```
Solution A: tabix -s 1 -b 2 -e 2
Author: Claude (2026-06-10)
Tested also by: Codex (2026-06-15, ✅ confirmed)
Environment: both VEP 115.2, CADD GRCh38 v1.7
```

---

## Archival & Promotion

| From | To | Trigger |
|-----|----|---------| 
| ISSUE_LOG | STANDARD_PRACTICES_LOG | confidence ≥ 9 + 30 days recurrence-free |
| INSIGHTS_LOG | CLAUDE_SESSION_START standing rules | 3+ confirmations + stable environment |
| EXECUTION_LOG | Vault/Archive/ | PROC success ≥ 95% + 5 consecutive successes |

**Timeline:**
1. Issue filed → ISSUE_LOG with confidence 0
2. Fix tested → confidence +1; if recurrence, -1 (recurrence-after-fix counter increments)
3. 30 days with no recurrence → confidence 9+
4. Promote to STANDARD_PRACTICES_LOG; archive from ISSUE_LOG

---

## Querying the logs

**Before running a command:** consult the ledger
```bash
# Find CADD solutions
grep -r "cadd" ISSUE_LOG.md STANDARD_PRACTICES_LOG.md EXECUTION_LOG.md

# Check PROC success rate
grep "PROC-vep-cadd-annotate" EXECUTION_LOG.md

# Find insights by author
grep "Author: Claude" INSIGHTS_LOG.md
```

**The preflight hook does this automatically:** Before any `vep`, `tabix`, `docker`, etc. command, it surfaces matching ISSUE + PROC records from the ledger as context.

---

## Workflow: issue → standard

**Step 1: File issue** (EXECUTION fails)
```
EXEC-2026-06-10-1207: VEP+CADD annotation fails
→ ISSUE-2026-06-10-cadd-missing-tabix-index filed
  confidence: 0
  status: provisional
  author: Claude
```

**Step 2: Fix tested** (EXECUTION succeeds)
```
EXEC-2026-06-10-1230: Build CADD tabix index
→ ISSUE-2026-06-10-cadd-missing-tabix-index updated
  confidence: +1 → 1
  recurrence-after-fix: 0
  author: Claude
  status: likely-works
```

**Step 3: Repeats succeed** (PROC accumulates runs)
```
PROC-cadd-tabix-index
runs: 3 (canonical + 2 repeats)
success rate: 100%
confidence: 3 → 5 → 9 (stable, no recurrence)
```

**Step 4: Promotion** (30 days stable)
```
ISSUE-2026-06-10-cadd-missing-tabix-index
confidence: 9
recurrence-free: 2026-06-10 to 2026-07-10
status: proven
↓ PROMOTE
STANDARD-2026-06-10-cadd-tabix-index
+ add to CLAUDE_SESSION_START standing rule
+ archive issue
```

---

## See also

- [[Reference/Three-Log-System]] — full mechanics, formulas, scoring model
- [[EXECUTION_LOG]] — current runs
- [[ISSUE_LOG]] — active problems
- [[INSIGHTS_LOG]] — learnings with lifecycle
- [[STANDARD_PRACTICES_LOG]] — proven solutions
- [[CLAUDE_SESSION_START]] — standing rules (promoted insights)
