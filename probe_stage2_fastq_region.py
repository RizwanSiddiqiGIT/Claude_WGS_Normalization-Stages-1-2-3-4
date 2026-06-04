#!/usr/bin/env python3
"""Inspect early Stage 1 trimmed FASTQs around the bwa-mem2 stall boundary."""

from __future__ import annotations

import gzip
from pathlib import Path


FILES = [
    ("R1", Path("/home/rayzw/DNA/hg38/fastq/R1_trimmed.fastq.gz")),
    ("R2", Path("/home/rayzw/DNA/hg38/fastq/R2_trimmed.fastq.gz")),
]


def inspect(label: str, path: Path) -> None:
    max_len = 0
    max_i = 0
    weird: list[tuple[int, str, int, int, str, str]] = []

    with gzip.open(path, "rt", errors="replace") as handle:
        i = 0
        while i < 4500:
            header = handle.readline().rstrip()
            seq = handle.readline().rstrip()
            plus = handle.readline().rstrip()
            qual = handle.readline().rstrip()
            if not qual:
                break
            i += 1
            seq_len = len(seq)
            qual_len = len(qual)
            if seq_len > max_len:
                max_len = seq_len
                max_i = i
            if i >= 2800 and (
                seq_len > 500
                or seq_len < 50
                or qual_len != seq_len
                or not plus.startswith("+")
            ):
                weird.append((i, header, seq_len, qual_len, plus[:20], seq[:80]))

    print(f"{label} max_len={max_len} max_i={max_i} weird_count={len(weird)}")
    for row in weird[:40]:
        print(label, row)


def main() -> int:
    for label, path in FILES:
        inspect(label, path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
