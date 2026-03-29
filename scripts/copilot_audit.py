#!/usr/bin/env python3
# purpose:  Static-analysis audit of every file GitHub Copilot reads, touches, or
#           is influenced by in VS Code. Produces a structured report.
# when:     CI validation; Doctor agent D14 check; manual developer audits.
#           NOT for: runtime debugging, API connectivity checks, or git operations.
# inputs:   --root PATH (default: repo root via script location)
#           --output md|json (default: md)
# outputs:  Markdown or JSON report on stdout; structured findings array.
# risk:     safe (read-only)
# source:   original
"""
Copilot Audit — static-analysis for all files VS Code Copilot reads.

Exit 0: no CRITICAL or HIGH findings.
Exit 1: at least one CRITICAL or HIGH finding.
"""
from __future__ import annotations

import argparse
import json
import os
import pathlib
import re
import subprocess
import sys
from dataclasses import dataclass, field
from typing import Iterator

# ── Severity constants ────────────────────────────────────────────────────────

CRITICAL = "CRITICAL"
HIGH     = "HIGH"
WARN     = "WARN"
INFO     = "INFO"
OK       = "OK"

SEVERITY_ORDER = {CRITICAL: 0, HIGH: 1, WARN: 2, INFO: 3, OK: 4}


# ── Data model ────────────────────────────────────────────────────────────────

@dataclass
class Finding:
    check_id:  str
    file:      str
    severity:  str
    message:   str


@dataclass
class CheckResult:
    check_id:   str
    label:      str
    findings:   list[Finding] = field(default_factory=list)

    def ok(self) -> bool:
        return not any(f.severity in (CRITICAL, HIGH, WARN) for f in self.findings)

    def worst(self) -> str:
        if not self.findings:
            return OK
        return min((f.severity for f in self.findings), key=lambda s: SEVERITY_ORDER[s])


# ── YAML frontmatter helper ───────────────────────────────────────────────────

def parse_frontmatter(text: str) -> dict[str, object]:
    """Return a flat dict of scalar frontmatter values from a Markdown file.

    Only parses simple key: value and key:\n  - item list patterns.
    Complex nested YAML is not supported — not needed for audit purposes.
    """
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    block = text[3:end].strip()
    result: dict[str, object] = {}
    current_key: str | None = None
    for line in block.splitlines():
        # List item
        if line.startswith("  - ") or line.startswith("- "):
            if current_key:
                lst = result.setdefault(current_key, [])
                if isinstance(lst, list):
                    lst.append(line.strip().lstrip("- ").strip())
            continue
        if ":" in line:
            key, _, val = line.partition(":")
            key = key.strip()
            val = val.strip().strip('"').strip("'")
            result[key] = val if val else []
            current_key = key
    return result


# ── Token estimator (stdlib only — no tiktoken dep) ──────────────────────────

def estimate_tokens(text: str) -> int:
    """Estimate token count using word-count × 1.3 (±15% proxy for cl100k_base)."""
    return int(len(text.split()) * 1.3)


# ── Checks ────────────────────────────────────────────────────────────────────

def check_a1_agent_frontmatter(root: pathlib.Path) -> CheckResult:
    """A1 — Agent files: frontmatter present; name, description, model fields set."""
    result = CheckResult("A1", "Agent frontmatter completeness")
    agents_dir = root / ".github" / "agents"
    if not agents_dir.is_dir():
        result.findings.append(Finding("A1", ".github/agents/", INFO,
                                       "No agents directory — skip"))
        return result
    for agent_file in sorted(agents_dir.glob("*.agent.md")):
        rel = str(agent_file.relative_to(root))
        text = agent_file.read_text(encoding="utf-8", errors="replace")
        if not text.startswith("---"):
            result.findings.append(Finding("A1", rel, HIGH,
                                           "No YAML frontmatter block found"))
            continue
        fm = parse_frontmatter(text)
        for required in ("name", "description"):
            if not fm.get(required):
                result.findings.append(Finding("A1", rel, HIGH,
                                               f"Missing required field: {required}"))
        if not fm.get("model"):
            result.findings.append(Finding("A1", rel, WARN,
                                           "Missing 'model' field — will use picker default"))
    return result


def check_a2_agent_handoffs(root: pathlib.Path) -> CheckResult:
    """A2 — Agent handoffs: every handoff agent target resolves to a known agent name."""
    result = CheckResult("A2", "Agent handoff targets")
    agents_dir = root / ".github" / "agents"
    if not agents_dir.is_dir():
        return result

    # Build known-name set
    known_names: set[str] = set()
    for agent_file in agents_dir.glob("*.agent.md"):
        fm = parse_frontmatter(agent_file.read_text(encoding="utf-8", errors="replace"))
        name = fm.get("name", "")
        if isinstance(name, str) and name:
            known_names.add(name)

    # Check handoff targets — scan for "agent: <Name>" lines inside handoffs blocks
    for agent_file in sorted(agents_dir.glob("*.agent.md")):
        rel = str(agent_file.relative_to(root))
        text = agent_file.read_text(encoding="utf-8", errors="replace")
        for m in re.finditer(r"^\s+agent:\s+(.+)$", text, re.MULTILINE):
            target = m.group(1).strip().strip('"').strip("'")
            if target and target not in known_names:
                result.findings.append(Finding("A2", rel, CRITICAL,
                                               f"Handoff targets unknown agent: '{target}'"))
    return result


# Matches real template placeholders: {{UPPERCASE_IDENT}} (no spaces, uppercase-led).
# Excludes prose mentions like '{{}}', '{{ github.event }}', or backtick code spans.
_PLACEHOLDER_RE = re.compile(r"\{\{[A-Z][A-Z0-9_]+\}\}")
# Strips backtick inline-code spans and triple-backtick fences before placeholder scanning.
_BACKTICK_CODE_RE = re.compile(r"```.*?```|`[^`\n]+`", re.DOTALL)


def _strip_code_spans(text: str) -> str:
    """Remove inline code spans and fenced code blocks from text."""
    return _BACKTICK_CODE_RE.sub("", text)


def check_a3_agent_no_placeholders(root: pathlib.Path) -> CheckResult:
    """A3 — Agent files must not contain {{PLACEHOLDER}} template tokens."""
    result = CheckResult("A3", "Agent files: no placeholder tokens")
    agents_dir = root / ".github" / "agents"
    if not agents_dir.is_dir():
        return result
    for agent_file in sorted(agents_dir.glob("*.agent.md")):
        rel = str(agent_file.relative_to(root))
        text = _strip_code_spans(
            agent_file.read_text(encoding="utf-8", errors="replace")
        )
        matches = _PLACEHOLDER_RE.findall(text)
        if matches:
            result.findings.append(Finding("A3", rel, HIGH,
                                           f"Contains {len(matches)} placeholder token(s): "
                                           + ", ".join(matches[:3])))
    return result


def check_i1_instructions_placeholders(root: pathlib.Path) -> CheckResult:
    """I1 — copilot-instructions.md placeholder separation."""
    result = CheckResult("I1", "Instructions placeholder separation")
    dev_file      = root / ".github" / "copilot-instructions.md"
    consumer_file = root / "template" / "copilot-instructions.md"

    for path, must_be_zero in ((dev_file, True), (consumer_file, False)):
        if not path.exists():
            result.findings.append(Finding("I1", str(path.relative_to(root)),
                                           INFO, "File not found — skip"))
            continue
        rel = str(path.relative_to(root))
        count = len(_PLACEHOLDER_RE.findall(
            _strip_code_spans(path.read_text(encoding="utf-8", errors="replace"))
        ))
        if must_be_zero and count > 0:
            result.findings.append(Finding("I1", rel, CRITICAL,
                                           f"Developer file has {count} placeholder token(s) "
                                           "(must be zero — file may be unresolved)"))
        elif not must_be_zero and count < 3:
            result.findings.append(Finding("I1", rel, HIGH,
                                           f"Consumer template has only {count} placeholder "
                                           "token(s) (expected ≥ 3 — may have been resolved)"))
    return result


def check_i2_instructions_length(root: pathlib.Path) -> CheckResult:
    """I2 — consumer template line count ≤ 800; token budget awareness."""
    result = CheckResult("I2", "Instructions length / token budget")
    consumer_file = root / "template" / "copilot-instructions.md"
    if not consumer_file.exists():
        return result
    text  = consumer_file.read_text(encoding="utf-8", errors="replace")
    lines = text.count("\n")
    tokens = estimate_tokens(text)
    rel = str(consumer_file.relative_to(root))
    if lines > 800:
        result.findings.append(Finding("I2", rel, CRITICAL,
                                       f"File is {lines} lines (limit: 800)"))
    elif lines > 720:
        result.findings.append(Finding("I2", rel, WARN,
                                       f"File is {lines} lines (within 80 of 800-line limit)"))
    if tokens > 8000:
        result.findings.append(Finding("I2", rel, WARN,
                                       f"Estimated token count {tokens} is high "
                                       "(target ≤ 8000 for attention budget)"))
    return result


def check_i3_instruction_stubs(root: pathlib.Path) -> CheckResult:
    """I3 — .instructions.md files: frontmatter present; applyTo non-empty."""
    result = CheckResult("I3", "Instruction stub frontmatter")
    dirs = [
        root / ".github" / "instructions",
        root / "template" / "instructions",
    ]
    found = False
    for d in dirs:
        for ifile in sorted(d.glob("*.instructions.md")) if d.is_dir() else []:
            found = True
            rel = str(ifile.relative_to(root))
            text = ifile.read_text(encoding="utf-8", errors="replace")
            if not text.startswith("---"):
                result.findings.append(Finding("I3", rel, HIGH,
                                               "No YAML frontmatter block"))
                continue
            fm = parse_frontmatter(text)
            if not fm.get("applyTo"):
                result.findings.append(Finding("I3", rel, WARN,
                                               "Missing or empty 'applyTo' field — "
                                               "instructions will not auto-attach to files"))
    if not found:
        result.findings.append(Finding("I3", ".github/instructions/", INFO,
                                       "No .instructions.md files found"))
    return result


def check_p1_prompt_mode(root: pathlib.Path) -> CheckResult:
    """P1 — .prompt.md files: known mode value if present."""
    result = CheckResult("P1", "Prompt file frontmatter")
    valid_modes = {"ask", "edit", "agent", "generate"}
    dirs = [
        root / ".github" / "prompts",
        root / "template" / "prompts",
    ]
    found = False
    for d in dirs:
        for pfile in sorted(d.glob("*.prompt.md")) if d.is_dir() else []:
            found = True
            rel = str(pfile.relative_to(root))
            text = pfile.read_text(encoding="utf-8", errors="replace")
            if not text.startswith("---"):
                result.findings.append(Finding("P1", rel, WARN,
                                               "No YAML frontmatter block"))
                continue
            fm = parse_frontmatter(text)
            mode = fm.get("mode", "")
            if isinstance(mode, str) and mode and mode not in valid_modes:
                result.findings.append(Finding("P1", rel, HIGH,
                                               f"Unknown mode: '{mode}' "
                                               f"(valid: {', '.join(sorted(valid_modes))})"))
    if not found:
        result.findings.append(Finding("P1", ".github/prompts/", INFO,
                                       "No .prompt.md files found"))
    return result


def check_s1_skill_name_matches_dir(root: pathlib.Path) -> CheckResult:
    """S1 — SKILL.md: name in frontmatter must match parent directory name."""
    result = CheckResult("S1", "Skill name matches directory")
    dirs = [
        root / ".github" / "skills",
        root / "template" / "skills",
    ]
    found = False
    for d in dirs:
        if not d.is_dir():
            continue
        for skill_file in sorted(d.rglob("SKILL.md")):
            found = True
            rel = str(skill_file.relative_to(root))
            dir_name = skill_file.parent.name
            text = skill_file.read_text(encoding="utf-8", errors="replace")
            fm = parse_frontmatter(text)
            name = fm.get("name", "")
            if not isinstance(name, str) or not name:
                result.findings.append(Finding("S1", rel, HIGH,
                                               "Missing 'name' field in frontmatter"))
            elif name != dir_name:
                result.findings.append(Finding("S1", rel, HIGH,
                                               f"name '{name}' does not match "
                                               f"directory '{dir_name}' (agentskills spec)"))
    if not found:
        result.findings.append(Finding("S1", ".github/skills/", INFO,
                                       "No SKILL.md files found"))
    return result


def check_s2_skill_size(root: pathlib.Path) -> CheckResult:
    """S2 — SKILL.md: body ≤ 500 lines; description ≤ 1024 chars."""
    result = CheckResult("S2", "Skill size constraints")
    dirs = [
        root / ".github" / "skills",
        root / "template" / "skills",
    ]
    for d in dirs:
        if not d.is_dir():
            continue
        for skill_file in sorted(d.rglob("SKILL.md")):
            rel = str(skill_file.relative_to(root))
            text = skill_file.read_text(encoding="utf-8", errors="replace")
            lines = text.count("\n")
            if lines > 500:
                result.findings.append(Finding("S2", rel, WARN,
                                               f"File is {lines} lines (recommended ≤ 500)"))
            fm = parse_frontmatter(text)
            desc = fm.get("description", "")
            if isinstance(desc, str) and len(desc) > 1024:
                result.findings.append(Finding("S2", rel, HIGH,
                                               f"description is {len(desc)} chars "
                                               "(agentskills limit: 1024)"))
    return result


def check_m1_mcp_valid_json(root: pathlib.Path) -> CheckResult:
    """M1 — .vscode/mcp.json: file is valid JSON with a servers key."""
    result = CheckResult("M1", "MCP config: valid JSON + servers key")
    mcp_file = root / ".vscode" / "mcp.json"
    if not mcp_file.exists():
        result.findings.append(Finding("M1", ".vscode/mcp.json", INFO,
                                       "File not found — MCP not configured"))
        return result
    rel = str(mcp_file.relative_to(root))
    try:
        data = json.loads(mcp_file.read_text(encoding="utf-8", errors="replace"))
    except json.JSONDecodeError as exc:
        result.findings.append(Finding("M1", rel, CRITICAL,
                                       f"Invalid JSON: {exc}"))
        return result
    if "servers" not in data:
        result.findings.append(Finding("M1", rel, HIGH,
                                       "Missing top-level 'servers' key"))
    return result


def check_m2_mcp_no_npm_antipatterns(root: pathlib.Path) -> CheckResult:
    """M2 — mcp.json: npx+mcp-server-git/fetch anti-pattern; deprecated references."""
    result = CheckResult("M2", "MCP config: no npm anti-patterns")
    mcp_file = root / ".vscode" / "mcp.json"
    if not mcp_file.exists():
        return result
    rel = str(mcp_file.relative_to(root))
    try:
        data = json.loads(mcp_file.read_text(encoding="utf-8", errors="replace"))
    except json.JSONDecodeError:
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
        # npx + mcp-server-git or mcp-server-fetch → these npm packages do not exist
        if command == "npx" and re.search(r"mcp-server-(git|fetch)", args_str):
            result.findings.append(Finding("M2", rel, CRITICAL,
                                           f"Server '{srv_name}': uses npx with "
                                           f"mcp-server-git/fetch (npm packages do not exist; "
                                           "use 'uvx' instead)"))
        # Direct package reference style (@modelcontextprotocol/server-*)
        if re.search(r"@modelcontextprotocol/server-(git|fetch)", args_str):
            result.findings.append(Finding("M2", rel, HIGH,
                                           f"Server '{srv_name}': references "
                                           "@modelcontextprotocol/server-git or "
                                           "server-fetch (packages do not exist on npm)"))
    return result


def check_m3_mcp_no_secrets(root: pathlib.Path) -> CheckResult:
    """M3 — mcp.json: no literal secrets in env values."""
    result = CheckResult("M3", "MCP config: no literal secrets")
    mcp_file = root / ".vscode" / "mcp.json"
    if not mcp_file.exists():
        return result
    rel = str(mcp_file.relative_to(root))
    try:
        data = json.loads(mcp_file.read_text(encoding="utf-8", errors="replace"))
    except json.JSONDecodeError:
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


def check_h1_hooks_valid_json(root: pathlib.Path) -> CheckResult:
    """H1 — copilot-hooks.json exists and is valid JSON."""
    result = CheckResult("H1", "Hooks config: exists and valid JSON")
    # Check both template and .github copies
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
        # Collect all string values that look like shell script paths
        raw = json.dumps(data)
        for script_path in re.findall(r'"([^"]+\.sh)"', raw):
            # Paths may be absolute (from repo root) or relative to hooks dir
            candidate = root / script_path.lstrip("/")
            if not candidate.exists():
                result.findings.append(Finding("H2", rel, HIGH,
                                               f"Referenced script not found: {script_path}"))
    return result


def _iter_shell_scripts(root: pathlib.Path) -> Iterator[pathlib.Path]:
    """Yield all .sh files under .github/hooks/scripts/ and template/hooks/scripts/."""
    for d in [
        root / "template" / "hooks" / "scripts",
        root / ".github"  / "hooks" / "scripts",
    ]:
        if d.is_dir():
            yield from sorted(d.glob("*.sh"))


def check_sh1_shebang(root: pathlib.Path) -> CheckResult:
    """SH1 — Hook shell scripts: shebang present."""
    result = CheckResult("SH1", "Hook scripts: shebang present")
    found = False
    for sh in _iter_shell_scripts(root):
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
    for sh in _iter_shell_scripts(root):
        if sh.name == "lib-hooks.sh":
            continue  # sourced library — calling script owns the set flags
        rel = str(sh.relative_to(root))
        text = sh.read_text(encoding="utf-8", errors="replace")
        if not re.search(r"set\s+-[a-z]*e[a-z]*u[a-z]*o\s+pipefail"
                         r"|set\s+-euo\s+pipefail"
                         r"|set\s+-uo\s+pipefail"
                         r"|set\s+-eu\s+pipefail", text):
            # Also accept separate set lines
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
    if not _shutil_which("bash"):
        result.findings.append(Finding("SH3", "", INFO,
                                       "bash not found in PATH — syntax check skipped"))
        return result
    for sh in _iter_shell_scripts(root):
        rel = str(sh.relative_to(root))
        proc = subprocess.run(
            ["bash", "-n", str(sh)],
            capture_output=True, text=True
        )
        if proc.returncode != 0:
            result.findings.append(Finding("SH3", rel, HIGH,
                                           f"Syntax error: {proc.stderr.strip()}"))
    return result


def check_vs1_settings_plugins(root: pathlib.Path) -> CheckResult:
    """VS1 — .vscode/settings.json: valid JSON; chat.plugins.paths entries resolve."""
    result = CheckResult("VS1", "VS Code settings: JSON valid + plugin paths resolve")
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
    plugin_paths = data.get("chat.plugins.paths", [])
    if isinstance(plugin_paths, list):
        for p in plugin_paths:
            if isinstance(p, str):
                resolved = pathlib.Path(p) if pathlib.Path(p).is_absolute() else root / p
                if not resolved.exists():
                    result.findings.append(Finding("VS1", rel, WARN,
                                                   f"chat.plugins.paths entry not found: {p}"))
    return result


# ── Utility ───────────────────────────────────────────────────────────────────

def _shutil_which(cmd: str) -> bool:
    import shutil
    return shutil.which(cmd) is not None


# ── Runner ────────────────────────────────────────────────────────────────────

ALL_CHECKS = [
    check_a1_agent_frontmatter,
    check_a2_agent_handoffs,
    check_a3_agent_no_placeholders,
    check_i1_instructions_placeholders,
    check_i2_instructions_length,
    check_i3_instruction_stubs,
    check_p1_prompt_mode,
    check_s1_skill_name_matches_dir,
    check_s2_skill_size,
    check_m1_mcp_valid_json,
    check_m2_mcp_no_npm_antipatterns,
    check_m3_mcp_no_secrets,
    check_h1_hooks_valid_json,
    check_h2_hooks_scripts_exist,
    check_sh1_shebang,
    check_sh2_pipefail,
    check_sh3_bash_syntax,
    check_vs1_settings_plugins,
]


def run_audit(root: pathlib.Path) -> list[CheckResult]:
    results = []
    for check_fn in ALL_CHECKS:
        results.append(check_fn(root))
    return results


# ── Output formatters ─────────────────────────────────────────────────────────

def _summary_counts(results: list[CheckResult]) -> dict[str, int]:
    counts: dict[str, int] = {CRITICAL: 0, HIGH: 0, WARN: 0, INFO: 0, OK: 0}
    for r in results:
        if not r.findings:
            counts[OK] += 1
        else:
            worst = r.worst()
            counts[worst] = counts.get(worst, 0) + 1
    return counts


def _overall_status(counts: dict[str, int]) -> str:
    if counts[CRITICAL] > 0 or counts[HIGH] > 0:
        return "CRITICAL"
    if counts[WARN] > 0:
        return "DEGRADED"
    return "HEALTHY"


def format_markdown(results: list[CheckResult]) -> str:
    lines = ["# Copilot Audit Report", ""]
    counts = _summary_counts(results)
    status = _overall_status(counts)
    lines += [
        f"**Status**: {status}",
        "",
        f"| Severity | Count |",
        f"|----------|-------|",
        f"| CRITICAL | {counts[CRITICAL]} |",
        f"| HIGH     | {counts[HIGH]} |",
        f"| WARN     | {counts[WARN]} |",
        f"| INFO     | {counts[INFO]} |",
        f"| OK       | {counts[OK]} |",
        "",
        "---",
        "",
        "## Findings",
        "",
    ]
    has_findings = False
    for r in results:
        non_ok = [f for f in r.findings if f.severity != OK]
        if non_ok:
            has_findings = True
            lines.append(f"### {r.check_id} — {r.label}")
            for f in non_ok:
                badge = f"**[{f.severity}]**"
                lines.append(f"- {badge} `{f.file}`: {f.message}")
            lines.append("")
    if not has_findings:
        lines.append("No findings. All checks passed.")
        lines.append("")
    return "\n".join(lines)


def format_json(results: list[CheckResult]) -> str:
    counts = _summary_counts(results)
    payload = {
        "status": _overall_status(counts),
        "summary": counts,
        "checks": [
            {
                "id":     r.check_id,
                "label":  r.label,
                "status": r.worst(),
                "findings": [
                    {
                        "check_id": f.check_id,
                        "file":     f.file,
                        "severity": f.severity,
                        "message":  f.message,
                    }
                    for f in r.findings
                ],
            }
            for r in results
        ],
    }
    return json.dumps(payload, indent=2)


# ── CLI entry point ───────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Copilot Audit — static-analysis for all files VS Code Copilot reads."
    )
    parser.add_argument(
        "--root",
        default=str(pathlib.Path(__file__).parent.parent),
        help="Repository root (default: parent of scripts/)",
    )
    parser.add_argument(
        "--output",
        choices=["md", "json"],
        default="md",
        help="Output format: md (default) or json",
    )
    args = parser.parse_args()

    root = pathlib.Path(args.root).resolve()
    if not root.is_dir():
        print(f"Error: --root '{root}' is not a directory", file=sys.stderr)
        return 2

    results = run_audit(root)

    if args.output == "json":
        print(format_json(results))
    else:
        print(format_markdown(results))

    counts = _summary_counts(results)
    return 1 if (_overall_status(counts) == "CRITICAL") else 0


if __name__ == "__main__":
    sys.exit(main())
