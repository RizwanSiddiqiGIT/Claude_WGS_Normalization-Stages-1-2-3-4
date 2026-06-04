#!/usr/bin/env python3
"""Compare a BAM @SQ dictionary against candidate FASTA .fai files."""

from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


def read_bam_dict(bam: Path) -> dict[str, int]:
    header = subprocess.check_output(["samtools", "view", "-H", str(bam)], text=True)
    contigs: dict[str, int] = {}
    for line in header.splitlines():
        if not line.startswith("@SQ"):
            continue
        fields = {}
        for item in line.split("\t")[1:]:
            key, value = item.split(":", 1)
            fields[key] = value
        contigs[fields["SN"]] = int(fields["LN"])
    return contigs


def read_fai(path: Path) -> dict[str, int]:
    contigs: dict[str, int] = {}
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if not line.strip():
                continue
            parts = line.rstrip("\n").split("\t")
            contigs[parts[0]] = int(parts[1])
    return contigs


def strip_chr(name: str) -> str:
    if name == "chrM":
        return "MT"
    if name.startswith("chrUn_"):
        return "Un_" + name[len("chrUn_") :]
    if name.startswith("chr"):
        return name[3:]
    return name


def score(label: str, bam: dict[str, int], ref: dict[str, int]) -> None:
    exact_shared = set(bam) & set(ref)
    exact_length_matches = {name for name in exact_shared if bam[name] == ref[name]}
    exact_length_mismatches = exact_shared - exact_length_matches

    normalized_ref: dict[str, tuple[str, int]] = {}
    duplicates = set()
    for name, length in ref.items():
        norm = strip_chr(name)
        if norm in normalized_ref:
            duplicates.add(norm)
        normalized_ref[norm] = (name, length)

    normalized_matches = {}
    normalized_length_mismatches = {}
    for name, length in bam.items():
        if name not in normalized_ref:
            continue
        ref_name, ref_len = normalized_ref[name]
        if length == ref_len:
            normalized_matches[name] = ref_name
        else:
            normalized_length_mismatches[name] = (ref_name, length, ref_len)

    missing_after_norm = sorted(set(bam) - set(normalized_matches) - set(normalized_length_mismatches))
    extra_after_norm = sorted(set(normalized_ref) - set(bam))

    print("=" * 80)
    print(label)
    print(f"ref_contigs={len(ref)}")
    print(f"exact_name_length_matches={len(exact_length_matches)}")
    print(f"exact_name_length_mismatches={len(exact_length_mismatches)}")
    print(f"chr_normalized_length_matches={len(normalized_matches)}")
    print(f"chr_normalized_length_mismatches={len(normalized_length_mismatches)}")
    print(f"bam_missing_from_ref_after_chr_normalization={len(missing_after_norm)}")
    print(f"ref_extra_after_chr_normalization={len(extra_after_norm)}")
    if duplicates:
        print(f"normalized_name_collisions={len(duplicates)}")

    print("sample_missing_from_ref=" + ",".join(missing_after_norm[:20]))
    print("sample_ref_extra=" + ",".join(extra_after_norm[:20]))
    if normalized_length_mismatches:
        sample = []
        for name, (ref_name, bam_len, ref_len) in list(normalized_length_mismatches.items())[:10]:
            sample.append(f"{name}->{ref_name}:bam={bam_len}:ref={ref_len}")
        print("sample_length_mismatches=" + ",".join(sample))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bam", required=True, type=Path)
    parser.add_argument("fai", nargs="+", type=Path)
    args = parser.parse_args()

    bam = read_bam_dict(args.bam)
    print(f"bam={args.bam}")
    print(f"bam_contigs={len(bam)}")
    for path in args.fai:
        score(str(path), bam, read_fai(path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
