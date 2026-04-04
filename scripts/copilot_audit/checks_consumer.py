"""Consumer completeness checks (C1) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib

from .consumer_inventory import (
    HOOK_CONFIG_REL,
    inventory_from_workspace_index,
    workspace_index_path,
)
from .context import AuditContext, ensure_context
from .models import CRITICAL, HIGH, INFO, WARN, CheckResult, Finding


def _check_expected_rel_paths(
    ctx: AuditContext,
    result: CheckResult,
    paths: tuple[str, ...],
    severity: str,
    description: str,
) -> None:
    for rel in paths:
        candidate = ctx.root / rel
        if not candidate.is_file():
            result.findings.append(Finding(
                "C1",
                rel,
                severity,
                f"Missing {description}: {pathlib.Path(rel).name}",
            ))


def _check_counts(result: CheckResult, rel: str, data: dict[str, object], inventory: dict[str, tuple[str, ...]]) -> None:
    counts = data.get("counts")
    if not isinstance(counts, dict):
        return
    expected_lengths = {
        "agents": len(inventory["agents"]),
        "skillsRepo": len(inventory["skills"]),
        "hookScriptsShell": len(inventory["hook_shell"]),
        "hookScriptsPowerShell": len(inventory["hook_powershell"]),
        "hookScriptsPython": len(inventory["hook_python"]),
        "hookScriptsJson": len(inventory["hook_json"]),
    }
    for key, expected in expected_lengths.items():
        actual = counts.get(key)
        if actual is None:
            continue
        if actual != expected:
            result.findings.append(Finding(
                "C1",
                rel,
                WARN,
                f"workspace-index count '{key}' is {actual}, expected {expected}",
            ))


def check_c1_consumer_companion_inventory(root: pathlib.Path | AuditContext) -> CheckResult:
    """C1 — consumer companion inventory from workspace-index is complete on disk."""
    ctx = ensure_context(root)
    result = CheckResult("C1", "Consumer companion inventory completeness")
    rel = ".copilot/workspace/workspace-index.json"

    if ctx.repo_shape != "consumer":
        result.findings.append(Finding("C1", rel, INFO,
                                       "Developer template repo or unknown layout — skip"))
        return result

    index_path = workspace_index_path(ctx)
    if not index_path.exists():
        result.findings.append(Finding("C1", rel, HIGH,
                                       "workspace-index.json not found — consumer completeness cannot be validated"))
        return result

    data, error = ctx.load_json(index_path)
    if error is not None:
        result.findings.append(Finding("C1", rel, CRITICAL,
                                       f"Invalid JSON: {error}"))
        return result
    if not isinstance(data, dict):
        result.findings.append(Finding("C1", rel, CRITICAL,
                                       "workspace-index.json must be a JSON object"))
        return result

    inventory = inventory_from_workspace_index(data, ctx)
    _check_counts(result, rel, data, inventory)

    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".github/agents") / filename) for filename in inventory["agents"]),
        HIGH,
        "agent from workspace-index inventory",
    )
    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".github/skills") / dirname / "SKILL.md") for dirname in inventory["skills"]),
        WARN,
        "skill from workspace-index inventory",
    )
    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".github/prompts") / filename) for filename in inventory["prompts"]),
        WARN,
        "prompt from workspace-index inventory",
    )
    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".github/instructions") / filename) for filename in inventory["instructions"]),
        WARN,
        "instruction from workspace-index inventory",
    )
    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".github/hooks/scripts") / filename) for filename in inventory["hook_shell"]),
        HIGH,
        "shell hook from workspace-index inventory",
    )
    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".github/hooks/scripts") / filename) for filename in inventory["hook_powershell"]),
        WARN,
        "PowerShell hook from workspace-index inventory",
    )
    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".github/hooks/scripts") / filename) for filename in inventory["hook_python"]),
        HIGH,
        "Python hook helper from workspace-index inventory",
    )
    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".github/hooks/scripts") / filename) for filename in inventory["hook_json"]),
        HIGH,
        "JSON hook helper from workspace-index inventory",
    )
    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".github/workflows") / filename) for filename in inventory["workflow_files"]),
        HIGH,
        "workflow from workspace-index inventory",
    )
    _check_expected_rel_paths(
        ctx,
        result,
        tuple(str(pathlib.Path(".copilot/workspace") / filename) for filename in inventory["workspace_files"]),
        HIGH,
        "core workspace file from workspace-index inventory",
    )

    if not (ctx.root / HOOK_CONFIG_REL).is_file():
        result.findings.append(Finding("C1", HOOK_CONFIG_REL, HIGH,
                                       "Missing hooks config from consumer inventory"))

    return result