"""Starter-kit checks (K1–K2) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib

from .context import AuditContext, ensure_context
from .models import Finding, CheckResult, CRITICAL, HIGH, WARN, INFO


def check_k1_starter_kit_plugins(root: pathlib.Path | AuditContext) -> CheckResult:
    """K1 — starter-kit plugin.json files: valid JSON + basic metadata."""
    ctx = ensure_context(root)
    result = CheckResult("K1", "Starter-kit plugins: valid JSON + metadata")
    if not ctx.starter_kits_root.is_dir():
        result.findings.append(Finding("K1", "starter-kits/", INFO,
                                       "No starter-kits directory — skip"))
        return result
    for kit_dir in ctx.starter_kit_dirs:
        plugin_path = kit_dir / "plugin.json"
        rel = ctx.rel(plugin_path)
        if not plugin_path.exists():
            result.findings.append(Finding("K1", rel, HIGH,
                                           "Missing plugin.json for starter kit"))
            continue
        data, error = ctx.load_json(plugin_path)
        if error is not None:
            result.findings.append(Finding("K1", rel, CRITICAL,
                                           f"Invalid JSON: {error}"))
            continue
        for key in ("name", "displayName", "description", "version"):
            val = data.get(key)
            if not isinstance(val, str) or not val:
                result.findings.append(Finding("K1", rel, HIGH,
                                               f"Missing or empty '{key}' field in starter-kit plugin"))
    return result


def check_k2_starter_registry(root: pathlib.Path | AuditContext) -> CheckResult:
    """K2 — starter-kits REGISTRY.json consistency."""
    ctx = ensure_context(root)
    result = CheckResult("K2", "Starter-kits registry consistency")
    kits_root = ctx.starter_kits_root
    registry_path = kits_root / "REGISTRY.json"
    if not registry_path.exists():
        result.findings.append(Finding("K2", ctx.rel(registry_path), INFO,
                                       "REGISTRY.json not found — starter-kits registry missing"))
        return result
    data, error = ctx.load_json(registry_path)
    if error is not None:
        result.findings.append(Finding("K2", ctx.rel(registry_path), CRITICAL,
                                       f"Invalid JSON: {error}"))
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
            result.findings.append(Finding("K2", ctx.rel(registry_path), HIGH,
                                           "Kit entry missing 'name' field"))
            continue
        seen.add(name)
        kit_dir = kits_root / name
        if not kit_dir.is_dir():
            result.findings.append(Finding("K2", ctx.rel(kit_dir), HIGH,
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
                result.findings.append(Finding("K2", ctx.rel(registry_path), HIGH,
                                               f"Kit '{name}': file listed in REGISTRY.json missing: {rel_path}"))

    for kit_dir in ctx.starter_kit_dirs:
        if kit_dir.name not in seen:
            result.findings.append(Finding("K2", ctx.rel(kit_dir), WARN,
                                           "Starter-kit directory not listed in REGISTRY.json"))
    return result
