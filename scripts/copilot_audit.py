#!/usr/bin/env python3
# purpose:  Thin wrapper — delegates to the copilot_audit package.
# when:     CI validation; Doctor agent D14 check; manual developer audits.
# inputs:   --root PATH (default: repo root via script location)
#           --output md|json (default: md)
# outputs:  Markdown or JSON report on stdout; structured findings array.
# risk:     safe (read-only)
# source:   original
"""
Copilot Audit — static-analysis for all files VS Code Copilot reads.

Thin wrapper that preserves the `python3 scripts/copilot_audit.py` CLI contract.
The real implementation lives in the copilot_audit/ package alongside this file.
"""
import os
import sys

# Ensure the scripts/ directory is on sys.path so that the copilot_audit
# package (scripts/copilot_audit/) is importable.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from copilot_audit.__main__ import main  # noqa: E402

if __name__ == "__main__":
    sys.exit(main())
