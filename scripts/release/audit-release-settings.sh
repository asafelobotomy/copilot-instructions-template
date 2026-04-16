#!/usr/bin/env bash
# scripts/release/audit-release-settings.sh -- audit GitHub repository settings against the current release workflow assumptions.
set -euo pipefail

source "$(dirname "$0")/../lib.sh"

require_command python3

repo="${GITHUB_REPOSITORY:-}"
branch="main"
fixture_dir="${RELEASE_SETTINGS_FIXTURE_DIR:-}"

usage() {
  echo "Usage: bash scripts/release/audit-release-settings.sh [--repo <owner/name>] [--branch <branch>]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="$2"
      shift 2
      ;;
    --branch)
      branch="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$repo" ]]; then
  if [[ -n "$fixture_dir" ]]; then
    repo="fixture/repository"
  else
    require_command gh
    repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
  fi
fi

read_fixture_or_api() {
  local name="$1"
  local endpoint="$2"

  if [[ -n "$fixture_dir" ]]; then
    cat "$fixture_dir/$name.json"
  else
    gh api "$endpoint"
  fi
}

if [[ -z "$fixture_dir" ]]; then
  require_command gh
fi

repo_json=$(read_fixture_or_api repo "repos/$repo")
workflow_json=$(read_fixture_or_api workflow "repos/$repo/actions/permissions/workflow")
rules_json=$(read_fixture_or_api rules "repos/$repo/rules/branches/$branch")

REPO_NAME="$repo" \
TARGET_BRANCH="$branch" \
REPO_JSON="$repo_json" \
WORKFLOW_JSON="$workflow_json" \
RULES_JSON="$rules_json" \
python3 - <<'PY'
import json
import os
import sys


repo_name = os.environ["REPO_NAME"]
target_branch = os.environ["TARGET_BRANCH"]
repo = json.loads(os.environ["REPO_JSON"])
workflow = json.loads(os.environ["WORKFLOW_JSON"])
rules = json.loads(os.environ["RULES_JSON"])

rule_types = [rule.get("type", "<unknown>") for rule in rules]
advanced_rules = [rule for rule in rule_types if rule not in {"deletion", "non_fast_forward"}]

passes = []
notes = []
warnings = []
errors = []

if repo.get("allow_auto_merge"):
    passes.append("Repository auto-merge is enabled.")
else:
    errors.append("Repository auto-merge is disabled, but the release workflow uses gh pr merge --auto.")

if repo.get("allow_squash_merge"):
    passes.append("Repository squash merge is enabled.")
else:
    errors.append("Repository squash merge is disabled, but the release workflow merges release PRs with --squash.")

if workflow.get("can_approve_pull_request_reviews"):
    passes.append("GitHub Actions may create and approve pull requests.")
else:
    errors.append(
        "GitHub Actions may not create and approve pull requests. Enable the repository setting under Actions > General > Workflow permissions."
    )

default_permissions = workflow.get("default_workflow_permissions")
if default_permissions == "read":
    notes.append(
        "Default workflow permissions are read-only; the release job relies on explicit job-level write permissions."
    )
elif default_permissions:
    warnings.append(
        f"Default workflow permissions are {default_permissions}. Read-only defaults are safer for this repo because the release job already scopes write access."
    )

if "non_fast_forward" in rule_types:
    passes.append(f"{target_branch} blocks non-fast-forward pushes.")
else:
    warnings.append(
        f"{target_branch} does not currently block non-fast-forward pushes. Add this rule to protect branch history."
    )

if "deletion" in rule_types:
    passes.append(f"{target_branch} blocks branch deletion.")
else:
    warnings.append(
        f"{target_branch} does not currently block branch deletion. Add this rule to protect the default branch."
    )

if "required_linear_history" in rule_types:
    passes.append(f"{target_branch} requires linear history.")
else:
    notes.append(
        f"{target_branch} does not require linear history. Consider enabling it because release automation already merges with --squash."
    )

if not advanced_rules:
    notes.append(
        "The active ruleset profile matches the current lightweight GITHUB_TOKEN release-PR model: no required pull-request approvals or status checks are enforced on the target branch."
    )

if "pull_request" in rule_types:
    warnings.append(
        f"{target_branch} requires pull requests before merging. The current release workflow does not self-approve release PRs, so release merges may become manual unless you change the workflow or token model."
    )

if "required_status_checks" in rule_types:
    warnings.append(
        f"{target_branch} requires status checks before merging. Release PRs created with GITHUB_TOKEN will not trigger new workflows, so use a GitHub App/PAT for release PRs or relax this rule."
    )

if "merge_queue" in rule_types:
    warnings.append(
        f"{target_branch} uses merge queue. Verify that gh pr merge --auto still matches your queue policy for release PRs."
    )

print(f"Release governance audit for {repo_name} ({target_branch})")
print("Compatibility profile: lightweight GITHUB_TOKEN release PR automation")
if rule_types:
    print("Detected branch rules: " + ", ".join(rule_types))
else:
    print("Detected branch rules: none")

for message in passes:
    print(f"PASS: {message}")
for message in notes:
    print(f"NOTE: {message}")
for message in warnings:
    print(f"WARN: {message}")
for message in errors:
    print(f"ERROR: {message}")

if errors:
    print("Result: incompatible with the current lightweight release workflow")
    sys.exit(1)

if warnings:
    print("Result: compatible with caveats")
else:
    print("Result: compatible")
PY