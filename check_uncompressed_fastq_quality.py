#!/usr/bin/env python3
"""Validate and summarize an uncompressed FASTQ file."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("fastq", type=Path)
    parser.add_argument("--sample-reads", type=int, default=1_000_000)
    args = parser.parse_args()

    lengths: Counter[int] = Counter()
    qchars: Counter[str] = Counter()
    n_bases = 0
    total_bases = 0
    bad = 0
    reads = 0

    with args.fastq.open("rt", errors="replace") as handle:
        for _ in range(args.sample_reads):
            header = handle.readline().rstrip("\n")
            seq = handle.readline().rstrip("\n")
            plus = handle.readline().rstrip("\n")
            qual = handle.readline().rstrip("\n")
            if not qual:
                break
            reads += 1
            if not header.startswith("@") or not plus.startswith("+") or len(seq) != len(qual):
                bad += 1
                if bad <= 5:
                    print(f"BAD_RECORD\t{reads}\t{header[:80]}\tseq_len={len(seq)}\tplus={plus[:20]}\tqual_len={len(qual)}")
            lengths[len(seq)] += 1
            total_bases += len(seq)
            n_bases += seq.upper().count("N")
            qchars.update(qual)

    q20_bases = 0
    q30_bases = 0
    q_min = None
    q_max = None
    for ch, count in qchars.items():
        q = ord(ch) - 33
        q_min = q if q_min is None else min(q_min, q)
        q_max = q if q_max is None else max(q_max, q)
        if q >= 20:
            q20_bases += count
        if q >= 30:
            q30_bases += count

    print(f"FASTQ={args.fastq}")
    print(f"SAMPLED_READS={reads}")
    print(f"BAD_RECORDS={bad}")
    print(f"TOTAL_BASES={total_bases}")
    print(f"N_BASES={n_bases}")
    print(f"N_RATE={n_bases / total_bases * 100:.6f}" if total_bases else "N_RATE=0")
    print("LENGTHS_TOP=" + ",".join(f"{length}:{count}" for length, count in lengths.most_common(10)))
    print(f"Q_MIN={q_min}")
    print(f"Q_MAX={q_max}")
    print(f"Q20_RATE={q20_bases / total_bases * 100:.4f}" if total_bases else "Q20_RATE=0")
    print(f"Q30_RATE={q30_bases / total_bases * 100:.4f}" if total_bases else "Q30_RATE=0")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
