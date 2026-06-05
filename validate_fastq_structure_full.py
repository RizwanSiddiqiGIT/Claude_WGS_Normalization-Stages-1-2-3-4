#!/usr/bin/env python3
"""Full streaming FASTQ structure validator with progress milestones."""

from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("fastq", type=Path)
    parser.add_argument("--progress-reads", type=int, default=5_000_000)
    parser.add_argument("--max-bad-records", type=int, default=100)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    start_time = time.time()
    reads = 0
    bad_records = 0
    total_bases = 0
    n_bases = 0
    min_len: int | None = None
    max_len = 0

    print(f"FASTQ={args.fastq}", flush=True)
    print(f"STARTED={time.strftime('%Y-%m-%d %H:%M:%S')}", flush=True)

    with args.fastq.open("rt", errors="replace", newline="") as handle:
        while True:
            line_number = reads * 4 + 1
            header = handle.readline()
            if not header:
                break
            seq = handle.readline()
            plus = handle.readline()
            qual = handle.readline()
            reads += 1

            if not seq or not plus or not qual:
                bad_records += 1
                print(
                    "BAD_RECORD\t"
                    f"read={reads}\tline={line_number}\t"
                    f"reason=truncated_record\t"
                    f"header={header.rstrip()[:120]}",
                    flush=True,
                )
                break

            seq = seq.rstrip("\r\n")
            plus = plus.rstrip("\r\n")
            qual = qual.rstrip("\r\n")
            header_text = header.rstrip("\r\n")

            seq_len = len(seq)
            qual_len = len(qual)
            total_bases += seq_len
            n_bases += seq.upper().count("N")
            min_len = seq_len if min_len is None else min(min_len, seq_len)
            max_len = max(max_len, seq_len)

            reasons: list[str] = []
            if not header_text.startswith("@"):
                reasons.append("header_not_at")
            if not plus.startswith("+"):
                reasons.append("plus_not_plus")
            if seq_len != qual_len:
                reasons.append("seq_qual_length_mismatch")

            if reasons:
                bad_records += 1
                print(
                    "BAD_RECORD\t"
                    f"read={reads}\tline={line_number}\t"
                    f"reason={','.join(reasons)}\t"
                    f"header={header_text[:120]}\t"
                    f"seq_len={seq_len}\t"
                    f"plus={plus[:120]}\t"
                    f"qual_len={qual_len}",
                    flush=True,
                )
                if bad_records >= args.max_bad_records:
                    print(
                        f"STOPPED_AFTER_BAD_RECORDS={bad_records}",
                        flush=True,
                    )
                    break

            if reads % args.progress_reads == 0:
                elapsed = max(time.time() - start_time, 1e-9)
                rate = reads / elapsed
                print(
                    "PROGRESS\t"
                    f"reads={reads}\t"
                    f"bad_records={bad_records}\t"
                    f"elapsed_seconds={elapsed:.0f}\t"
                    f"reads_per_second={rate:.0f}",
                    flush=True,
                )

    elapsed = time.time() - start_time
    n_rate = (n_bases / total_bases * 100) if total_bases else 0
    print("SUMMARY", flush=True)
    print(f"READS={reads}", flush=True)
    print(f"BAD_RECORDS={bad_records}", flush=True)
    print(f"TOTAL_BASES={total_bases}", flush=True)
    print(f"N_BASES={n_bases}", flush=True)
    print(f"N_RATE={n_rate:.6f}", flush=True)
    print(f"MIN_READ_LENGTH={min_len}", flush=True)
    print(f"MAX_READ_LENGTH={max_len}", flush=True)
    print(f"ELAPSED_SECONDS={elapsed:.0f}", flush=True)
    print(f"FINISHED={time.strftime('%Y-%m-%d %H:%M:%S')}", flush=True)
    return 0 if bad_records == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
