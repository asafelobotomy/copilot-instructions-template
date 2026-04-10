"""Consumer inventory helpers shared by audit checks."""
from __future__ import annotations

from .context import AuditContext


WORKSPACE_INDEX_REL = ".copilot/workspace/operations/workspace-index.json"
HOOK_CONFIG_REL = ".github/hooks/copilot-hooks.json"
OPTIONAL_VSCODE_FILES = (
    ".vscode/settings.json",
    ".vscode/extensions.json",
    ".vscode/mcp.json",
)
OPTIONAL_ROOT_FILES = (
    "CLAUDE.md",
)
STARTER_KIT_MANIFEST_GLOBS = (
    ".github/starter-kits/*/plugin.json",
    ".github/starter-kits/*/skills/*/SKILL.md",
    ".github/starter-kits/*/instructions/*.instructions.md",
    ".github/starter-kits/*/prompts/*.prompt.md",
)


def workspace_index_path(ctx: AuditContext):
    """Return the local consumer workspace-index path."""
    return ctx.root / WORKSPACE_INDEX_REL


def _string_list(payload: object, *keys: str) -> tuple[str, ...]:
    current = payload
    for key in keys:
        if not isinstance(current, dict):
            return ()
        current = current.get(key)
    if not isinstance(current, list):
        return ()
    return tuple(item for item in current if isinstance(item, str))


def inventory_from_workspace_index(
    payload: object,
    ctx: AuditContext | None = None,
) -> dict[str, tuple[str, ...]]:
    """Normalise the explicit workspace-index inventory for consumer checks."""
    return {
        "agents": _string_list(payload, "agents"),
        "agent_support_files": _string_list(payload, "agentSupportFiles"),
        "skills": _string_list(payload, "skills", "repo"),
        "prompts": _string_list(payload, "prompts"),
        "instructions": _string_list(payload, "instructions"),
        "workspace_files": _string_list(payload, "workspaceFiles"),
        "workflow_files": _string_list(payload, "workflowFiles"),
        "hook_shell": _string_list(payload, "hookScripts", "shell"),
        "hook_powershell": _string_list(payload, "hookScripts", "powershell"),
        "hook_python": _string_list(payload, "hookScripts", "python"),
        "hook_json": _string_list(payload, "hookScripts", "json"),
    }


def managed_consumer_file_paths(
    ctx: AuditContext,
    inventory: dict[str, tuple[str, ...]],
) -> tuple[str, ...]:
    """Return the managed consumer files that currently exist on disk."""
    files: set[str] = set()

    for filename in inventory["agents"]:
        candidate = ctx.root / ".github" / "agents" / filename
        if candidate.is_file():
            files.add(ctx.rel(candidate))

    for filename in inventory["agent_support_files"]:
        candidate = ctx.root / ".github" / "agents" / filename
        if candidate.is_file():
            files.add(ctx.rel(candidate))

    for dirname in inventory["skills"]:
        candidate = ctx.root / ".github" / "skills" / dirname / "SKILL.md"
        if candidate.is_file():
            files.add(ctx.rel(candidate))

    for filename in inventory["prompts"]:
        candidate = ctx.root / ".github" / "prompts" / filename
        if candidate.is_file():
            files.add(ctx.rel(candidate))

    for filename in inventory["instructions"]:
        candidate = ctx.root / ".github" / "instructions" / filename
        if candidate.is_file():
            files.add(ctx.rel(candidate))

    hook_config = ctx.root / HOOK_CONFIG_REL
    if hook_config.is_file():
        files.add(HOOK_CONFIG_REL)

    for filename in inventory["hook_shell"] + inventory["hook_powershell"] + inventory["hook_python"] + inventory["hook_json"]:
        candidate = ctx.root / ".github" / "hooks" / "scripts" / filename
        if candidate.is_file():
            files.add(ctx.rel(candidate))

    for filename in inventory["workspace_files"]:
        candidate = ctx.root / ".copilot" / "workspace" / filename
        if candidate.is_file():
            files.add(ctx.rel(candidate))

    for filename in inventory["workflow_files"]:
        candidate = ctx.root / ".github" / "workflows" / filename
        if candidate.is_file():
            files.add(ctx.rel(candidate))

    for rel in OPTIONAL_VSCODE_FILES + OPTIONAL_ROOT_FILES:
        candidate = ctx.root / rel
        if candidate.is_file():
            files.add(rel)

    for pattern in STARTER_KIT_MANIFEST_GLOBS:
        for candidate in ctx.root.glob(pattern):
            if candidate.is_file():
                files.add(ctx.rel(candidate))

    return tuple(sorted(files))