"""VS Code settings checks (VS1) for the Copilot Audit tool."""
from __future__ import annotations

import json
import pathlib

from .models import Finding, CheckResult, CRITICAL, WARN, INFO


def check_vs1_settings_plugins(root: pathlib.Path) -> CheckResult:
    """VS1 — .vscode/settings.json: valid JSON + customization paths resolve."""
    result = CheckResult("VS1", "VS Code settings: JSON valid + customization paths resolve")
    settings_file = root / ".vscode" / "settings.json"
    if not settings_file.exists():
        result.findings.append(Finding("VS1", ".vscode/settings.json", INFO,
                                       "File not found — skip"))
        return result
    rel = str(settings_file.relative_to(root))
    try:
        data = json.loads(settings_file.read_text(encoding="utf-8", errors="replace"))
    except json.JSONDecodeError as exc:
        result.findings.append(Finding("VS1", rel, CRITICAL,
                                       f"Invalid JSON: {exc}"))
        return result

    def _check_path_list(key: str, base: pathlib.Path = root) -> None:
        paths = data.get(key, [])
        if not isinstance(paths, list):
            return
        for p in paths:
            if not isinstance(p, str):
                continue
            resolved = pathlib.Path(p) if pathlib.Path(p).is_absolute() else base / p
            if not resolved.exists():
                result.findings.append(Finding(
                    "VS1", rel, WARN,
                    f"{key} entry not found: {p}",
                ))

    _check_path_list("chat.plugins.paths")
    _check_path_list("chat.instructionsFilesLocations")
    _check_path_list("chat.promptFilesLocations")
    _check_path_list("chat.agentFilesLocations")
    _check_path_list("chat.agentSkillsLocations")
    _check_path_list("chat.hookFilesLocations")

    return result
