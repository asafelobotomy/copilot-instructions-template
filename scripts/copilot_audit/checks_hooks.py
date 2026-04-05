"""Hook checks (H1–H2, SH1–SH3, PS1) for the Copilot Audit tool."""
from __future__ import annotations

import json
import pathlib
import re
import subprocess

from .context import AuditContext, ensure_context
from .models import Finding, CheckResult, CRITICAL, HIGH, WARN, INFO
from .helpers import has_command


def check_h1_hooks_valid_json(root: pathlib.Path | AuditContext) -> CheckResult:
    """H1 — copilot-hooks.json: exists and is valid JSON."""
    ctx = ensure_context(root)
    result = CheckResult("H1", "Hooks config: exists and valid JSON")
    checked = False
    for hooks_file in ctx.hook_config_files:
        if not hooks_file.exists():
            continue
        checked = True
        rel = ctx.rel(hooks_file)
        _, error = ctx.load_json(hooks_file)
        if error is not None:
            result.findings.append(Finding("H1", rel, CRITICAL,
                                           f"Invalid JSON: {error}"))
    if not checked:
        result.findings.append(Finding("H1", ".github/hooks/copilot-hooks.json",
                                       HIGH, "hooks config not found — hooks will not run"))
    return result


def check_h2_hooks_scripts_exist(root: pathlib.Path | AuditContext) -> CheckResult:
    """H2 — Every script path referenced in copilot-hooks.json exists on disk."""
    ctx = ensure_context(root)
    result = CheckResult("H2", "Hooks config: all referenced scripts exist")
    for hooks_file in ctx.hook_config_files:
        if not hooks_file.exists():
            continue
        rel = ctx.rel(hooks_file)
        data, error = ctx.load_json(hooks_file)
        if error is not None:
            continue  # H1 already flagged this
        raw = json.dumps(data)
        for script_path in re.findall(r'"([^"]+\.sh)"', raw):
            candidate = ctx.root / script_path.lstrip("/")
            if not candidate.exists():
                result.findings.append(Finding(
                    "H2", rel, HIGH,
                    f"Referenced script not found: {script_path}",
                ))
        for ps_path in re.findall(r'"[^"]*?([./A-Za-z0-9_\\\\/-]+\.ps1)"', raw):
            norm = ps_path.replace("\\", "/")
            rel_path = norm.lstrip("/")
            if rel_path.startswith("./"):
                rel_path = rel_path[2:]
            candidate = ctx.root / rel_path
            if not candidate.exists():
                result.findings.append(Finding(
                    "H2", rel, WARN,
                    f"Referenced script not found: {ps_path}",
                ))
    return result


def check_sh1_shebang(root: pathlib.Path | AuditContext) -> CheckResult:
    """SH1 — Hook shell scripts: shebang present."""
    ctx = ensure_context(root)
    result = CheckResult("SH1", "Hook scripts: shebang present")
    found = False
    for sh in ctx.shell_scripts:
        found = True
        rel = ctx.rel(sh)
        first_line = ctx.read_text(sh).split("\n")[0]
        if not first_line.startswith("#!/"):
            result.findings.append(Finding("SH1", rel, HIGH,
                                           "Missing shebang line"))
    if not found:
        result.findings.append(Finding("SH1", ".github/hooks/scripts/", INFO,
                                       "No shell hook scripts found"))
    return result


def check_sh2_pipefail(root: pathlib.Path | AuditContext) -> CheckResult:
    """SH2 — Hook shell scripts: set -euo pipefail present.

    lib-hooks.sh is a sourced library and is intentionally excluded.
    """
    ctx = ensure_context(root)
    result = CheckResult("SH2", "Hook scripts: set -euo pipefail")
    for sh in ctx.shell_scripts:
        if sh.name == "lib-hooks.sh":
            continue
        rel = ctx.rel(sh)
        text = ctx.read_text(sh)
        if not re.search(r"set\s+-[a-z]*e[a-z]*u[a-z]*o\s+pipefail"
                         r"|set\s+-euo\s+pipefail"
                         r"|set\s+-uo\s+pipefail"
                         r"|set\s+-eu\s+pipefail", text):
            has_e = bool(re.search(r"set\s+.*-[a-z]*e", text))
            has_u = bool(re.search(r"set\s+.*-[a-z]*u", text))
            has_pipefail = bool(re.search(r"set\s+-o\s+pipefail", text))
            if not (has_e and has_u and has_pipefail):
                result.findings.append(Finding("SH2", rel, WARN,
                                               "Missing 'set -euo pipefail' (or equivalent)"))
    return result


def check_sh3_bash_syntax(root: pathlib.Path | AuditContext) -> CheckResult:
    """SH3 — Hook shell scripts: bash -n syntax check passes."""
    ctx = ensure_context(root)
    result = CheckResult("SH3", "Hook scripts: bash syntax check")
    if not has_command("bash"):
        result.findings.append(Finding("SH3", "", INFO,
                                       "bash not found in PATH — syntax check skipped"))
        return result
    for sh in ctx.shell_scripts:
        rel = ctx.rel(sh)
        proc = subprocess.run(
            ["bash", "-n", str(sh)],
            capture_output=True, text=True
        )
        if proc.returncode != 0:
            result.findings.append(Finding("SH3", rel, HIGH,
                                           f"Syntax error: {proc.stderr.strip()}"))
    return result


def check_ps1_basic_sanity(root: pathlib.Path | AuditContext) -> CheckResult:
    """PS1 — PowerShell hook scripts: basic sanity checks."""
    ctx = ensure_context(root)
    result = CheckResult("PS1", "PowerShell hook scripts: basic sanity")
    found = False
    resolver = ctx.root / "scripts/tests/resolve-powershell.sh"
    pwsh_path = None
    if resolver.is_file() and has_command("bash"):
        try:
            proc = subprocess.run(
                ["bash", str(resolver)],
                capture_output=True,
                text=True,
                cwd=ctx.root,
                check=False,
            )
        except OSError:
            proc = None
        if proc and proc.returncode == 0:
            candidate = (proc.stdout or "").strip()
            if candidate:
                pwsh_path = candidate
    if not pwsh_path:
        for candidate in ("pwsh", "powershell"):
            if has_command(candidate):
                pwsh_path = candidate
                break
    for ps1 in ctx.ps_scripts:
        found = True
        rel = ctx.rel(ps1)
        text = ctx.read_text(ps1)
        if not text.strip():
            result.findings.append(Finding("PS1", rel, HIGH,
                                           "Script is empty"))
            continue
        if "Set-StrictMode" not in text:
            result.findings.append(Finding("PS1", rel, INFO,
                                           "Set-StrictMode not enabled — consider adding for safer hooks"))
        if pwsh_path:
            ps_path = str(ps1).replace("'", "''")
            cmd = (
                "$errors = $null; "
                f"[System.Management.Automation.Language.Parser]::ParseFile('{ps_path}',"
                "[ref]$null,[ref]$errors) > $null; "
                "if ($errors -and $errors.Count -gt 0) { $errors | Out-String; exit 1 }"
            )
            proc = subprocess.run(
                [pwsh_path, "-NoLogo", "-NoProfile", "-Command", cmd],
                capture_output=True, text=True,
            )
            if proc.returncode != 0:
                msg = (proc.stderr or proc.stdout).strip()
                if not msg:
                    msg = "PowerShell syntax error (see PowerShell output)"
                result.findings.append(Finding("PS1", rel, HIGH, msg))
    if not found:
        result.findings.append(Finding("PS1", ".github/hooks/scripts/", INFO,
                                       "No PowerShell hook scripts found"))
    return result
