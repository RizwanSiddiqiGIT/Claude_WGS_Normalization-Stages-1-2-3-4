#!/usr/bin/env python3
"""Generate a lightweight auto-refreshing HTML progress page for pipeline stages."""

from __future__ import annotations

import argparse
import datetime as dt
import html
import os
import subprocess
import time
from pathlib import Path


def human_size(num: int) -> str:
    value = float(num)
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if value < 1024 or unit == "TB":
            return f"{value:.1f} {unit}" if unit != "B" else f"{int(value)} B"
        value /= 1024
    return f"{num} B"


def run_command(command: list[str]) -> str:
    try:
        return subprocess.check_output(command, text=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as exc:
        return exc.output
    except FileNotFoundError as exc:
        return str(exc)


def matching_processes(patterns: list[str]) -> list[str]:
    if not patterns:
        return []
    ps_output = run_command(["ps", "-eo", "pid,ppid,etime,%cpu,%mem,rss,cmd"])
    lines = []
    for line in ps_output.splitlines():
        if "progress_tracker.py" in line:
            continue
        if any(pattern in line for pattern in patterns):
            lines.append(line)
    return lines


def file_rows(paths: list[Path]) -> list[tuple[str, str, str]]:
    rows = []
    for root in paths:
        if not root.exists():
            rows.append((str(root), "missing", ""))
            continue
        if root.is_file():
            stat = root.stat()
            rows.append((str(root), human_size(stat.st_size), format_mtime(stat.st_mtime)))
            continue
        for path in sorted(root.glob("*")):
            if path.is_file():
                stat = path.stat()
                rows.append((str(path), human_size(stat.st_size), format_mtime(stat.st_mtime)))
    return rows[-80:]


def format_mtime(timestamp: float) -> str:
    return dt.datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d %H:%M:%S")


def tail_file(path: Path, lines: int) -> str:
    if not path.exists():
        return f"Log file not found: {path}"
    if path.stat().st_size == 0:
        return f"Log file is empty: {path}"
    output = run_command(["tail", "-n", str(lines), str(path)])
    return output.rstrip()


def infer_status(processes: list[str], log_text: str, expected_files: list[Path]) -> str:
    missing_expected = [path for path in expected_files if not path.exists() or path.stat().st_size == 0]
    lower_log = log_text.lower()
    if "error" in lower_log or "[fail]" in lower_log or "exception" in lower_log:
        return "ATTENTION"
    if processes:
        return "RUNNING"
    if expected_files and not missing_expected:
        return "COMPLETE"
    return "IDLE_OR_WAITING"


def render_html(args: argparse.Namespace) -> str:
    now = dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_path = Path(args.log)
    watch_paths = [Path(item) for item in args.watch]
    expected_files = [Path(item) for item in args.expect]
    processes = matching_processes(args.pattern)
    log_text = tail_file(log_path, args.tail_lines)
    status = infer_status(processes, log_text, expected_files)
    files = file_rows(watch_paths + expected_files)

    status_class = {
        "RUNNING": "running",
        "COMPLETE": "complete",
        "ATTENTION": "attention",
    }.get(status, "idle")

    process_block = "\n".join(html.escape(line) for line in processes) or "No matching process currently running."
    log_block = html.escape(log_text)
    file_rows_html = "\n".join(
        f"<tr><td>{html.escape(path)}</td><td>{html.escape(size)}</td><td>{html.escape(mtime)}</td></tr>"
        for path, size, mtime in files
    )

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="refresh" content="{args.interval}">
  <title>{html.escape(args.stage)} Progress</title>
  <style>
    :root {{
      color-scheme: light dark;
      --bg: #f6f7f9;
      --fg: #1f2933;
      --muted: #64748b;
      --panel: #ffffff;
      --border: #d8dee9;
      --running: #1d4ed8;
      --complete: #047857;
      --attention: #b91c1c;
      --idle: #6b7280;
    }}
    @media (prefers-color-scheme: dark) {{
      :root {{
        --bg: #0f172a;
        --fg: #e5e7eb;
        --muted: #94a3b8;
        --panel: #111827;
        --border: #334155;
      }}
    }}
    body {{
      margin: 0;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: var(--bg);
      color: var(--fg);
    }}
    main {{
      max-width: 1180px;
      margin: 0 auto;
      padding: 24px;
    }}
    h1, h2 {{
      margin: 0 0 12px;
      letter-spacing: 0;
    }}
    h1 {{
      font-size: 28px;
    }}
    h2 {{
      font-size: 18px;
      margin-top: 24px;
    }}
    .top {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 12px;
      margin: 18px 0;
    }}
    .box {{
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 14px;
    }}
    .label {{
      color: var(--muted);
      font-size: 13px;
      margin-bottom: 6px;
    }}
    .value {{
      font-size: 18px;
      font-weight: 650;
      overflow-wrap: anywhere;
    }}
    .status {{
      display: inline-block;
      border-radius: 999px;
      padding: 6px 12px;
      color: white;
      font-size: 14px;
      font-weight: 700;
      background: var(--idle);
    }}
    .status.running {{ background: var(--running); }}
    .status.complete {{ background: var(--complete); }}
    .status.attention {{ background: var(--attention); }}
    pre {{
      white-space: pre-wrap;
      overflow-wrap: anywhere;
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 14px;
      line-height: 1.45;
      max-height: 420px;
      overflow: auto;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 8px;
      overflow: hidden;
    }}
    th, td {{
      border-bottom: 1px solid var(--border);
      padding: 9px 10px;
      text-align: left;
      font-size: 14px;
      overflow-wrap: anywhere;
    }}
    th {{
      color: var(--muted);
      font-size: 13px;
    }}
  </style>
</head>
<body>
<main>
  <h1>{html.escape(args.stage)} Progress</h1>
  <div class="top">
    <div class="box"><div class="label">Status</div><div class="value"><span class="status {status_class}">{status}</span></div></div>
    <div class="box"><div class="label">Last Updated</div><div class="value">{html.escape(now)}</div></div>
    <div class="box"><div class="label">Refresh</div><div class="value">Every {args.interval}s</div></div>
    <div class="box"><div class="label">Log</div><div class="value">{html.escape(str(log_path))}</div></div>
  </div>

  <h2>Matching Processes</h2>
  <pre>{process_block}</pre>

  <h2>Watched Files</h2>
  <table>
    <thead><tr><th>Path</th><th>Size</th><th>Modified</th></tr></thead>
    <tbody>{file_rows_html}</tbody>
  </table>

  <h2>Recent Log</h2>
  <pre>{log_block}</pre>
</main>
</body>
</html>
"""


def write_html(output: Path, content: str) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp = output.with_suffix(output.suffix + ".tmp")
    tmp.write_text(content, encoding="utf-8")
    os.replace(tmp, output)


def main() -> int:
    parser = argparse.ArgumentParser(description="Write an auto-refreshing pipeline progress HTML page.")
    parser.add_argument("--stage", required=True)
    parser.add_argument("--log", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--watch", action="append", default=[])
    parser.add_argument("--expect", action="append", default=[])
    parser.add_argument("--pattern", action="append", default=[])
    parser.add_argument("--interval", type=int, default=60)
    parser.add_argument("--tail-lines", type=int, default=80)
    parser.add_argument("--once", action="store_true")
    args = parser.parse_args()

    output = Path(args.output)
    while True:
        write_html(output, render_html(args))
        if args.once:
            return 0
        time.sleep(args.interval)


if __name__ == "__main__":
    raise SystemExit(main())

