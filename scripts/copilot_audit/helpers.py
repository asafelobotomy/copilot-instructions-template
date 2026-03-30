"""Shared helpers for the Copilot Audit tool."""
from __future__ import annotations

import pathlib
import re
import shutil
from typing import Iterator


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


# ── Placeholder regex helpers ─────────────────────────────────────────────────

# Matches real template placeholders: {{UPPERCASE_IDENT}} (no spaces, uppercase-led).
PLACEHOLDER_RE = re.compile(r"\{\{[A-Z][A-Z0-9_]+\}\}")

# Strips backtick inline-code spans and triple-backtick fences before scanning.
_BACKTICK_CODE_RE = re.compile(r"```.*?```|`[^`\n]+`", re.DOTALL)


def strip_code_spans(text: str) -> str:
    """Remove inline code spans and fenced code blocks from text."""
    return _BACKTICK_CODE_RE.sub("", text)


# ── Path discovery ────────────────────────────────────────────────────────────

def instruction_dirs(root: pathlib.Path) -> list[pathlib.Path]:
    """Return all directories that may contain .instructions.md files."""
    dirs: list[pathlib.Path] = [
        root / ".github" / "instructions",
        root / "template" / "instructions",
    ]
    starter_root = root / "starter-kits"
    if starter_root.is_dir():
        for kit in starter_root.iterdir():
            if kit.is_dir():
                kit_instructions = kit / "instructions"
                if kit_instructions.is_dir():
                    dirs.append(kit_instructions)
    return dirs


def prompt_dirs(root: pathlib.Path) -> list[pathlib.Path]:
    """Return all directories that may contain prompt files."""
    dirs: list[pathlib.Path] = [
        root / ".github" / "prompts",
        root / "template" / "prompts",
    ]
    starter_root = root / "starter-kits"
    if starter_root.is_dir():
        for kit in starter_root.iterdir():
            if kit.is_dir():
                kit_prompts = kit / "prompts"
                if kit_prompts.is_dir():
                    dirs.append(kit_prompts)
    return dirs


def skill_dirs(root: pathlib.Path) -> list[pathlib.Path]:
    """Return all directories that may contain SKILL.md files."""
    dirs: list[pathlib.Path] = [
        root / ".github" / "skills",
        root / "template" / "skills",
    ]
    starter_root = root / "starter-kits"
    if starter_root.is_dir():
        for kit in starter_root.iterdir():
            if kit.is_dir():
                kit_skills = kit / "skills"
                if kit_skills.is_dir():
                    dirs.append(kit_skills)
    return dirs


def iter_shell_scripts(root: pathlib.Path) -> Iterator[pathlib.Path]:
    """Yield all .sh files under .github/hooks/scripts/ and template/hooks/scripts/."""
    for d in [
        root / "template" / "hooks" / "scripts",
        root / ".github"  / "hooks" / "scripts",
    ]:
        if d.is_dir():
            yield from sorted(d.glob("*.sh"))


def iter_ps_scripts(root: pathlib.Path) -> Iterator[pathlib.Path]:
    """Yield all .ps1 files under .github/hooks/scripts/ and template/hooks/scripts/."""
    for d in [
        root / "template" / "hooks" / "scripts",
        root / ".github" / "hooks" / "scripts",
    ]:
        if d.is_dir():
            yield from sorted(d.glob("*.ps1"))


def has_command(cmd: str) -> bool:
    """Check if a command is available in PATH."""
    return shutil.which(cmd) is not None
