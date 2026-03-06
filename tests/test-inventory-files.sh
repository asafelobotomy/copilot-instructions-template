#!/usr/bin/env bash
# tests/test-inventory-files.sh -- verify bibliography and metrics inventory drift.
# Run: bash tests/test-inventory-files.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

echo "=== Inventory and markdown coverage checks ==="
echo ""

echo "1. BIBLIOGRAPHY lists the actual workspace files"
assert_python "bibliography file set matches workspace files" '
import pathlib
import re

biblio = (root / "BIBLIOGRAPHY.md").read_text(encoding="utf-8")
listed = set(re.findall(r"\| `([^`]+)` \|", biblio))
actual = set()

for path in root.rglob("*"):
    if not path.is_file():
        continue
    rel = path.relative_to(root).as_posix()
    if rel.startswith(".git/") or rel.startswith("coverage/") or rel.startswith("node_modules/"):
        continue
    actual.add(rel)

missing = sorted(actual - listed)
extra = sorted(listed - actual)
if missing or extra:
    raise SystemExit(f"missing={missing} extra={extra}")
'
echo ""

echo "2. BIBLIOGRAPHY LOC values match the current files"
assert_python "bibliography LOC values are current" '
import pathlib
import re

text = (root / "BIBLIOGRAPHY.md").read_text(encoding="utf-8")
entries = re.findall(r"\| `([^`]+)` \| .*? \| ([0-9]+|—) \|", text)
mismatches = []

for rel_path, loc_text in entries:
    path = root / rel_path
    actual_loc = sum(1 for _ in path.open(encoding="utf-8"))
    expected = "—" if actual_loc == 0 else str(actual_loc)
    if loc_text != expected:
        mismatches.append((rel_path, loc_text, expected))

if mismatches:
    raise SystemExit(str(mismatches[:10]))
'
echo ""

echo "3. BIBLIOGRAPHY summary totals are self-consistent"
assert_python "bibliography totals match listed entries" '
import re

text = (root / "BIBLIOGRAPHY.md").read_text(encoding="utf-8")
entries = re.findall(r"\| `([^`]+)` \| .*? \| ([0-9]+|—) \|", text)
summary = re.search(r"\*\*Total\*\*: ([0-9]+) files · ([0-9,]+) LOC", text)
if summary is None:
    raise SystemExit("missing total line")

file_total = len(entries)
loc_total = sum(0 if loc == "—" else int(loc) for _, loc in entries)
summary_files = int(summary.group(1))
summary_loc = int(summary.group(2).replace(",", ""))

if (file_total, loc_total) != (summary_files, summary_loc):
    raise SystemExit(f"entries=({file_total},{loc_total}) summary=({summary_files},{summary_loc})")
'
echo ""

echo "4. Latest METRICS row matches the documented repo metrics commands"
assert_python "metrics latest row matches live repo metrics" '
rows = [line for line in (root / "METRICS.md").read_text(encoding="utf-8").splitlines() if line.startswith("| 20")]
if not rows:
    raise SystemExit("missing metrics rows")

latest = [cell.strip() for cell in rows[-1].strip("|").split("|")]
latest_loc = latest[2].replace(",", "")
latest_files = latest[3]

actual_files = 0
for path in root.rglob("*"):
    if not path.is_file():
        continue
    rel = path.relative_to(root).as_posix()
    if rel.startswith(".git/") or rel.startswith("coverage/") or rel.startswith("node_modules/"):
        continue
    actual_files += 1

actual_loc = 0
for path in root.rglob("*"):
    if not path.is_file():
        continue
    rel = path.relative_to(root).as_posix()
    if rel.startswith("node_modules/"):
        continue
    if path.suffix not in {".sh", ".md"}:
        continue
    actual_loc += sum(1 for _ in path.open(encoding="utf-8"))

if latest_files != str(actual_files) or latest_loc != str(actual_loc):
    raise SystemExit(f"metrics=({latest_files},{latest_loc}) actual=({actual_files},{actual_loc})")
'
echo ""

finish_tests