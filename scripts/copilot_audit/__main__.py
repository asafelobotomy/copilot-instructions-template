"""CLI entry point for copilot_audit (python -m copilot_audit)."""
from __future__ import annotations

import argparse
import pathlib
import sys

from . import (
    DEFAULT_PROFILE,
    PROFILES,
    format_json,
    format_markdown,
    overall_status,
    run_audit,
    summary_counts,
)


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Copilot Audit — static-analysis for files VS Code Copilot reads, "
            "with developer and consumer-safe profiles."
        )
    )
    parser.add_argument(
        "--root",
        default=str(pathlib.Path(__file__).parent.parent.parent),
        help="Repository root (default: grandparent of scripts/copilot_audit/)",
    )
    parser.add_argument(
        "--output",
        choices=["md", "json"],
        default="md",
        help="Output format: md (default) or json",
    )
    parser.add_argument(
        "--profile",
        choices=PROFILES,
        default=DEFAULT_PROFILE,
        help=(
            "Audit profile: developer (default, repo policy checks) or "
            "consumer (safe subset for consumer repos)"
        ),
    )
    args = parser.parse_args()

    root = pathlib.Path(args.root).resolve()
    if not root.is_dir():
        print(f"Error: --root '{root}' is not a directory", file=sys.stderr)
        return 2

    results = run_audit(root, profile=args.profile)

    if args.output == "json":
        print(format_json(results))
    else:
        print(format_markdown(results))

    counts = summary_counts(results)
    return 1 if (overall_status(counts) == "CRITICAL") else 0


if __name__ == "__main__":
    sys.exit(main())
