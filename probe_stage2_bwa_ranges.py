#!/usr/bin/env python3
"""Extract read-pair ranges for targeted bwa-mem2 probes."""

from __future__ import annotations

import gzip
import sys
from pathlib import Path


R1 = Path("/home/rayzw/DNA/hg38/fastq/R1_trimmed.fastq.gz")
R2 = Path("/home/rayzw/DNA/hg38/fastq/R2_trimmed.fastq.gz")
OUT = Path("/home/rayzw/DNA/hg38/tmp/stage2_bwa_probe")


def write_range(src: Path, dest: Path, start: int, end: int) -> None:
    with gzip.open(src, "rt") as input_handle, gzip.open(dest, "wt") as output_handle:
        for i in range(1, end + 1):
            record = [input_handle.readline() for _ in range(4)]
            if not record[-1]:
                break
            if start <= i <= end:
                output_handle.writelines(record)


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: probe_stage2_bwa_ranges.py START END", file=sys.stderr)
        return 2
    start = int(sys.argv[1])
    end = int(sys.argv[2])
    OUT.mkdir(parents=True, exist_ok=True)
    write_range(R1, OUT / f"R1_{start}_{end}.fq.gz", start, end)
    write_range(R2, OUT / f"R2_{start}_{end}.fq.gz", start, end)
    print(OUT / f"R1_{start}_{end}.fq.gz")
    print(OUT / f"R2_{start}_{end}.fq.gz")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
