---
name: claude-code-environment-bash-tool-powershell-wsl
metadata: 
  node_type: memory
  tags: 
    - claude
    - wsl
    - environment
    - execution
    - insight
  date: 2026-06-08
  status: active
  originSessionId: 06adf67b-8daa-4ab7-98a8-694fe1141efa
---

# Claude Code Environment — Executing in WSL

> ⚠️ **Supersedes the blanket "never use the Bash tool for WSL" rule** in `feedback_wsl_execution.md`. This session tested both paths directly; findings below are current.

## Two execution tools, two behaviors (verified 2026-06-08)
| Tool | Underlying shell | Invoking WSL |
|------|------------------|--------------|
| **Bash tool** | Git Bash (MINGW64) | `wsl -d Ubuntu -- bash -c "..."` → **works cleanly**, no path-translation error |
| **PowerShell tool** | Windows PowerShell | `wsl -- ...` → prints `Failed to translate 'G:\My Drive\Coding\Claude'` (CWD has spaces) but **still runs** the command in WSL |

## Why
- The PowerShell error is WSL failing to map the **current working directory** (`G:\My Drive\Coding\Claude`, spaces) into the distro. It's a CWD-translation *warning*, not a command failure — output still returns after it.
- The Bash tool doesn't trigger that CWD translation, so `wsl -d Ubuntu -- bash -c` is the cleaner path.

## Rules
1. **Prefer the Bash tool** with `wsl -d Ubuntu -- bash -c "..."` for WSL commands.
2. **Keep Linux paths INSIDE the quoted `bash -c "..."` string.** Do NOT pass `/home/rayzw/...` as a bare argument at the Git Bash level — MSYS path conversion can rewrite it to `C:/Program Files/Git/home/rayzw/...`. Inside the quoted string, paths reach bash untouched.
3. For complex / multi-line scripts, still **write a script file first** (avoids quoting issues), then run it: `wsl -d Ubuntu -- bash /home/rayzw/tmp/script.sh`.
4. Read / write WSL files from Windows tools (Read/Write/Edit) via the UNC path: `\\wsl.localhost\Ubuntu\home\rayzw\...`.

## Related
- [[ISSUE_LOG#ISSUE-001]] — original "write scripts first" rule (still valid for complex bash)
- [[ISSUE_LOG#ISSUE-011]] — PowerShell CWD path-translation failure (+ 2026-06-08 update)
- [[Reference/WSL-Execution]] · [[Reference/Process-Daemon]]
