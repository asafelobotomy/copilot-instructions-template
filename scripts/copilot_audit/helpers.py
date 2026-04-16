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


def strip_json_comments(text: str) -> str:
    """Remove JSONC-style comments while preserving string contents."""
    chars: list[str] = []
    index = 0
    in_string = False
    escaped = False
    length = len(text)

    while index < length:
        char = text[index]

        if in_string:
            chars.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            index += 1
            continue

        if char == '"':
            in_string = True
            chars.append(char)
            index += 1
            continue

        if char == "/" and index + 1 < length:
            nxt = text[index + 1]
            if nxt == "/":
                index += 2
                while index < length and text[index] != "\n":
                    index += 1
                continue
            if nxt == "*":
                index += 2
                while index + 1 < length and not (text[index] == "*" and text[index + 1] == "/"):
                    index += 1
                index = index + 2 if index + 1 < length else length
                continue

        chars.append(char)
        index += 1

    return "".join(chars)


def strip_json_trailing_commas(text: str) -> str:
    """Remove trailing commas outside strings so JSONC payloads remain parseable."""
    chars: list[str] = []
    index = 0
    in_string = False
    escaped = False
    length = len(text)

    while index < length:
        char = text[index]

        if in_string:
            chars.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            index += 1
            continue

        if char == '"':
            in_string = True
            chars.append(char)
            index += 1
            continue

        if char == ",":
            probe = index + 1
            while probe < length and text[probe] in " \t\r\n":
                probe += 1
            if probe < length and text[probe] in "]}":
                index += 1
                continue

        chars.append(char)
        index += 1

    return "".join(chars)


def relax_jsonc(text: str) -> str:
    """Convert JSONC-like text into strict JSON for parsing."""
    return strip_json_trailing_commas(strip_json_comments(text))


# ── Path discovery ────────────────────────────────────────────────────────────

def instruction_dirs(root: pathlib.Path) -> list[pathlib.Path]:
    """Return all directories that may contain .instructions.md files."""
    dirs: list[pathlib.Path] = [
        root / ".github" / "instructions",
        root / "template" / "instructions",
    ]
    for kit in starter_kit_dirs(root):
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
    for kit in starter_kit_dirs(root):
        kit_prompts = kit / "prompts"
        if kit_prompts.is_dir():
            dirs.append(kit_prompts)
    return dirs


def skill_dirs(root: pathlib.Path) -> list[pathlib.Path]:
    """Return all directories that may contain SKILL.md files."""
    dirs: list[pathlib.Path] = [
        root / "skills",
    ]
    for kit in starter_kit_dirs(root):
        kit_skills = kit / "skills"
        if kit_skills.is_dir():
            dirs.append(kit_skills)
    return dirs


def starter_kit_roots(root: pathlib.Path) -> tuple[pathlib.Path, ...]:
    """Return source and installed starter-kit roots when present."""
    candidates = (
        root / "starter-kits",
        root / ".github" / "starter-kits",
    )
    return tuple(path for path in candidates if path.is_dir())


def starter_kit_dirs(root: pathlib.Path) -> list[pathlib.Path]:
    """Return all starter-kit directories from source and installed roots."""
    dirs: list[pathlib.Path] = []
    for starter_root in starter_kit_roots(root):
        for kit in starter_root.iterdir():
            if kit.is_dir():
                dirs.append(kit)
    return dirs


def iter_shell_scripts(root: pathlib.Path) -> Iterator[pathlib.Path]:
    """Yield all .sh files under hooks/scripts/."""
    for d in [
        root / "hooks" / "scripts",
    ]:
        if d.is_dir():
            yield from sorted(d.glob("*.sh"))


def iter_ps_scripts(root: pathlib.Path) -> Iterator[pathlib.Path]:
    """Yield all .ps1 files under hooks/scripts/."""
    for d in [
        root / "hooks" / "scripts",
    ]:
        if d.is_dir():
            yield from sorted(d.glob("*.ps1"))


def has_command(cmd: str) -> bool:
    """Check if a command is available in PATH."""
    return shutil.which(cmd) is not None
