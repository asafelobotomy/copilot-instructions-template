#!/usr/bin/env bash
# tests/test-markdown-contracts.sh -- verify markdown document structure and local links.
# Run: bash tests/test-markdown-contracts.sh
# Exit 0: all checks passed. Exit 1: one or more checks failed.
set -uo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
init_test_context "$0"

echo "=== Markdown contract checks ==="
echo ""

echo "1. Local markdown links resolve to real files and anchors"
assert_python "repository markdown links are valid" '
import pathlib
import re

link_pattern = re.compile(r"(?<!\!)\[[^\]]+\]\(([^)]+)\)")
heading_pattern = re.compile(r"^(#+)\s+(.*)$", re.MULTILINE)
skip_prefixes = ("http://", "https://", "mailto:", "#")
missing = []

def slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[`*_]+", "", text)
    text = re.sub(r"[^a-z0-9\s-]", "", text)
    text = re.sub(r"\s+", "-", text)
    text = re.sub(r"-+", "-", text)
    return text

for md_path in root.rglob("*.md"):
    rel_md = md_path.relative_to(root).as_posix()
    if rel_md.startswith("node_modules/"):
        continue
    text = md_path.read_text(encoding="utf-8")
    headings = {slugify(match.group(2)) for match in heading_pattern.finditer(text)}

    for raw_target in link_pattern.findall(text):
        target = raw_target.strip()
        if target.startswith(skip_prefixes):
            if target.startswith("#"):
                anchor = target[1:]
                if anchor and anchor not in headings:
                    missing.append((rel_md, raw_target, "anchor"))
            continue

        clean_target = target.split()[0]
        path_part, _, anchor = clean_target.partition("#")
        resolved = (md_path.parent / path_part).resolve()
        try:
            resolved.relative_to(root.resolve())
        except ValueError:
            missing.append((rel_md, raw_target, "outside-root"))
            continue

        if not resolved.exists():
            missing.append((rel_md, raw_target, "file"))
            continue

        if anchor:
            if resolved.suffix != ".md":
                continue
            target_text = resolved.read_text(encoding="utf-8")
            target_headings = {slugify(match.group(2)) for match in heading_pattern.finditer(target_text)}
            if anchor not in target_headings:
                missing.append((rel_md, raw_target, "anchor"))

if missing:
    raise SystemExit(str(missing[:20]))
'
echo ""

echo "2. CHANGELOG keeps core Keep a Changelog sections"
assert_python "changelog retains required sections" '
text = (root / "CHANGELOG.md").read_text(encoding="utf-8")
required = [
    "# Changelog — copilot-instructions-template",
    "## [Unreleased]",
    "### Added",
    "### Changed",
    "### Fixed",
    "### Update protocol",
    "### CI",
]
for marker in required:
    if marker not in text:
        raise SystemExit(marker)
'
echo ""

echo "3. JOURNAL ADR entries keep Context, Decision, Consequences"
assert_python "journal entries retain ADR triad" '
text = (root / "JOURNAL.md").read_text(encoding="utf-8")
sections = [section.strip() for section in text.split("\n---\n") if section.strip().startswith("## ")]
bad = []
for section in sections:
    if "**Context**:" not in section or "**Decision**:" not in section or "**Consequences**:" not in section:
        first_line = section.splitlines()[0]
        bad.append(first_line)
if bad:
    raise SystemExit(str(bad))
'
echo ""

echo "4. README and AGENTS keep their core navigation sections"
assert_python "high-signal markdown sections remain present" '
required = {
    "README.md": [
        "## Quickstart",
        "## Key features",
        "## Human-readable guides",
        "## Repository layout",
    ],
    "AGENTS.md": [
        "## Remote Bootstrap Sequence",
        "## Remote Update Sequence",
        "## Remote Restore Sequence",
        "## Canonical triggers",
    ],
}
for rel_path, markers in required.items():
    text = (root / rel_path).read_text(encoding="utf-8")
    for marker in markers:
        if marker not in text:
            raise SystemExit(f"{rel_path}: missing {marker}")
'
echo ""

finish_tests