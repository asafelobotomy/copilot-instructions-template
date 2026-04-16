"""VS Code settings checks (VS1) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib

from .context import AuditContext, ensure_context
from .models import Finding, CheckResult, CRITICAL, WARN, INFO


def check_vs1_settings_plugins(root: pathlib.Path | AuditContext) -> CheckResult:
    """VS1 — .vscode/settings.json: valid JSON + customization paths resolve."""
    ctx = ensure_context(root)
    result = CheckResult("VS1", "VS Code settings: JSON valid + customization paths resolve")
    settings_file = ctx.root / ".vscode" / "settings.json"
    if not settings_file.exists():
        result.findings.append(Finding("VS1", ".vscode/settings.json", INFO,
                                       "File not found — skip"))
        return result
    rel = ctx.rel(settings_file)
    data, error = ctx.load_jsonc(settings_file)
    if error is not None:
        result.findings.append(Finding("VS1", rel, CRITICAL,
                                       f"Invalid JSON: {error}"))
        return result

    def _iter_path_entries(key: str) -> list[tuple[str, bool]] | None:
        value = data.get(key)
        if value is None:
            return None
        if isinstance(value, dict):
            return [(path, enabled) for path, enabled in value.items() if isinstance(path, str)]
        if isinstance(value, list):
            return [(path, True) for path in value if isinstance(path, str)]
        result.findings.append(Finding(
            "VS1", rel, WARN,
            f"{key} must be an object mapping path -> boolean or a list of paths",
        ))
        return []

    def _resolve_path(raw_path: str, base: pathlib.Path = ctx.root) -> pathlib.Path:
        path_obj = pathlib.Path(raw_path).expanduser()
        if path_obj.is_absolute():
            return path_obj
        return base / path_obj

    def _check_plugin_locations(key: str = "chat.pluginLocations") -> None:
        entries = _iter_path_entries(key)
        if entries is None:
            return
        for raw_path, enabled in entries:
            if enabled is False:
                continue
            if "${" in raw_path:
                result.findings.append(Finding(
                    "VS1", rel, WARN,
                    f"{key} should use literal paths, not variable syntax: {raw_path}",
                ))
                continue
            resolved = _resolve_path(raw_path)
            if not resolved.exists():
                result.findings.append(Finding(
                    "VS1", rel, WARN,
                    f"{key} entry not found: {raw_path}",
                ))

    def _check_path_roots(key: str) -> None:
        entries = _iter_path_entries(key)
        if entries is None:
            return
        for raw_path, enabled in entries:
            if enabled is False:
                continue
            resolved = _resolve_path(raw_path)
            if not resolved.exists():
                result.findings.append(Finding(
                    "VS1", rel, WARN,
                    f"{key} entry not found: {raw_path}",
                ))

    def _check_path_list(key: str, base: pathlib.Path = ctx.root) -> None:
        paths = data.get(key, [])
        if not isinstance(paths, list):
            result.findings.append(Finding(
                "VS1", rel, WARN,
                f"{key} must be a list of paths",
            ))
            return
        for p in paths:
            if not isinstance(p, str):
                continue
            resolved = _resolve_path(p, base)
            if not resolved.exists():
                result.findings.append(Finding(
                    "VS1", rel, WARN,
                    f"{key} entry not found: {p}",
                ))

    _check_plugin_locations()
    _check_path_list("chat.plugins.paths")
    _check_path_roots("chat.instructionsFilesLocations")
    _check_path_roots("chat.promptFilesLocations")
    _check_path_roots("chat.agentFilesLocations")
    _check_path_roots("chat.skillsLocations")
    _check_path_roots("chat.agentSkillsLocations")
    _check_path_roots("chat.hookFilesLocations")

    return result
