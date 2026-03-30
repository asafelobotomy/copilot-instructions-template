"""CLI entry point for copilot_audit (python -m copilot_audit)."""
from __future__ import annotations

import argparse
import pathlib
import sys

from . import run_audit
from .output import format_markdown, format_json, _summary_counts, _overall_status


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Copilot Audit — static-analysis for all files VS Code Copilot reads."
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
    args = parser.parse_args()

    root = pathlib.Path(args.root).resolve()
    if not root.is_dir():
        print(f"Error: --root '{root}' is not a directory", file=sys.stderr)
        return 2

    results = run_audit(root)

    if args.output == "json":
        print(format_json(results))
    else:
        print(format_markdown(results))

    counts = _summary_counts(results)
    return 1 if (_overall_status(counts) == "CRITICAL") else 0


if __name__ == "__main__":
    sys.exit(main())
