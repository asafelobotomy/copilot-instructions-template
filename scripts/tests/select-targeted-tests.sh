#!/usr/bin/env bash
# purpose:  Map changed repository paths to deterministic targeted test suites for intermediate-phase verification.
# when:     Use during task phases to choose targeted suites from changed paths; not a replacement for the final full-suite gate.
# inputs:   One or more repo-relative or absolute file or directory paths under the current repository root.
# outputs:  JSON describing normalized paths, selected test suites, intermediate-phase strategy, matched rules, and the final full-suite gate.
# risk:     safe
# source:   original
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
MAP_FILE="$ROOT_DIR/scripts/tests/targeted-test-map.json"

if [[ $# -lt 1 ]]; then
  echo "Usage: bash scripts/tests/select-targeted-tests.sh <path> [<path>...]" >&2
  exit 1
fi

python3 - "$ROOT_DIR" "$MAP_FILE" "$@" <<'PY'
from __future__ import annotations

import fnmatch
import json
import pathlib
import sys


ROOT = pathlib.Path(sys.argv[1]).resolve()
MAP_FILE = pathlib.Path(sys.argv[2])
RAW_PATHS = sys.argv[3:]

if not MAP_FILE.is_file():
    raise SystemExit(f"targeted test map not found: {MAP_FILE}")

config = json.loads(MAP_FILE.read_text(encoding="utf-8"))
rules = config.get("rules", [])
defaults = config.get("defaults", {})

PHASE_RANK = {
    "targeted": 0,
    "broaden-aggressively": 1,
    "full-suite": 2,
}


def normalize_path(raw: str) -> str:
    candidate = pathlib.Path(raw)
    if candidate.is_absolute():
        try:
            rel = candidate.resolve().relative_to(ROOT)
            return rel.as_posix()
        except ValueError:
            return candidate.resolve().as_posix()
    normalized = pathlib.PurePosixPath(str(candidate).replace("\\", "/")).as_posix()
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized.rstrip("/") or "."


def matches(rule: dict[str, object], path: str) -> bool:
    match_type = rule["matchType"]
    pattern = str(rule["pattern"])  # validated below
    if match_type == "exact":
        return path == pattern
    if match_type == "prefix":
        prefix = pattern.rstrip("/")
        return path == prefix or path.startswith(prefix + "/")
    if match_type == "glob":
        return fnmatch.fnmatch(path, pattern)
    raise ValueError(f"unsupported matchType: {match_type}")


def unique(items: list[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for item in items:
        if item not in seen:
            seen.add(item)
            ordered.append(item)
    return ordered


for rule in rules:
    if rule.get("matchType") not in {"exact", "prefix", "glob"}:
        raise SystemExit(f"invalid matchType in {MAP_FILE}: {rule}")
    if rule.get("phaseStrategy") not in PHASE_RANK:
        raise SystemExit(f"invalid phaseStrategy in {MAP_FILE}: {rule}")

normalized_paths = [normalize_path(path) for path in RAW_PATHS]
selected_tests: list[str] = []
matched_rules: list[dict[str, object]] = []
unmapped_paths: list[str] = []
broadening_reasons: list[str] = []
current_strategy = "targeted"

for path in normalized_paths:
    path_matches = [rule for rule in rules if matches(rule, path)]
    if not path_matches:
        unmapped_paths.append(path)
        default_strategy = defaults.get("unmappedPhaseStrategy", "full-suite")
        if PHASE_RANK[default_strategy] > PHASE_RANK[current_strategy]:
            current_strategy = default_strategy
        broadening_reasons.append(f"No deterministic mapping for {path}")
        continue

    for rule in path_matches:
        tests = []
        for test in rule.get("tests", []):
            tests.append(path if test == "self" else test)
        selected_tests.extend(tests)
        rule_strategy = str(rule["phaseStrategy"])
        matched_rules.append(
            {
                "id": rule["id"],
                "path": path,
                "phase_strategy": rule_strategy,
                "tests": tests,
                "reason": rule["reason"],
            }
        )
        if PHASE_RANK[rule_strategy] > PHASE_RANK[current_strategy]:
            current_strategy = rule_strategy
        if rule_strategy != "targeted":
            broadening_reasons.append(f"{path}: {rule['reason']}")

output = {
    "input_paths": RAW_PATHS,
    "normalized_paths": normalized_paths,
    "selected_tests": sorted(unique(selected_tests)),
    "intermediate_phase_strategy": current_strategy,
    "run_full_suite_at_completion": bool(defaults.get("runFullSuiteAtCompletion", True)),
    "matched_rules": matched_rules,
    "broadening_reasons": unique(broadening_reasons),
    "unmapped_paths": unmapped_paths,
    "final_gate": "bash tests/run-all.sh",
}

print(json.dumps(output, indent=2))
PY