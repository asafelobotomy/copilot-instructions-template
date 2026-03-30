"""Hook checks (H1–H2, SH1–SH3, PS1) for the Copilot Audit tool."""
from __future__ import annotations

import json
import pathlib
import re
import subprocess
from typing import Iterator

from .models import Finding, CheckResult, CRITICAL, HIGH, WARN, INFO
from .helpers import has_command, iter_shell_scripts, iter_ps_scripts


def check_h1_hooks_valid_json(root: pathlib.Path) -> CheckResult:
    """H1 — copilot-hooks.json: exists and is valid JSON."""
    result = CheckResult("H1", "Hooks config: exists and valid JSON")
    paths = [
        root / "template" / "hooks" / "copilot-hooks.json",
        root / ".github"  / "hooks" / "copilot-hooks.json",
    ]
    checked = False
    for hooks_file in paths:
        if not hooks_file.exists():
            continue
        checked = True
        rel = str(hooks_file.relative_to(root))
        try:
            json.loads(hooks_file.read_text(encoding="utf-8", errors="replace"))
        except json.JSONDecodeError as exc:
            result.findings.append(Finding("H1", rel, CRITICAL,
                                           f"Invalid JSON: {exc}"))
    if not checked:
        result.findings.append(Finding("H1", ".github/hooks/copilot-hooks.json",
                                       HIGH, "hooks config not found — hooks will not run"))
    return result


def check_h2_hooks_scripts_exist(root: pathlib.Path) -> CheckResult:
    """H2 — Every script path referenced in copilot-hooks.json exists on disk."""
    result = CheckResult("H2", "Hooks config: all referenced scripts exist")
    for hooks_file in [
        root / "template" / "hooks" / "copilot-hooks.json",
        root / ".github"  / "hooks" / "copilot-hooks.json",
    ]:
        if not hooks_file.exists():
            continue
        rel = str(hooks_file.relative_to(root))
        try:
            data = json.loads(hooks_file.read_text(encoding="utf-8", errors="replace"))
        except json.JSONDecodeError:
            continue  # H1 already flagged this
        raw = json.dumps(data)
        for script_path in re.findall(r'"([^"]+\.sh)"', raw):
            candidate = root / script_path.lstrip("/")
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
            candidate = root / rel_path
            if not candidate.exists():
                result.findings.append(Finding(
                    "H2", rel, WARN,
                    f"Referenced script not found: {ps_path}",
                ))
    return result


def check_sh1_shebang(root: pathlib.Path) -> CheckResult:
    """SH1 — Hook shell scripts: shebang present."""
    result = CheckResult("SH1", "Hook scripts: shebang present")
    found = False
    for sh in iter_shell_scripts(root):
        found = True
        rel = str(sh.relative_to(root))
        first_line = sh.read_text(encoding="utf-8", errors="replace").split("\n")[0]
        if not first_line.startswith("#!/"):
            result.findings.append(Finding("SH1", rel, HIGH,
                                           "Missing shebang line"))
    if not found:
        result.findings.append(Finding("SH1", ".github/hooks/scripts/", INFO,
                                       "No shell hook scripts found"))
    return result


def check_sh2_pipefail(root: pathlib.Path) -> CheckResult:
    """SH2 — Hook shell scripts: set -euo pipefail present.

    lib-hooks.sh is a sourced library and is intentionally excluded.
    """
    result = CheckResult("SH2", "Hook scripts: set -euo pipefail")
    for sh in iter_shell_scripts(root):
        if sh.name == "lib-hooks.sh":
            continue
        rel = str(sh.relative_to(root))
        text = sh.read_text(encoding="utf-8", errors="replace")
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


def check_sh3_bash_syntax(root: pathlib.Path) -> CheckResult:
    """SH3 — Hook shell scripts: bash -n syntax check passes."""
    result = CheckResult("SH3", "Hook scripts: bash syntax check")
    if not has_command("bash"):
        result.findings.append(Finding("SH3", "", INFO,
                                       "bash not found in PATH — syntax check skipped"))
        return result
    for sh in iter_shell_scripts(root):
        rel = str(sh.relative_to(root))
        proc = subprocess.run(
            ["bash", "-n", str(sh)],
            capture_output=True, text=True
        )
        if proc.returncode != 0:
            result.findings.append(Finding("SH3", rel, HIGH,
                                           f"Syntax error: {proc.stderr.strip()}"))
    return result


def check_ps1_basic_sanity(root: pathlib.Path) -> CheckResult:
    """PS1 — PowerShell hook scripts: basic sanity checks."""
    result = CheckResult("PS1", "PowerShell hook scripts: basic sanity")
    found = False
    has_pwsh = has_command("pwsh")
    for ps1 in iter_ps_scripts(root):
        found = True
        rel = str(ps1.relative_to(root))
        text = ps1.read_text(encoding="utf-8", errors="replace")
        if not text.strip():
            result.findings.append(Finding("PS1", rel, HIGH,
                                           "Script is empty"))
            continue
        if "Set-StrictMode" not in text:
            result.findings.append(Finding("PS1", rel, INFO,
                                           "Set-StrictMode not enabled — consider adding for safer hooks"))
        if has_pwsh:
            ps_path = str(ps1).replace("'", "''")
            cmd = (
                "$errors = $null; "
                f"[System.Management.Automation.Language.Parser]::ParseFile('{ps_path}',"
                "[ref]$null,[ref]$errors) > $null; "
                "if ($errors -and $errors.Count -gt 0) { $errors | Out-String; exit 1 }"
            )
            proc = subprocess.run(
                ["pwsh", "-NoLogo", "-NoProfile", "-Command", cmd],
                capture_output=True, text=True,
            )
            if proc.returncode != 0:
                msg = (proc.stderr or proc.stdout).strip()
                if not msg:
                    msg = "PowerShell syntax error (see pwsh output)"
                result.findings.append(Finding("PS1", rel, HIGH, msg))
    if not found:
        result.findings.append(Finding("PS1", ".github/hooks/scripts/", INFO,
                                       "No PowerShell hook scripts found"))
    return result
