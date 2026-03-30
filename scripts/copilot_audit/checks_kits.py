"""Starter-kit checks (K1–K2) for the Copilot Audit tool."""
from __future__ import annotations

import json
import pathlib

from .models import Finding, CheckResult, CRITICAL, HIGH, WARN, INFO


def check_k1_starter_kit_plugins(root: pathlib.Path) -> CheckResult:
    """K1 — starter-kit plugin.json files: valid JSON + basic metadata."""
    result = CheckResult("K1", "Starter-kit plugins: valid JSON + metadata")
    kits_root = root / "starter-kits"
    if not kits_root.is_dir():
        result.findings.append(Finding("K1", "starter-kits/", INFO,
                                       "No starter-kits directory — skip"))
        return result
    for kit_dir in sorted(p for p in kits_root.iterdir() if p.is_dir()):
        plugin_path = kit_dir / "plugin.json"
        rel = str(plugin_path.relative_to(root))
        if not plugin_path.exists():
            result.findings.append(Finding("K1", rel, HIGH,
                                           "Missing plugin.json for starter kit"))
            continue
        try:
            data = json.loads(plugin_path.read_text(encoding="utf-8", errors="replace"))
        except json.JSONDecodeError as exc:
            result.findings.append(Finding("K1", rel, CRITICAL,
                                           f"Invalid JSON: {exc}"))
            continue
        for key in ("name", "displayName", "description", "version"):
            val = data.get(key)
            if not isinstance(val, str) or not val:
                result.findings.append(Finding("K1", rel, HIGH,
                                               f"Missing or empty '{key}' field in starter-kit plugin"))
    return result


def check_k2_starter_registry(root: pathlib.Path) -> CheckResult:
    """K2 — starter-kits REGISTRY.json consistency."""
    result = CheckResult("K2", "Starter-kits registry consistency")
    kits_root = root / "starter-kits"
    registry_path = kits_root / "REGISTRY.json"
    if not registry_path.exists():
        result.findings.append(Finding("K2", str(registry_path.relative_to(root)), INFO,
                                       "REGISTRY.json not found — starter-kits registry missing"))
        return result
    try:
        data = json.loads(registry_path.read_text(encoding="utf-8", errors="replace"))
    except json.JSONDecodeError as exc:
        result.findings.append(Finding("K2", str(registry_path.relative_to(root)), CRITICAL,
                                       f"Invalid JSON: {exc}"))
        return result

    kits = data.get("kits", [])
    if not isinstance(kits, list):
        return result

    seen: set[str] = set()
    for kit in kits:
        if not isinstance(kit, dict):
            continue
        name = kit.get("name")
        if not isinstance(name, str) or not name:
            result.findings.append(Finding("K2", str(registry_path.relative_to(root)), HIGH,
                                           "Kit entry missing 'name' field"))
            continue
        seen.add(name)
        kit_dir = kits_root / name
        if not kit_dir.is_dir():
            result.findings.append(Finding("K2", str(kit_dir.relative_to(root)), HIGH,
                                           f"Kit '{name}' listed in REGISTRY.json but directory is missing"))
            continue
        files = kit.get("files", [])
        if not isinstance(files, list):
            continue
        for rel_path in files:
            if not isinstance(rel_path, str):
                continue
            candidate = kit_dir / rel_path
            if not candidate.exists():
                result.findings.append(Finding("K2", str(registry_path.relative_to(root)), HIGH,
                                               f"Kit '{name}': file listed in REGISTRY.json missing: {rel_path}"))

    for kit_dir in sorted(p for p in kits_root.iterdir() if p.is_dir()):
        if kit_dir.name not in seen:
            result.findings.append(Finding("K2", str(kit_dir.relative_to(root)), WARN,
                                           "Starter-kit directory not listed in REGISTRY.json"))
    return result
