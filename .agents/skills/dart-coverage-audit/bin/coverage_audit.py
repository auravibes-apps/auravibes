#!/usr/bin/env python3
"""Parse LCOV and report low test coverage files."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple


@dataclass(frozen=True)
class FileCoverage:
    path: str
    hits: int
    found: int

    @property
    def percent(self) -> float:
        if self.found == 0:
            return 0.0
        return (self.hits / self.found) * 100


class LcovError(Exception):
    pass


_GENERATED_SUFFIXES = (".g.dart", ".freezed.dart", ".mocks.dart")


def parse_lcov(lcov_path: Path) -> List[FileCoverage]:
    if not lcov_path.exists():
        raise LcovError(f"LCOV file not found: {lcov_path}")

    aggregate: Dict[str, Tuple[int, int]] = {}
    current_file: Optional[str] = None
    hits = 0
    found = 0

    def flush() -> None:
        nonlocal current_file, hits, found
        if current_file is not None and found > 0:
            prev_hits, prev_found = aggregate.get(current_file, (0, 0))
            aggregate[current_file] = (prev_hits + hits, prev_found + found)
        current_file = None
        hits = 0
        found = 0

    try:
        with lcov_path.open("r", encoding="utf-8") as handle:
            for raw in handle:
                line = raw.strip()
                if line.startswith("SF:"):
                    flush()
                    current_file = line[3:]
                    continue
                if line.startswith("DA:"):
                    parts = line[3:].split(",")
                    if len(parts) < 2:
                        raise LcovError(f"Malformed DA entry: {line}")
                    found += 1
                    if int(parts[1]) > 0:
                        hits += 1
                    continue
                if line == "end_of_record":
                    flush()
    except OSError as err:
        raise LcovError(f"Unable to read LCOV file: {lcov_path}") from err
    except ValueError as err:
        raise LcovError("Invalid DA entry in LCOV file") from err

    flush()
    records = [
        FileCoverage(path=path, hits=hits, found=found)
        for path, (hits, found) in aggregate.items()
    ]
    if not records:
        raise LcovError("No file coverage records found in LCOV file")
    return records


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Report low-coverage Dart/Flutter files from lcov.info"
    )
    parser.add_argument(
        "--lcov",
        default="coverage/lcov.info",
        help="Path to lcov.info (default: coverage/lcov.info)",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=60.0,
        help="Low-coverage threshold percentage (default: 60)",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=20,
        help="Number of lowest-covered files to print (default: 20)",
    )
    parser.add_argument(
        "--exclude-generated",
        action="store_true",
        help="Exclude generated files ending in .g.dart, .freezed.dart, or .mocks.dart",
    )
    parser.add_argument(
        "--min-lines",
        type=int,
        default=1,
        help="Ignore files with fewer executable lines than this value",
    )
    parser.add_argument(
        "--json-out",
        default="",
        help="Optional path to write JSON report",
    )
    parser.add_argument(
        "--fail-under-overall",
        type=float,
        default=None,
        help="Exit with code 1 when overall coverage is below this percentage",
    )
    parser.add_argument(
        "--fail-if-any-below-threshold",
        action="store_true",
        help="Exit with code 1 when any file is below --threshold",
    )
    return parser


def format_file_line(item: FileCoverage) -> str:
    return f"{item.percent:6.2f}%\t{item.hits:4d}/{item.found:<4d}\t{item.path}"


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.top < 1:
        print("error: --top must be >= 1", file=sys.stderr)
        return 2
    if args.min_lines < 1:
        print("error: --min-lines must be >= 1", file=sys.stderr)
        return 2
    if args.threshold < 0 or args.threshold > 100:
        print("error: --threshold must be between 0 and 100", file=sys.stderr)
        return 2
    if args.fail_under_overall is not None and (
        args.fail_under_overall < 0 or args.fail_under_overall > 100
    ):
        print("error: --fail-under-overall must be between 0 and 100", file=sys.stderr)
        return 2

    try:
        records = parse_lcov(Path(args.lcov))
    except LcovError as err:
        print(f"error: {err}", file=sys.stderr)
        return 2

    filtered = [entry for entry in records if entry.found >= args.min_lines]
    if args.exclude_generated:
        filtered = [
            entry
            for entry in filtered
            if not any(entry.path.endswith(suffix) for suffix in _GENERATED_SUFFIXES)
        ]

    if not filtered:
        print("error: no files remain after filters", file=sys.stderr)
        return 2

    filtered.sort(key=lambda item: item.percent)

    total_hits = sum(item.hits for item in filtered)
    total_found = sum(item.found for item in filtered)
    overall = (total_hits / total_found) * 100 if total_found > 0 else 0.0
    below_threshold = [item for item in filtered if item.percent < args.threshold]

    print(f"OVERALL {overall:.2f}% ({total_hits}/{total_found})")
    print(f"FILES {len(filtered)}")
    print(f"THRESHOLD {args.threshold:.2f}%")
    print(f"BELOW_THRESHOLD {len(below_threshold)}")
    print()
    print(f"LOWEST_{min(args.top, len(filtered))}")
    for item in filtered[: args.top]:
        print(format_file_line(item))

    if below_threshold:
        print()
        print(f"FILES_BELOW_{args.threshold:.2f}")
        for item in below_threshold:
            print(format_file_line(item))

    if args.json_out:
        payload = {
            "schema_version": 1,
            "overall_percent": round(overall, 4),
            "total_hits": total_hits,
            "total_found": total_found,
            "file_count": len(filtered),
            "threshold": args.threshold,
            "below_threshold_count": len(below_threshold),
            "lowest_files": [
                asdict(item) | {"percent": item.percent}
                for item in filtered[: args.top]
            ],
            "below_threshold_files": [
                asdict(item) | {"percent": item.percent} for item in below_threshold
            ],
            "filters": {
                "exclude_generated": args.exclude_generated,
                "min_lines": args.min_lines,
            },
        }

        try:
            output_path = Path(args.json_out)
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        except OSError as err:
            print(f"error: could not write JSON report: {err}", file=sys.stderr)
            return 2

    failed = False
    if args.fail_under_overall is not None and overall < args.fail_under_overall:
        print(
            f"GATE_FAIL overall {overall:.2f}% < {args.fail_under_overall:.2f}%",
            file=sys.stderr,
        )
        failed = True

    if args.fail_if_any_below_threshold and below_threshold:
        print(
            f"GATE_FAIL {len(below_threshold)} files below {args.threshold:.2f}%",
            file=sys.stderr,
        )
        failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
