"""Shared repository context and caches for the Copilot Audit tool."""
from __future__ import annotations

import json
import pathlib
from functools import cached_property
from json import JSONDecodeError

from .helpers import (
    instruction_dirs,
    iter_ps_scripts,
    iter_shell_scripts,
    parse_frontmatter,
    prompt_dirs,
    skill_dirs,
)


class AuditContext:
    """Repository-scoped caches for repeated file access during audit runs."""

    def __init__(self, root: pathlib.Path) -> None:
        self.root = pathlib.Path(root)
        self._text_cache: dict[pathlib.Path, str] = {}
        self._json_cache: dict[pathlib.Path, tuple[object | None, JSONDecodeError | None]] = {}
        self._frontmatter_cache: dict[pathlib.Path, dict[str, object]] = {}

    def rel(self, path: pathlib.Path) -> str:
        """Return a repository-relative path string."""
        return str(path.relative_to(self.root))

    def read_text(self, path: pathlib.Path) -> str:
        """Read and cache file text using replacement for undecodable bytes."""
        path = pathlib.Path(path)
        if path not in self._text_cache:
            self._text_cache[path] = path.read_text(encoding="utf-8", errors="replace")
        return self._text_cache[path]

    def load_json(self, path: pathlib.Path) -> tuple[object | None, JSONDecodeError | None]:
        """Parse and cache JSON, returning (data, error)."""
        path = pathlib.Path(path)
        if path not in self._json_cache:
            if not path.exists():
                self._json_cache[path] = (None, None)
            else:
                try:
                    self._json_cache[path] = (json.loads(self.read_text(path)), None)
                except JSONDecodeError as exc:
                    self._json_cache[path] = (None, exc)
        return self._json_cache[path]

    def load_frontmatter(self, path: pathlib.Path) -> dict[str, object]:
        """Parse and cache flat YAML frontmatter from Markdown files."""
        path = pathlib.Path(path)
        if path not in self._frontmatter_cache:
            self._frontmatter_cache[path] = parse_frontmatter(self.read_text(path))
        return self._frontmatter_cache[path]

    @cached_property
    def agents_dir(self) -> pathlib.Path:
        return self.root / ".github" / "agents"

    @cached_property
    def agent_files(self) -> tuple[pathlib.Path, ...]:
        if not self.agents_dir.is_dir():
            return ()
        return tuple(sorted(self.agents_dir.glob("*.agent.md")))

    @cached_property
    def instruction_files(self) -> tuple[pathlib.Path, ...]:
        files: list[pathlib.Path] = []
        for directory in instruction_dirs(self.root):
            if directory.is_dir():
                files.extend(sorted(directory.glob("*.instructions.md")))
        return tuple(files)

    @cached_property
    def prompt_files(self) -> tuple[pathlib.Path, ...]:
        files: list[pathlib.Path] = []
        for directory in prompt_dirs(self.root):
            if directory.is_dir():
                files.extend(sorted(directory.glob("*.prompt.md")))
        return tuple(files)

    @cached_property
    def skill_files(self) -> tuple[pathlib.Path, ...]:
        files: list[pathlib.Path] = []
        for directory in skill_dirs(self.root):
            if directory.is_dir():
                files.extend(sorted(directory.rglob("SKILL.md")))
        return tuple(files)

    @cached_property
    def shell_scripts(self) -> tuple[pathlib.Path, ...]:
        return tuple(iter_shell_scripts(self.root))

    @cached_property
    def ps_scripts(self) -> tuple[pathlib.Path, ...]:
        return tuple(iter_ps_scripts(self.root))

    @cached_property
    def starter_kits_root(self) -> pathlib.Path:
        return self.root / "starter-kits"

    @cached_property
    def starter_kit_dirs(self) -> tuple[pathlib.Path, ...]:
        if not self.starter_kits_root.is_dir():
            return ()
        return tuple(sorted(path for path in self.starter_kits_root.iterdir() if path.is_dir()))

    @cached_property
    def hook_config_files(self) -> tuple[pathlib.Path, pathlib.Path]:
        return (
            self.root / "template" / "hooks" / "copilot-hooks.json",
            self.root / ".github" / "hooks" / "copilot-hooks.json",
        )


def ensure_context(root_or_ctx: pathlib.Path | AuditContext) -> AuditContext:
    """Return an AuditContext whether given a root path or an existing context."""
    if isinstance(root_or_ctx, AuditContext):
        return root_or_ctx
    return AuditContext(pathlib.Path(root_or_ctx))