"""Version metadata checks (V1) for the Copilot Audit tool."""
from __future__ import annotations

import pathlib
import re

from .consumer_inventory import managed_consumer_file_paths, inventory_from_workspace_index, workspace_index_path
from .context import AuditContext, ensure_context
from .models import Finding, CheckResult, HIGH, WARN, INFO


SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
FILE_MANIFEST_HASH_RE = re.compile(r"^[0-9a-f]{8,64}$")
SETUP_ANSWER_RE = re.compile(r"^([A-Z_][A-Z0-9_]*)=(.*)$")
REQUIRED_SETUP_ANSWER_KEYS = (
    "PROJECT_NAME",
    "LANGUAGE",
    "RUNTIME",
    "PACKAGE_MANAGER",
    "TEST_COMMAND",
    "TYPE_CHECK_COMMAND",
    "THREE_CHECK_COMMAND",
    "TEST_FRAMEWORK",
    "SETUP_DATE",
)
CONDITIONAL_SETUP_ANSWER_KEYS = {
    ".vscode/mcp.json": ("MCP_STACK_SERVERS", "MCP_CUSTOM_SERVERS"),
}


def _first_content_line(text: str) -> str:
    """Return the first non-empty line that is not a standalone HTML comment."""
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("<!--") and line.endswith("-->"):
            continue
        return line
    return ""


def _comment_block_payload(text: str, marker: str) -> str:
    """Return the contents of a named HTML comment block without the markers."""
    start = text.find(marker)
    if start == -1:
        return ""
    end = text.find("-->", start)
    if end == -1:
        return ""
    block = text[start:end]
    return "\n".join(block.splitlines()[1:]).strip()


def _parse_mapping_block(
    payload: str,
    *,
    check_id: str,
    rel: str,
    result: CheckResult,
    block_name: str,
    key_pattern: re.Pattern[str],
) -> dict[str, str]:
    mapping: dict[str, str] = {}
    if not payload:
        return mapping
    for line in payload.splitlines():
        entry = line.strip()
        if not entry:
            continue
        match = key_pattern.match(entry)
        if not match:
            result.findings.append(Finding(check_id, rel, HIGH,
                                           f"{block_name} contains invalid entry: {entry}"))
            continue
        key, value = match.groups()
        if key in mapping:
            result.findings.append(Finding(check_id, rel, HIGH,
                                           f"{block_name} contains duplicate key: {key}"))
            continue
        mapping[key] = value
    return mapping


def check_v1_copilot_version_metadata(root: pathlib.Path | AuditContext) -> CheckResult:
    """V1 — consumer version metadata must be structurally complete."""
    ctx = ensure_context(root)
    result = CheckResult("V1", "Copilot version metadata completeness")
    rel = ".github/copilot-version.md"
    path = ctx.root / rel

    if ctx.repo_shape != "consumer":
        result.findings.append(Finding("V1", rel, INFO,
                                       "Developer template repo or unknown layout — skip"))
        return result

    if not path.exists():
        result.findings.append(Finding("V1", rel, HIGH,
                                       "Version file not found — consumer update provenance is unavailable"))
        return result

    text = ctx.read_text(path)
    version = _first_content_line(text)
    if not SEMVER_RE.match(version):
        result.findings.append(Finding("V1", rel, HIGH,
                                       "First content line must be a semantic version (X.Y.Z)"))

    applied_date = ""
    for label in ("Applied", "Updated"):
        match = re.search(rf"(?m)^{label}:\s*(.+?)\s*$", text)
        if not match:
            result.findings.append(Finding("V1", rel, HIGH,
                                           f"Missing '{label}:' line"))
            continue
        date_value = match.group(1).strip()
        if label == "Applied":
            applied_date = date_value
        if not DATE_RE.match(date_value):
            result.findings.append(Finding("V1", rel, HIGH,
                                           f"{label}: must use YYYY-MM-DD format"))

    section_payload = _comment_block_payload(text, "<!-- section-fingerprints")
    if not section_payload:
        result.findings.append(Finding("V1", rel, WARN,
                                       "Missing section-fingerprints block — section drift cannot be tracked"))
    elif "=" not in section_payload:
        result.findings.append(Finding("V1", rel, WARN,
                                       "section-fingerprints block is empty"))

    manifest_payload = _comment_block_payload(text, "<!-- file-manifest")
    if not manifest_payload:
        result.findings.append(Finding("V1", rel, HIGH,
                                       "Missing file-manifest block — companion provenance is incomplete"))
    elif "=" not in manifest_payload:
        result.findings.append(Finding("V1", rel, HIGH,
                                       "file-manifest block is empty"))
    else:
        manifest_entries = _parse_mapping_block(
            manifest_payload,
            check_id="V1",
            rel=rel,
            result=result,
            block_name="file-manifest",
            key_pattern=re.compile(r"^(.+?)=(.+)$"),
        )
        index_data, _ = ctx.load_json(workspace_index_path(ctx))
        inventory = inventory_from_workspace_index(
            index_data if isinstance(index_data, dict) else {},
            ctx,
        )
        expected_paths = set(managed_consumer_file_paths(ctx, inventory))

        for candidate, file_hash in manifest_entries.items():
            if not FILE_MANIFEST_HASH_RE.match(file_hash):
                result.findings.append(Finding("V1", rel, HIGH,
                                               f"file-manifest hash for '{candidate}' is not a hex digest prefix"))
            manifest_path = ctx.root / candidate
            if not manifest_path.exists():
                result.findings.append(Finding("V1", rel, HIGH,
                                               f"file-manifest lists missing file: {candidate}"))
            elif candidate not in expected_paths:
                result.findings.append(Finding("V1", rel, WARN,
                                               f"file-manifest includes unexpected managed surface: {candidate}"))

        for expected_path in sorted(expected_paths):
            if expected_path not in manifest_entries:
                result.findings.append(Finding("V1", rel, HIGH,
                                               f"file-manifest missing managed surface: {expected_path}"))

    answers_payload = _comment_block_payload(text, "<!-- setup-answers")
    if not answers_payload:
        result.findings.append(Finding("V1", rel, HIGH,
                                       "Missing setup-answers block — optional surface decisions cannot be reconstructed"))
    elif "=" not in answers_payload:
        result.findings.append(Finding("V1", rel, HIGH,
                                       "setup-answers block is empty"))
    else:
        answers = _parse_mapping_block(
            answers_payload,
            check_id="V1",
            rel=rel,
            result=result,
            block_name="setup-answers",
            key_pattern=SETUP_ANSWER_RE,
        )

        for key in REQUIRED_SETUP_ANSWER_KEYS:
            if key not in answers:
                result.findings.append(Finding("V1", rel, HIGH,
                                               f"setup-answers missing required key: {key}"))

        setup_date = answers.get("SETUP_DATE")
        if setup_date and not DATE_RE.match(setup_date):
            result.findings.append(Finding("V1", rel, HIGH,
                                           "SETUP_DATE must use YYYY-MM-DD format"))
        if setup_date and applied_date and DATE_RE.match(applied_date) and setup_date != applied_date:
            result.findings.append(Finding("V1", rel, WARN,
                                           "SETUP_DATE does not match Applied: date"))

    ownership_payload = _comment_block_payload(text, "<!-- ownership-mode")
    if ownership_payload:
        ownership = _parse_mapping_block(
            ownership_payload,
            check_id="V1",
            rel=rel,
            result=result,
            block_name="ownership-mode",
            key_pattern=SETUP_ANSWER_RE,
        )
        mode = ownership.get("OWNERSHIP_MODE", "")
        if mode and mode not in ("plugin-backed", "all-local"):
            result.findings.append(Finding("V1", rel, HIGH,
                                           f"OWNERSHIP_MODE must be 'plugin-backed' or 'all-local', got '{mode}'"))
        for surface_key in ("AGENTS", "SKILLS", "HOOKS"):
            val = ownership.get(surface_key, "")
            if val and val not in ("plugin", "local"):
                result.findings.append(Finding("V1", rel, HIGH,
                                               f"{surface_key} must be 'plugin' or 'local', got '{val}'"))

        for rel_path, required_keys in CONDITIONAL_SETUP_ANSWER_KEYS.items():
            if not (ctx.root / rel_path).exists():
                continue
            for key in required_keys:
                if key not in answers:
                    result.findings.append(Finding("V1", rel, HIGH,
                                                   f"setup-answers missing key for enabled surface {rel_path}: {key}"))

    return result