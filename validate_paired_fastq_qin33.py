#!/usr/bin/env python3
"""Streaming paired FASTQ validator for Phred+33/qin33 data.

Handles plain text or gzip-compressed FASTQ, validates both mates together,
checks four-line FASTQ structure, sequence/quality length equality, printable
Phred+33 quality characters, and synchronized pair names.
"""

from __future__ import annotations

import argparse
import gzip
import sys
import time
from pathlib import Path
from typing import TextIO


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("r1", type=Path)
    parser.add_argument("r2", type=Path)
    parser.add_argument("--progress-pairs", type=int, default=5_000_000)
    parser.add_argument("--max-bad-pairs", type=int, default=20)
    return parser.parse_args()


def open_text(path: Path) -> TextIO:
    if str(path).endswith(".gz"):
        return gzip.open(path, "rt", errors="replace", newline="")
    return path.open("rt", errors="replace", newline="")


def normalize_name(header: str) -> str:
    name = header.rstrip("\r\n")
    if name.startswith("@"):
        name = name[1:]
    name = name.split()[0]
    for suffix in ("/1", "/2"):
        if name.endswith(suffix):
            return name[:-2]
    return name


def validate_record(label: str, lines: list[str], pair_number: int) -> list[str]:
    header, seq, plus, qual = [line.rstrip("\r\n") for line in lines]
    reasons: list[str] = []
    if not header.startswith("@"):
        reasons.append(f"{label}_header_not_at")
    if not plus.startswith("+"):
        reasons.append(f"{label}_plus_not_plus")
    if len(seq) != len(qual):
        reasons.append(f"{label}_seq_qual_length_mismatch:{len(seq)}!={len(qual)}")
    for ch in qual:
      # qin33 FASTQ quality characters should be printable ASCII after adding
      # 33 to a Phred score. Keep the upper bound broad because platforms can
      # differ, but fail control characters and non-ASCII replacement.
        code = ord(ch)
        if code < 33 or code > 126:
            reasons.append(f"{label}_quality_not_qin33_printable:ord{code}")
            break
    if not seq:
        reasons.append(f"{label}_empty_sequence")
    if reasons:
        reasons.append(f"pair={pair_number}")
    return reasons


def read_record(handle: TextIO) -> list[str] | None:
    header = handle.readline()
    if not header:
        return None
    record = [header]
    for _ in range(3):
        line = handle.readline()
        if not line:
            record.append("")
        else:
            record.append(line)
    return record


def main() -> int:
    args = parse_args()
    start = time.time()
    pairs = 0
    bad_pairs = 0
    min_len_r1: int | None = None
    min_len_r2: int | None = None
    max_len_r1 = 0
    max_len_r2 = 0

    print(f"R1={args.r1}", flush=True)
    print(f"R2={args.r2}", flush=True)
    print(f"STARTED={time.strftime('%Y-%m-%d %H:%M:%S')}", flush=True)

    with open_text(args.r1) as r1_handle, open_text(args.r2) as r2_handle:
        while True:
            rec1 = read_record(r1_handle)
            rec2 = read_record(r2_handle)
            if rec1 is None and rec2 is None:
                break
            pairs += 1
            reasons: list[str] = []
            if rec1 is None:
                reasons.append("r1_ended_before_r2")
            if rec2 is None:
                reasons.append("r2_ended_before_r1")
            if rec1 is not None and "" in rec1:
                reasons.append("r1_truncated_record")
            if rec2 is not None and "" in rec2:
                reasons.append("r2_truncated_record")
            if rec1 is not None and "" not in rec1:
                reasons.extend(validate_record("r1", rec1, pairs))
                seq_len = len(rec1[1].rstrip("\r\n"))
                min_len_r1 = seq_len if min_len_r1 is None else min(min_len_r1, seq_len)
                max_len_r1 = max(max_len_r1, seq_len)
            if rec2 is not None and "" not in rec2:
                reasons.extend(validate_record("r2", rec2, pairs))
                seq_len = len(rec2[1].rstrip("\r\n"))
                min_len_r2 = seq_len if min_len_r2 is None else min(min_len_r2, seq_len)
                max_len_r2 = max(max_len_r2, seq_len)
            if rec1 is not None and rec2 is not None and "" not in rec1 and "" not in rec2:
                name1 = normalize_name(rec1[0])
                name2 = normalize_name(rec2[0])
                if name1 != name2:
                    reasons.append(f"pair_name_mismatch:{name1[:80]}!={name2[:80]}")
            if reasons:
                bad_pairs += 1
                print(
                    "BAD_PAIR\t"
                    f"pair={pairs}\t"
                    f"reasons={','.join(reasons)}",
                    flush=True,
                )
                if bad_pairs >= args.max_bad_pairs:
                    print(f"STOPPED_AFTER_BAD_PAIRS={bad_pairs}", flush=True)
                    break
            if pairs % args.progress_pairs == 0:
                elapsed = max(time.time() - start, 1e-9)
                print(
                    "PROGRESS\t"
                    f"pairs={pairs}\t"
                    f"bad_pairs={bad_pairs}\t"
                    f"elapsed_seconds={elapsed:.0f}\t"
                    f"pairs_per_second={pairs / elapsed:.0f}",
                    flush=True,
                )

    elapsed = time.time() - start
    print("SUMMARY", flush=True)
    print(f"PAIRS={pairs}", flush=True)
    print(f"BAD_PAIRS={bad_pairs}", flush=True)
    print(f"R1_MIN_READ_LENGTH={min_len_r1}", flush=True)
    print(f"R1_MAX_READ_LENGTH={max_len_r1}", flush=True)
    print(f"R2_MIN_READ_LENGTH={min_len_r2}", flush=True)
    print(f"R2_MAX_READ_LENGTH={max_len_r2}", flush=True)
    print(f"ELAPSED_SECONDS={elapsed:.0f}", flush=True)
    print(f"FINISHED={time.strftime('%Y-%m-%d %H:%M:%S')}", flush=True)
    return 0 if bad_pairs == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
