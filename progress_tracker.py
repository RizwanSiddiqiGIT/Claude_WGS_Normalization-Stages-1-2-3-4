#!/usr/bin/env python3
"""Generate a lightweight auto-refreshing HTML progress page for pipeline stages."""

from __future__ import annotations

import argparse
import datetime as dt
import html
import os
import re
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


def process_elapsed(processes: list[str]) -> str:
    if not processes:
        return "Not running"
    for line in processes:
        parts = line.split(None, 7)
        if len(parts) >= 3 and "progress_tracker.py" not in line:
            return parts[2]
    return "Running"


def human_duration(seconds: float | None) -> str:
    if seconds is None:
        return "Unknown"
    total = max(0, int(seconds))
    hours, remainder = divmod(total, 3600)
    minutes, secs = divmod(remainder, 60)
    if hours:
        return f"{hours}h {minutes}m {secs}s"
    if minutes:
        return f"{minutes}m {secs}s"
    return f"{secs}s"


def parse_log_started(log_path: Path) -> dt.datetime | None:
    if not log_path.exists() or log_path.stat().st_size == 0:
        return None
    pattern = re.compile(r"^ Started: (.+)$")
    with log_path.open("r", encoding="utf-8", errors="ignore") as handle:
        for line in handle:
            match = pattern.match(line.rstrip())
            if not match:
                continue
            value = match.group(1)
            for fmt in ("%a %b %d %H:%M:%S %Z %Y", "%a %b %e %H:%M:%S %Z %Y"):
                try:
                    return dt.datetime.strptime(value, fmt)
                except ValueError:
                    continue
    return None


def fastqc_progress(log_path: Path) -> dict[str, object]:
    result: dict[str, object] = {
        "r1": None,
        "r2": None,
        "phase": "Not started",
        "average": None,
    }
    if not log_path.exists() or log_path.stat().st_size == 0:
        return result

    progress_pattern = re.compile(r"Approx (\d+)% complete for (.+)")
    with log_path.open("r", encoding="utf-8", errors="ignore") as handle:
        for raw_line in handle:
            line = raw_line.rstrip()
            if "[2/7] Running raw FastQC" in line:
                result["phase"] = "Raw FastQC running"
            elif "[3/7] Running fastp" in line:
                result["phase"] = "Raw FastQC complete; fastp running"
                result["r1"] = 100
                result["r2"] = 100
            elif "[7/7] Running final FastQC" in line:
                result["phase"] = "Final FastQC and MultiQC running"
            elif "STAGE 1 COMPLETE" in line:
                result["phase"] = "Complete"
                result["r1"] = 100
                result["r2"] = 100

            match = progress_pattern.search(line)
            if not match:
                continue
            pct = int(match.group(1))
            filename = match.group(2)
            if ".1.fq" in filename or "R1" in filename:
                result["r1"] = pct
            elif ".2.fq" in filename or "R2" in filename:
                result["r2"] = pct

    values = [value for value in (result["r1"], result["r2"]) if isinstance(value, int)]
    if values:
        result["average"] = sum(values) / len(values)
    return result


def extract_stage1_step_sections(log_path: Path) -> dict[int, list[str]]:
    sections: dict[int, list[str]] = {step: [] for step in range(1, 8)}
    if not log_path.exists() or log_path.stat().st_size == 0:
        return sections

    marker = re.compile(r"^\[(\d)/7\]")
    current_step: int | None = None
    with log_path.open("r", encoding="utf-8", errors="ignore") as handle:
        for raw_line in handle:
            line = raw_line.rstrip()
            match = marker.match(line)
            if match:
                current_step = int(match.group(1))
            if current_step in sections:
                sections[current_step].append(line)
    return sections


def latest_stage1_step(log_path: Path) -> int:
    latest = 1
    if not log_path.exists() or log_path.stat().st_size == 0:
        return latest
    marker = re.compile(r"^\[(\d)/7\]")
    with log_path.open("r", encoding="utf-8", errors="ignore") as handle:
        for raw_line in handle:
            match = marker.match(raw_line)
            if match:
                latest = int(match.group(1))
    return latest


def step_status(step: int, current_step: int, section_text: str, log_text: str) -> str:
    lower_section = section_text.lower()
    lower_log = log_text.lower()
    if step == current_step and (
        "error" in lower_section
        or "exception" in lower_section
        or "invalid compressed data" in lower_section
        or "crc error" in lower_section
    ):
        return "Attention"
    if step < current_step:
        return "Complete"
    if step == current_step:
        if "stage 1 complete" in lower_log:
            return "Complete"
        return "Current"
    return "Pending"


def status_badge_class(status: str) -> str:
    return {
        "Complete": "complete",
        "Current": "running",
        "Attention": "attention",
        "Pending": "idle",
    }.get(status, "idle")


def stage1_tabs_html(log_path: Path, log_text: str) -> str:
    step_names = {
        1: "Verify Raw Input",
        2: "Raw FastQC",
        3: "fastp Filtering",
        4: "Verify Trimmed Output",
        5: "Backup Existing Finals",
        6: "Promote Outputs",
        7: "Final FastQC + MultiQC",
    }
    sections = extract_stage1_step_sections(log_path)
    current_step = latest_stage1_step(log_path)
    tabs = []
    panels = []

    for step in range(1, 8):
        section_lines = sections.get(step, [])
        section_text = "\n".join(section_lines[-80:]) if section_lines else "This step has not started yet."
        if step == 4:
            validation_log = log_path.parent / "stage1_trimmed_reformat_validation_latest.log"
            if validation_log.exists():
                section_text += "\n\n--- BBTools reformat.sh validation follow-up ---\n"
                section_text += tail_file(validation_log, 80)
        status_value = step_status(step, current_step, section_text, log_text)
        active = " active" if step == current_step else ""
        selected = "true" if step == current_step else "false"
        tabs.append(
            f'<button class="tab-button{active}" type="button" data-step="step-{step}" '
            f'aria-selected="{selected}">Step {step}</button>'
        )
        panels.append(
            f"""
  <section id="step-{step}" class="tab-panel{active}">
    <div class="top">
      <div class="box"><div class="label">Step</div><div class="value">Step {step}</div></div>
      <div class="box"><div class="label">Name</div><div class="value">{html.escape(step_names[step])}</div></div>
      <div class="box"><div class="label">Status</div><div class="value"><span class="status {status_badge_class(status_value)}">{html.escape(status_value)}</span></div></div>
    </div>
    <pre>{html.escape(section_text)}</pre>
  </section>"""
        )

    return f"""
  <h2>Stage 1 Steps</h2>
  <div class="tabs" role="tablist">
    {"".join(tabs)}
  </div>
  {"".join(panels)}"""


def processed_reads(log_path: Path) -> int:
    if not log_path.exists() or log_path.stat().st_size == 0:
        return 0
    total = 0
    pattern = re.compile(r"Processed (\d+) reads")
    with log_path.open("r", encoding="utf-8", errors="ignore") as handle:
        for line in handle:
            match = pattern.search(line)
            if match:
                total += int(match.group(1))
    return total


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
    now_dt = dt.datetime.now()
    log_path = Path(args.log)
    watch_paths = [Path(item) for item in args.watch]
    expected_files = [Path(item) for item in args.expect]
    processes = matching_processes(args.pattern)
    log_text = tail_file(log_path, args.tail_lines)
    status = infer_status(processes, log_text, expected_files)
    files = file_rows(watch_paths + expected_files)
    processed = processed_reads(log_path)
    progress_pct = (processed / args.expected_reads * 100) if args.expected_reads and processed else 0
    started_at = parse_log_started(log_path)
    elapsed_seconds = (now_dt - started_at).total_seconds() if started_at else None
    fq_progress = fastqc_progress(log_path)
    fq_average = fq_progress["average"]
    eta_seconds = None
    if elapsed_seconds and isinstance(fq_average, (int, float)) and 0 < fq_average < 100:
        eta_seconds = elapsed_seconds * ((100 - fq_average) / fq_average)
    fastq_progress_html = f"""
  <h2>Current FASTQ Progress</h2>
  <div class="top">
    <div class="box"><div class="label">FASTQ 1</div><div class="value">{html.escape(str(fq_progress["r1"])) if fq_progress["r1"] is not None else "Pending"}%</div></div>
    <div class="box"><div class="label">FASTQ 2</div><div class="value">{html.escape(str(fq_progress["r2"])) if fq_progress["r2"] is not None else "Pending"}%</div></div>
    <div class="box"><div class="label">Current Phase</div><div class="value">{html.escape(str(fq_progress["phase"]))}</div></div>
  </div>"""
    timing_html = f"""
  <h2>Run Timing</h2>
  <div class="top">
    <div class="box"><div class="label">Total Runtime</div><div class="value">{html.escape(human_duration(elapsed_seconds))}</div></div>
    <div class="box"><div class="label">Estimated Time Remaining</div><div class="value">{html.escape(human_duration(eta_seconds))}</div></div>
  </div>"""
    stage1_tabs = stage1_tabs_html(log_path, log_text)
    metrics_html = ""
    if args.expected_reads:
        metrics_html = f"""
  <div class="top">
    <div class="box"><div class="label">Runtime</div><div class="value">{html.escape(process_elapsed(processes))}</div></div>
    <div class="box"><div class="label">Processed Reads</div><div class="value">{processed:,}</div></div>
    <div class="box"><div class="label">Approx Alignment Progress</div><div class="value">{progress_pct:.2f}%</div></div>
  </div>"""

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
    .tabs {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px;
      margin: 18px 0 12px;
    }}
    .tab-button {{
      appearance: none;
      border: 1px solid var(--border);
      background: var(--panel);
      color: var(--fg);
      border-radius: 8px;
      padding: 9px 12px;
      font: inherit;
      font-weight: 650;
      cursor: pointer;
    }}
    .tab-button.active {{
      border-color: var(--running);
      background: var(--running);
      color: white;
    }}
    .tab-panel {{
      display: none;
    }}
    .tab-panel.active {{
      display: block;
    }}
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
{metrics_html}
{fastq_progress_html}
{timing_html}
{stage1_tabs}

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
<script>
  const buttons = Array.from(document.querySelectorAll(".tab-button"));
  const panels = Array.from(document.querySelectorAll(".tab-panel"));
  function showStep(id) {{
    buttons.forEach((button) => {{
      const active = button.dataset.step === id;
      button.classList.toggle("active", active);
      button.setAttribute("aria-selected", active ? "true" : "false");
    }});
    panels.forEach((panel) => panel.classList.toggle("active", panel.id === id));
  }}
  buttons.forEach((button) => button.addEventListener("click", () => showStep(button.dataset.step)));
</script>
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
    parser.add_argument("--expected-reads", type=int, default=0)
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
