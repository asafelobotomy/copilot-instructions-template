#!/usr/bin/env bash
# purpose:  Map changed repository paths to deterministic targeted test suites for intermediate-phase verification.
# when:     Use during task phases to choose targeted suites from changed paths; not a replacement for the final full-suite gate.
# inputs:   One or more repo-relative or absolute file or directory paths under the current repository root.
# outputs:  JSON describing normalized paths, selected test suites, intermediate-phase strategy, the inner-loop time budget, matched rules, and the final full-suite gate.
# risk:     safe
# source:   original
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
MAP_FILE="$ROOT_DIR/scripts/harness/targeted-test-map.json"
SUITE_MANIFEST_PATH="$ROOT_DIR/scripts/harness/suite-manifest.json"

if [[ $# -lt 1 ]]; then
  echo "Usage: bash scripts/harness/select-targeted-tests.sh <path> [<path>...]" >&2
  exit 1
fi

python3 - "$ROOT_DIR" "$MAP_FILE" "$SUITE_MANIFEST_PATH" "$@" <<'PY'
from __future__ import annotations

import fnmatch
import json
import pathlib
import sys


ROOT = pathlib.Path(sys.argv[1]).resolve()
MAP_FILE = pathlib.Path(sys.argv[2])
SUITE_MANIFEST_PATH = pathlib.Path(sys.argv[3])
RAW_PATHS = sys.argv[4:]

if not MAP_FILE.is_file():
    raise SystemExit(f"targeted test map not found: {MAP_FILE}")
if not SUITE_MANIFEST_PATH.is_file():
    raise SystemExit(f"suite manifest not found: {SUITE_MANIFEST_PATH}")

config = json.loads(MAP_FILE.read_text(encoding="utf-8"))
defaults = config.get("defaults", {})
rule_files = config.get("ruleFiles", [])
suite_manifest = json.loads(SUITE_MANIFEST_PATH.read_text(encoding="utf-8"))


def load_rules() -> list[dict[str, object]]:
    loaded_rules: list[dict[str, object]] = []

    def extend_rules(payload: object, source: pathlib.Path) -> None:
        if not isinstance(payload, list):
            raise SystemExit(f"invalid rules payload in {source}: expected a list")
        for rule in payload:
            if not isinstance(rule, dict):
                raise SystemExit(f"invalid rule entry in {source}: {rule!r}")
            loaded_rules.append(rule)

    if "rules" in config:
        extend_rules(config.get("rules"), MAP_FILE)

    if rule_files:
        if not isinstance(rule_files, list) or not all(isinstance(item, str) and item for item in rule_files):
            raise SystemExit(f"invalid ruleFiles list in {MAP_FILE}")
        for rule_file in rule_files:
            shard_path = (ROOT / rule_file).resolve()
            if not shard_path.is_file():
                raise SystemExit(f"targeted test map shard not found: {rule_file}")
            shard_payload = json.loads(shard_path.read_text(encoding="utf-8"))
            if isinstance(shard_payload, dict):
                extend_rules(shard_payload.get("rules"), shard_path)
            elif isinstance(shard_payload, list):
                extend_rules(shard_payload, shard_path)
            else:
                raise SystemExit(f"invalid shard payload in {shard_path}: expected object or list")

    if not loaded_rules:
        raise SystemExit(f"targeted test map has no rules: {MAP_FILE}")

    return loaded_rules


rules = load_rules()

suite_order: dict[str, int] = {}
suite_phase: dict[str, str] = {}
for index, suite in enumerate(suite_manifest.get("suites", [])):
    path = suite.get("path")
    if not isinstance(path, str) or not path:
        raise SystemExit(f"invalid suite manifest path entry: {suite}")
    if path in suite_order:
        raise SystemExit(f"duplicate suite path in suite manifest: {path}")
    suite_order[path] = index
    phase = suite.get("phase")
    if not isinstance(phase, str) or not phase:
        raise SystemExit(f"invalid suite manifest phase entry: {suite}")
    suite_phase[path] = phase

if not suite_order:
    raise SystemExit(f"suite manifest has no suites: {SUITE_MANIFEST_PATH}")

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


def ordered_suite_paths(items: list[str]) -> list[str]:
    known = [item for item in unique(items) if item in suite_order]
    unknown = sorted(item for item in unique(items) if item not in suite_order)
    return sorted(known, key=lambda item: suite_order[item]) + unknown


for rule in rules:
    rule_id = rule.get("id")
    if not isinstance(rule_id, str) or not rule_id:
        raise SystemExit(f"invalid rule id in {MAP_FILE}: {rule}")
    if rule.get("matchType") not in {"exact", "prefix", "glob"}:
        raise SystemExit(f"invalid matchType in {MAP_FILE}: {rule}")
    if rule.get("phaseStrategy") not in PHASE_RANK:
        raise SystemExit(f"invalid phaseStrategy in {MAP_FILE}: {rule}")
    risk_class = rule.get("riskClass")
    valid_risk_classes = config.get("riskClasses", [])
    if risk_class is not None and risk_class not in valid_risk_classes:
        raise SystemExit(
            f"invalid riskClass {risk_class!r} in rule {rule_id}; "
            f"valid classes: {valid_risk_classes}"
        )
    for test in rule.get("tests", []):
        if test == "self":
            continue
        if test not in suite_order:
            raise SystemExit(
                f"targeted test map references suite path not present in suite manifest: {test}"
            )

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
            if test == "self":
                if path not in suite_order:
                    continue
                resolved_test = path
            else:
                resolved_test = test
            if resolved_test not in suite_order:
                raise SystemExit(
                    f"selected suite path is not present in suite manifest: {resolved_test}"
                )
            tests.append(resolved_test)
        selected_tests.extend(tests)
        rule_strategy = str(rule["phaseStrategy"])
        matched_rules.append(
            {
                "id": rule["id"],
                "path": path,
                "phase_strategy": rule_strategy,
                "tests": tests,
                "reason": rule["reason"],
                **({"riskClass": rule["riskClass"]} if "riskClass" in rule else {}),
            }
        )
        if PHASE_RANK[rule_strategy] > PHASE_RANK[current_strategy]:
            current_strategy = rule_strategy
        if rule_strategy != "targeted":
            broadening_reasons.append(f"{path}: {rule['reason']}")

# ── Risk-based escalation ──────────────────────────────────────────────────

tracked_file_patterns: list[str] = defaults.get("trackedFilePatterns", [])
confidence_floor: float = float(defaults.get("confidenceFloor", 0.5))
early_on_critical: bool = bool(defaults.get("earlyFullSuiteOnCriticalSurface", True))
early_broaden_domain_threshold: int = int(defaults.get("earlyFullSuiteOnMultipleBroadenDomains", 2))
completion_domain_threshold: int = int(defaults.get("runFullSuiteAtCompletionOnMultipleDomains", 2))
completion_phase_threshold: int = int(defaults.get("runFullSuiteAtCompletionOnMultiplePhases", 3))
completion_suite_threshold: int = int(defaults.get("runFullSuiteAtCompletionOnMultipleSuites", 3))

# 1. Tracked-file-pattern check: any changed path that matches a tracked
#    pattern forces full suite (mirrors Datadog's "tracked files" concept).
tracked_hits: list[str] = []
for path in normalized_paths:
    for pattern in tracked_file_patterns:
        if fnmatch.fnmatch(path, pattern) or fnmatch.fnmatch(pathlib.PurePosixPath(path).name, pattern):
            tracked_hits.append(path)
            break

# 2. Collect risk classes from matched rules.
risk_classes_matched: list[str] = unique(
    [str(r["riskClass"]) for r in matched_rules if r.get("riskClass")]
)

# 3. Derive top-level domains touched by the change set.
def top_level_domain(p: str) -> str:
    parts = pathlib.PurePosixPath(p).parts
    return parts[0] if parts else "."

# 3a. Mirror-domain collapsing: parity-mirror paths map to a single canonical domain.
mirror_domains: dict[str, list[str]] = config.get("mirrorDomains", {})

def resolve_domain(p: str) -> str:
    for canonical, prefixes in mirror_domains.items():
        for prefix in prefixes:
            normalized_prefix = prefix.rstrip("/")
            if p == normalized_prefix or p.startswith(normalized_prefix + "/"):
                return canonical
    return top_level_domain(p)

domains_touched: list[str] = unique([resolve_domain(p) for p in normalized_paths])

# 4. Count distinct broadening domains (resolved domain of the path that triggered broadening).
broaden_domains: set[str] = set()
for entry in matched_rules:
    if entry.get("phase_strategy") not in ("targeted",):
        broaden_domains.add(resolve_domain(str(entry["path"])))

# 5. Confidence score: ratio of mapped (non-unmapped) files to total changed files.
total_files = len(normalized_paths)
mapped_files = total_files - len(unmapped_paths)
confidence_score = round(mapped_files / total_files, 4) if total_files > 0 else 1.0

# 6. Escalation decision.
should_run_full_suite_early = False
early_full_suite_reasons: list[str] = []
decision_log: list[dict[str, object]] = []

# Rule: tracked-file-pattern hit
decision_log.append({
    "rule": "tracked-file-pattern",
    "matched": bool(tracked_hits),
    "detail": tracked_hits[:5] if tracked_hits else "no tracked-file hits",
})
if tracked_hits:
    should_run_full_suite_early = True
    early_full_suite_reasons.append(
        f"Tracked file pattern matched: {', '.join(tracked_hits[:3])}"
    )

# Rule: critical-surface risk class
critical_hit = "critical-surface" in risk_classes_matched
decision_log.append({
    "rule": "critical-surface",
    "matched": critical_hit and early_on_critical,
    "detail": "critical-surface risk class found in matched rules" if critical_hit else "no critical-surface rules matched",
})
if critical_hit and early_on_critical:
    should_run_full_suite_early = True
    early_full_suite_reasons.append("Critical-surface risk class matched")

# Rule: security-sensitive risk class
security_hit = "security-sensitive" in risk_classes_matched
decision_log.append({
    "rule": "security-sensitive",
    "matched": security_hit,
    "detail": "security-sensitive risk class found in matched rules" if security_hit else "no security-sensitive rules matched",
})
if security_hit:
    should_run_full_suite_early = True
    early_full_suite_reasons.append("Security-sensitive risk class matched")

# Rule: cross-domain broadening spread
multi_domain = len(broaden_domains) >= early_broaden_domain_threshold
decision_log.append({
    "rule": "multi-domain-broaden",
    "matched": multi_domain,
    "detail": {
        "broaden_domains": sorted(broaden_domains),
        "threshold": early_broaden_domain_threshold,
    },
})
if multi_domain:
    should_run_full_suite_early = True
    early_full_suite_reasons.append(
        f"Broadening triggered across {len(broaden_domains)} domains "
        f"(threshold: {early_broaden_domain_threshold}): {', '.join(sorted(broaden_domains))}"
    )

# Rule: confidence floor breach
low_confidence = confidence_score < confidence_floor
decision_log.append({
    "rule": "confidence-floor",
    "matched": low_confidence,
    "detail": {
        "confidence_score": confidence_score,
        "floor": confidence_floor,
        "mapped_files": mapped_files,
        "total_files": total_files,
    },
})
ordered_selected_tests = ordered_suite_paths(selected_tests)
selected_phases = unique([suite_phase[test] for test in ordered_selected_tests if test in suite_phase])

run_full_suite_at_completion = bool(defaults.get("runFullSuiteAtCompletion", False))
run_full_suite_at_completion_reasons: list[str] = []

if current_strategy == "full-suite":
    run_full_suite_at_completion = True
    run_full_suite_at_completion_reasons.append(
        "Intermediate phase strategy already requires the full suite"
    )

if should_run_full_suite_early:
    run_full_suite_at_completion = True
    run_full_suite_at_completion_reasons.extend(early_full_suite_reasons)

completion_multi_surface = (
    len(domains_touched) >= completion_domain_threshold
    and len(selected_phases) >= completion_phase_threshold
    and len(ordered_selected_tests) >= completion_suite_threshold
)
if completion_multi_surface:
    run_full_suite_at_completion = True
    run_full_suite_at_completion_reasons.append(
        f"Change spans {len(domains_touched)} domains, {len(selected_phases)} phases, and {len(ordered_selected_tests)} targeted suites "
        f"(thresholds: {completion_domain_threshold} domains / {completion_phase_threshold} phases / {completion_suite_threshold} suites)"
    )

output = {
    "input_paths": RAW_PATHS,
    "normalized_paths": normalized_paths,
    "selected_tests": ordered_selected_tests,
    "intermediate_phase_strategy": current_strategy,
    "intermediate_phase_budget_seconds": int(defaults.get("intermediatePhaseBudgetSeconds", 10)),
    "should_run_full_suite_early": should_run_full_suite_early,
    "early_full_suite_reasons": early_full_suite_reasons,
    "confidence_score": confidence_score,
    "risk_classes_matched": risk_classes_matched,
    "domains_touched": domains_touched,
    "selected_phases": selected_phases,
    "run_full_suite_at_completion": run_full_suite_at_completion,
    "run_full_suite_at_completion_reasons": unique(run_full_suite_at_completion_reasons),
    "matched_rules": matched_rules,
    "broadening_reasons": unique(broadening_reasons),
    "unmapped_paths": unmapped_paths,
    "decision_log": decision_log,
    "final_gate": "bash tests/run-all.sh",
    "terminal_safe_final_gate": "bash scripts/harness/run-all-captured.sh",
}

print(json.dumps(output, indent=2))
PY