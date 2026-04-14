"""MCP checks (M1–M4) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib
import re

from .context import AuditContext, ensure_context
from .models import Finding, CheckResult, HIGH, INFO, CRITICAL, WARN


def check_m1_mcp_valid_json(root: pathlib.Path | AuditContext) -> CheckResult:
    """M1 — .vscode/mcp.json: file is valid JSON with a servers key."""
    ctx = ensure_context(root)
    result = CheckResult("M1", "MCP config: valid JSON + servers key")
    mcp_file = ctx.root / ".vscode" / "mcp.json"
    if not mcp_file.exists():
        result.findings.append(Finding("M1", ".vscode/mcp.json", INFO,
                                       "File not found — MCP not configured"))
        return result
    rel = ctx.rel(mcp_file)
    data, error = ctx.load_jsonc(mcp_file)
    if error is not None:
        result.findings.append(Finding("M1", rel, CRITICAL,
                                       f"Invalid JSON: {error}"))
        return result
    if "servers" not in data:
        result.findings.append(Finding("M1", rel, HIGH,
                                       "Missing top-level 'servers' key"))
    return result


def check_m2_mcp_no_npm_antipatterns(root: pathlib.Path | AuditContext) -> CheckResult:
    """M2 — mcp.json: npx+mcp-server-git/fetch anti-pattern; deprecated references."""
    ctx = ensure_context(root)
    result = CheckResult("M2", "MCP config: no npm anti-patterns")
    mcp_file = ctx.root / ".vscode" / "mcp.json"
    if not mcp_file.exists():
        return result
    rel = ctx.rel(mcp_file)
    data, error = ctx.load_jsonc(mcp_file)
    if error is not None:
        return result  # M1 already flagged this
    servers = data.get("servers", {})
    if not isinstance(servers, dict):
        return result
    for srv_name, srv_cfg in servers.items():
        if not isinstance(srv_cfg, dict):
            continue
        command = srv_cfg.get("command", "")
        args    = srv_cfg.get("args", [])
        args_str = " ".join(str(a) for a in args)
        if command == "npx" and re.search(r"mcp-server-(git|fetch)", args_str):
            result.findings.append(Finding("M2", rel, CRITICAL,
                                           f"Server '{srv_name}': uses npx with "
                                           f"mcp-server-git/fetch (npm packages do not exist; "
                                           "use 'uvx' instead)"))
        if re.search(r"@modelcontextprotocol/server-(git|fetch)", args_str):
            result.findings.append(Finding("M2", rel, HIGH,
                                           f"Server '{srv_name}': references "
                                           "@modelcontextprotocol/server-git or "
                                           "server-fetch (packages do not exist on npm)"))
    return result


def check_m3_mcp_no_secrets(root: pathlib.Path | AuditContext) -> CheckResult:
    """M3 — mcp.json: no literal secrets in env values."""
    ctx = ensure_context(root)
    result = CheckResult("M3", "MCP config: no literal secrets")
    mcp_file = ctx.root / ".vscode" / "mcp.json"
    if not mcp_file.exists():
        return result
    rel = ctx.rel(mcp_file)
    data, error = ctx.load_jsonc(mcp_file)
    if error is not None:
        return result
    secret_pattern = re.compile(
        r"(_KEY|_TOKEN|_SECRET|_PASSWORD|_APIKEY|_API_KEY)\Z", re.IGNORECASE
    )
    placeholder_pattern = re.compile(r"\$\{")
    servers = data.get("servers", {})
    if not isinstance(servers, dict):
        return result
    for srv_name, srv_cfg in servers.items():
        if not isinstance(srv_cfg, dict):
            continue
        env = srv_cfg.get("env", {})
        if not isinstance(env, dict):
            continue
        for key, val in env.items():
            if secret_pattern.search(key) and isinstance(val, str):
                if val and not placeholder_pattern.search(val) and len(val) > 4:
                    result.findings.append(Finding("M3", rel, HIGH,
                                                   f"Server '{srv_name}': env key '{key}' "
                                                   "appears to contain a literal secret "
                                                   "(use ${{input:id}} syntax instead)"))
    return result


def check_m4_mcp_stdio_sandbox(root: pathlib.Path | AuditContext) -> CheckResult:
    """M4 — mcp.json: stdio servers should have sandboxEnabled on supported platforms."""
    ctx = ensure_context(root)
    result = CheckResult("M4", "MCP config: stdio servers have sandbox")
    mcp_file = ctx.root / ".vscode" / "mcp.json"
    if not mcp_file.exists():
        return result
    rel = ctx.rel(mcp_file)
    data, error = ctx.load_jsonc(mcp_file)
    if error is not None:
        return result  # M1 already flagged this
    servers = data.get("servers", {})
    if not isinstance(servers, dict):
        return result
    for srv_name, srv_cfg in servers.items():
        if not isinstance(srv_cfg, dict):
            continue
        if srv_cfg.get("type") != "stdio":
            continue
        if srv_cfg.get("disabled", False):
            continue
        # uvx-based servers are exempt: the VS Code sandbox proxy intercepts
        # PyPI network access during the uvx launcher phase and triggers
        # repeated domain-approval prompts that cannot be reliably suppressed
        # via per-server allowedDomains.  Only npx-based servers are sandboxed.
        if srv_cfg.get("command") == "uvx":
            continue
        if not srv_cfg.get("sandboxEnabled", False):
            result.findings.append(Finding("M4", rel, WARN,
                                           f"Server '{srv_name}': stdio server without "
                                           "'sandboxEnabled: true' — consider sandboxing "
                                           "to restrict filesystem/network access"))
    return result
