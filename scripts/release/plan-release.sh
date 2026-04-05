#!/usr/bin/env bash
# scripts/release/plan-release.sh -- decide whether post-CI automation should run release-please.
set -euo pipefail

source "$(dirname "$0")/../lib.sh"

require_command git python3

head_ref="HEAD"
base_ref=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --head)
      head_ref="$2"
      shift 2
      ;;
    --base)
      base_ref="$2"
      shift 2
      ;;
        *)
            echo "Usage: bash scripts/release/plan-release.sh [--base <git-ref>] [--head <git-ref>]"
      exit 1
      ;;
  esac
done

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

if [[ -z "$base_ref" ]]; then
  if base_ref=$(git describe --tags --abbrev=0 --match 'v*' "$head_ref" 2>/dev/null); then
    :
  else
    base_ref=$(git rev-list --max-parents=0 "$head_ref" | tail -n 1)
  fi
fi

declare -a release_paths=(
    template
    .github/agents
    starter-kits
    SETUP.md
    UPDATE.md
    AGENTS.md
    scripts/workspace/check-workspace-drift.sh
)

mapfile -t release_files < <(git diff --name-only "$base_ref" "$head_ref" -- "${release_paths[@]}" | sed '/^$/d')
release_commit_messages=$(git log --format=%B%x1e "$base_ref..$head_ref" -- "${release_paths[@]}" || true)
current_version=$(tr -d '[:space:]' < VERSION.md)

RELEASE_FILES=$(printf '%s\n' "${release_files[@]:-}") \
RELEASE_COMMITS="$release_commit_messages" \
CURRENT_VERSION="$current_version" \
python3 - <<'PY'
import os
import re


def bump_version(version: str, bump: str) -> str:
    major, minor, patch = (int(part) for part in version.split("."))
    if bump == "major":
        return f"{major + 1}.0.0"
    if bump == "minor":
        return f"{major}.{minor + 1}.0"
    if bump == "patch":
        return f"{major}.{minor}.{patch + 1}"
    return version


def rank(level: str) -> int:
    return {"none": 0, "patch": 1, "minor": 2, "major": 3}[level]


def stronger(current: str, candidate: str) -> str:
    return candidate if rank(candidate) > rank(current) else current


def first_nonempty_line(text: str) -> str:
    for line in text.splitlines():
        stripped = line.strip()
        if stripped:
            return stripped
    return ""


def fallback_bump(message: str) -> str:
    if re.search(r"BREAKING[ -]CHANGE:\s", message):
        return "major"
    if re.search(r"(^|\n)\s*[-*]?\s*\w+(?:\([^)]+\))?!:\s", message, re.MULTILINE):
        return "major"
    if re.search(r"(^|\n)\s*[-*]?\s*feat(?:\([^)]+\))?:\s", message, re.MULTILINE):
        return "minor"
    if re.search(r"(^|\n)\s*[-*]?\s*(fix|deps|docs|refactor|perf|build|ci|test|chore)(?:\([^)]+\))?:\s", message, re.MULTILINE):
        return "patch"
    return "none"


release_files = [line for line in os.environ.get("RELEASE_FILES", "").splitlines() if line]
messages = [chunk.strip() for chunk in os.environ.get("RELEASE_COMMITS", "").split("\x1e") if chunk.strip()]
current_version = os.environ["CURRENT_VERSION"]

should_release = bool(release_files or messages)
native_bump = "none"
inferred_bump = "none"

for message in messages:
    header = first_nonempty_line(message)
    conventional = re.match(r"^(feat|fix|deps)(?:\([^)]+\))?(!)?:\s", header)
    if conventional:
        commit_type = conventional.group(1)
        bang = conventional.group(2)
        if bang or re.search(r"BREAKING[ -]CHANGE:\s", message):
            native_bump = stronger(native_bump, "major")
        elif commit_type == "feat":
            native_bump = stronger(native_bump, "minor")
        else:
            native_bump = stronger(native_bump, "patch")
    inferred_bump = stronger(inferred_bump, fallback_bump(message))

if not should_release:
    bump = "none"
    force_release_as = False
    next_version = current_version
    reason = "no release-driving changes since last tag"
elif native_bump != "none":
    bump = native_bump
    force_release_as = False
    next_version = bump_version(current_version, bump)
    reason = "release-driving commits include releasable conventional headers"
elif inferred_bump != "none":
    bump = inferred_bump
    force_release_as = True
    next_version = bump_version(current_version, bump)
    reason = "release-driving commits imply a semver bump through fallback rules"
else:
    bump = "patch"
    force_release_as = True
    next_version = bump_version(current_version, bump)
    reason = "release-driving changes default to a patch release because no semver signal was present"

outputs = {
    "should_release": "true" if should_release else "false",
    "version_bump": bump,
    "force_release_as": "true" if force_release_as else "false",
    "next_version": next_version,
    "reason": reason,
}

for key, value in outputs.items():
    print(f"{key}={value}")

github_output = os.environ.get("GITHUB_OUTPUT")
if github_output:
    with open(github_output, "a", encoding="utf-8") as handle:
        for key, value in outputs.items():
            handle.write(f"{key}={value}\n")
PY