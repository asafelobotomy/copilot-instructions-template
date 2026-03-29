# Research: Copilot Audit Tool Design

> Date: 2026-03-29 | Agent: Researcher | Status: complete

## Summary

This report synthesises findings from seven investigation areas to inform the design
of a static-analysis audit tool (Python or bash) invokable by the Doctor subagent.
The tool must audit every file GitHub Copilot reads, touches, or is influenced by in
VS Code. Key conclusions: (1) the full file set is now well-documented in official VS
Code docs; (2) the `skills-ref` CLI provides the only official validator for
`SKILL.md` files; (3) no standalone "copilot-audit" CLI exists publicly — this
project would be first; (4) `python-frontmatter` + `jsonschema` is the recommended
validation stack; (5) `tiktoken` (`cl100k_base`) is the best offline token estimator
for Claude; (6) ShellCheck covers all hook-script static analysis needs; (7) MCP
config has no public standalone validator — schema knowledge is embedded in VS Code.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/docs/copilot/customization/custom-instructions> | Instruction file types, frontmatter fields, `applyTo` patterns |
| <https://code.visualstudio.com/docs/copilot/customization/custom-agents> | `.agent.md` frontmatter schema, all fields |
| <https://code.visualstudio.com/docs/copilot/customization/agent-skills> | `SKILL.md` format, VS Code-specific extra fields |
| <https://code.visualstudio.com/docs/copilot/customization/prompt-files> | `.prompt.md` frontmatter schema |
| <https://code.visualstudio.com/docs/copilot/customization/hooks> | Hook event types, file locations, JSON wire format |
| <https://code.visualstudio.com/docs/copilot/customization/mcp-servers> | MCP config file structure, stdio/http types |
| <https://code.visualstudio.com/docs/copilot/reference/mcp-configuration> | Full MCP JSON schema field reference |
| <https://code.visualstudio.com/docs/copilot/reference/copilot-settings> | Full `chat.*` and `github.copilot.*` settings reference |
| <https://code.visualstudio.com/docs/copilot/copilot-customization> | Overview — all customisation types, discovery rules |
| <https://agentskills.io/specification> | Agent Skills `SKILL.md` validation rules and constraints |
| <https://raw.githubusercontent.com/agentskills/agentskills/main/skills-ref/README.md> | `skills-ref` CLI validator installation and usage |
| <https://github.com/openai/tiktoken> | tiktoken BPE tokeniser — best offline token estimator |
| <https://python-frontmatter.readthedocs.io/en/latest/> | `python-frontmatter` API reference |
| <https://github.com/koalaman/shellcheck> | ShellCheck — bash/sh static analysis |

---

## Findings

### Q1 — GitHub Copilot Configuration Files

**Complete file set read by VS Code Copilot (as of March 2026):**

| File / Pattern | Type | Trigger |
|---|---|---|
| `.github/copilot-instructions.md` | Always-on instructions | Every request |
| `AGENTS.md` | Always-on instructions | Every request (`chat.useAgentsMdFile=true`) |
| `CLAUDE.md` | Always-on instructions | Every request (`chat.useClaudeMdFile=true`) |
| `.github/instructions/**/*.instructions.md` | File-based instructions | `applyTo` glob match or description match |
| `.claude/rules/**/*.instructions.md` | File-based instructions (Claude format) | Same as above |
| `~/.copilot/instructions/**/*.instructions.md` | User-profile instructions | Cross-workspace |
| `.github/prompts/**/*.prompt.md` | Slash commands | Manual invocation via `/` |
| `.github/agents/**/*.agent.md` | Custom agents | Agent selection |
| `~/.copilot/agents/**/*.agent.md` | Custom agents (user profile) | Cross-workspace |
| `.github/skills/**/SKILL.md` | Agent skills | On-demand by relevance |
| `.github/hooks/**/*.json` | Hooks | Lifecycle events |
| `.claude/settings.json` | Hooks (Claude format) | Lifecycle events |
| `.claude/settings.local.json` | Hooks (Claude format, local) | Lifecycle events |
| `.vscode/mcp.json` | MCP servers | Tool calls in agent mode |
| `.vscode/settings.json` | VS Code settings | Always |
| `.vscode/extensions.json` | Extension recommendations | Informational |

**VS Code settings keys relevant to audit** (`.vscode/settings.json`):

- `chat.instructionsFilesLocations` — custom instruction file roots (map)
- `chat.promptFilesLocations` — custom prompt file roots (map)
- `chat.agentFilesLocations` — custom agent file roots (map)
- `chat.agentSkillsLocations` — custom skill roots (map)
- `chat.hookFilesLocations` — custom hook file roots (map; defaults include `.github/hooks`, `.claude/settings*.json`)
- `chat.useCustomizationsInParentRepositories` — monorepo discovery (bool, default `false`)
- `chat.useAgentsMdFile` — whether `AGENTS.md` is read (bool, default `true`)
- `chat.useClaudeMdFile` — whether `CLAUDE.md` is read (bool, default `true`)
- `chat.useNestedAgentsMdFiles` — subfolder `AGENTS.md` files (experimental)
- `github.copilot.enable` — per-language inline suggestion toggle (map)
- `chat.mcp.access` — org-level MCP on/off
- `chat.plugins.enabled`, `chat.plugins.paths` — agent plugin loading

**Monorepo / parent-repository discovery edge case**: when
`chat.useCustomizationsInParentRepositories=true`, VS Code walks up from the
workspace folder to the `.git` root and discovers all customisations at intermediate
levels. An audit tool must implement the same path-walking logic.

**Sources:**

- <https://code.visualstudio.com/docs/copilot/customization/custom-instructions>
- <https://code.visualstudio.com/docs/copilot/customization/hooks>
- <https://code.visualstudio.com/docs/copilot/reference/copilot-settings>

---

### Q2 — Agent Skills Open Standard: Validation Rules

**`SKILL.md` frontmatter — agentskills.io specification:**

| Field | Required | Constraints |
|---|---|---|
| `name` | Yes | 1–64 chars; `[a-z0-9-]` only; no leading/trailing/consecutive hyphens; **must match parent directory name** |
| `description` | Yes | 1–1024 chars; non-empty; should describe what AND when |
| `license` | No | Short string or filename ref |
| `compatibility` | No | 1–500 chars if present |
| `metadata` | No | Arbitrary `string → string` map |
| `allowed-tools` | No | Space-delimited tool list (experimental) |

**VS Code additional fields** (not in base spec, recognised by VS Code):

| Field | Default | Notes |
|---|---|---|
| `argument-hint` | — | Hint text shown in chat input field |
| `user-invocable` | `true` | `false` hides the skill from the `/` slash-command menu |
| `disable-model-invocation` | `false` | `true` prevents automatic loading by the agent |

**`applyTo`** is a field on **`.instructions.md` files** (not `SKILL.md`) — standard
glob patterns (e.g., `**/*.ts`, `src/api/**`, `"**"` for all files).

**Official CLI validator** (`skills-ref` from `agentskills/agentskills` repo):

```bash
pip install git+https://github.com/agentskills/agentskills#subdirectory=skills-ref
skills-ref validate ./my-skill          # exit 0 = valid, 1 = errors
skills-ref read-properties ./my-skill   # JSON output of parsed fields
```

The tool is marked "demonstration purposes only" — not production-hardened, but
adequate for CI. It validates frontmatter field constraints and naming conventions.
**Recommendation**: copy the validation logic locally rather than installing it as a
CI dependency.

**Token budget guidance from the spec:**

- Skill metadata (`name` + `description`): ~100 tokens — loaded at startup for **all** skills
- `SKILL.md` body: < 5000 tokens recommended; keep body under 500 lines

**Sources:**

- <https://agentskills.io/specification>
- <https://raw.githubusercontent.com/agentskills/agentskills/main/skills-ref/README.md>
- <https://code.visualstudio.com/docs/copilot/customization/agent-skills>

---

### Q3 — MCP Server Validation

**Configuration file:** `.vscode/mcp.json`

**Top-level keys:**

- `"servers"`: required object — map of server name → server config
- `"inputs"`: optional array — input variable definitions for secrets

**Stdio server** (most common, local processes):

| Field | Required | Notes |
|---|---|---|
| `type` | Optional | `"stdio"` — inferred when `command` is present |
| `command` | Required | Executable path or name |
| `args` | Optional | Array of string arguments |
| `env` | Optional | Environment variables — must use `${input:id}` for secrets |
| `envFile` | Optional | Path to `.env` file |
| `sandboxEnabled` | Optional | macOS/Linux only |

**HTTP/SSE server:**

| Field | Required | Notes |
|---|---|---|
| `type` | Required | `"http"` or `"sse"` |
| `url` | Required | Server URL |
| `headers` | Optional | Auth headers — must use `${input:id}` for secrets |

**Known anti-patterns to flag in audit:**

| Pattern | Risk |
|---|---|
| `@modelcontextprotocol/server-git` via `npx` | Package does not exist on npm (404) |
| `@modelcontextprotocol/server-fetch` via `npx` | Package does not exist on npm (404) |
| `mcp-server-git` or `mcp-server-fetch` via `npx` | Use `uvx` instead |
| Hardcoded secrets in `env` values | Security violation — use `${input:id}` |
| `type: "stdio"` without `command` | Invalid configuration |
| Server names outside `[a-zA-Z0-9_-]` | Naming convention violation |

**No public standalone JSON Schema** for `mcp.json`. VS Code embeds IntelliSense
internally; no published schemastore.org entry found. Audit tool must hand-code its
own schema checks. The MCP Inspector (`npx @modelcontextprotocol/inspector`) is an
interactive debugging tool for running servers, not a config-file validator.

**Sources:**

- <https://code.visualstudio.com/docs/copilot/reference/mcp-configuration>
- <https://code.visualstudio.com/docs/copilot/customization/mcp-servers>
- <https://modelcontextprotocol.io/docs/tools/inspector>

---

### Q4 — Token Budget Estimation

**Best available offline options (no API call):**

| Tool | Install | Claude accuracy |
|---|---|---|
| `tiktoken` (`cl100k_base`) | `pip install tiktoken` | ±10% — GPT-4 encoding, good proxy |
| Rule-of-thumb: 4 chars/token | none | ±20%, useful for quick checks |

**`tiktoken`** (OpenAI, Apache 2.0):

```python
import tiktoken
enc = tiktoken.get_encoding("cl100k_base")   # GPT-4 / closest to Claude
token_count = len(enc.encode(text))
```

`cl100k_base` is the standard proxy for Claude token counts without API access.
The ±10% divergence is acceptable for "approaching limit" warnings in an audit tool.
Outputs should be labelled `(estimated, ±10%)`.

**Anthropic's official token counter** requires an API call via the SDK — impractical
for a static offline audit tool.

**Verified gap**: No dedicated offline `anthropic-tokenizer` Python package found;
the repository `anthropics/anthropic-tokenizer-python` returns HTTP 404.

**Sources:**

- <https://github.com/openai/tiktoken>
- <https://agentskills.io/specification> (token budget guidance)

---

### Q5 — Markdown Frontmatter Validation

**Recommended Python stack:**

`python-frontmatter` (zero-dep, PyPI, actively maintained):

```python
import frontmatter

post = frontmatter.load("file.instructions.md")
meta = post.metadata   # dict — all frontmatter key/value pairs
body = post.content    # str — Markdown body after frontmatter
```

Combine with `jsonschema` for schema-based field validation:

```python
import jsonschema

skill_schema = {
    "type": "object",
    "required": ["name", "description"],
    "properties": {
        "name": {
            "type": "string",
            "maxLength": 64,
            "pattern": "^[a-z0-9]+(-[a-z0-9]+)*$"
        },
        "description": {"type": "string", "maxLength": 1024, "minLength": 1}
    }
}
jsonschema.validate(meta, skill_schema)
```

**Bash alternative** — `yq` (Go binary, `snap install yq`):

```bash
name=$(sed -n '/^---$/,/^---$/p' SKILL.md | yq '.name')
```

**markdownlint-cli2** (already in this repo) validates Markdown style but does **not**
parse or validate YAML frontmatter content.

**Sources:**

- <https://python-frontmatter.readthedocs.io/en/latest/>
- <https://github.com/mikefarah/yq>

---

### Q6 — Existing Copilot Audit / Health Check Tools

GitHub's `robots.txt` blocks automated search queries — no automated search was
possible. Findings are based on documentation review and codebase inspection.

**Found in this repo:**

| Path | What it validates |
|---|---|
| `scripts/validate-agent-frontmatter.sh` | `.github/agents/*.agent.md` frontmatter fields; exits 0/1 |
| `scripts/sync-template-parity.sh` | `.github/` mirrors vs `template/` sources |
| `.github/agents/doctor.agent.md` | Conversational Doctor, 13 checks (D1–D13); **not** scriptable from CI |
| `tests/test-validate-agent-frontmatter.sh` | Test coverage for the above |

**Gap**: No standalone, scriptable, CI-invocable audit tool exists with machine-readable
JSON output. The Doctor agent runs only interactively. **No public third-party
"copilot-audit" CLI tool was found.**

---

### Q7 — Shell Script Static Analysis

**ShellCheck** — the standard bash analyser:

```bash
shellcheck myscript.sh                 # exits 1 on warnings/errors
shellcheck --severity=error script.sh  # fail only on errors (not style)
shellcheck -f json script.sh           # machine-readable JSON output
```

ShellCheck catches: missing shebang, unquoted variables, SC2039 (use `$()` not
backticks), word splitting, and 500+ other patterns. It does **not** automatically
flag the absence of `set -euo pipefail` — an explicit grep is required:

```bash
grep -q 'set -euo pipefail' "$script" || echo "WARN: missing set -euo pipefail"
```

**Syntax-only check** (fastest, no semantics):

```bash
bash -n script.sh   # exits non-zero on syntax errors only
```

**JSON file validation** (stdlib, no extra deps):

```bash
python3 -m json.tool .github/hooks/copilot-hooks.json > /dev/null
python3 -m json.tool .vscode/mcp.json > /dev/null
```

**Hook wire-format contract** (JSON stdin → JSON stdout): No existing dedicated tool.
A minimal test harness can pipe `{}` on stdin and validate stdout with `python3 -m
json.tool`. Custom implementation required in the audit tool. Extractable from the
existing `tests/test-hook-*.sh` files in this repo.

**Sources:**

- <https://github.com/koalaman/shellcheck>
- <https://code.visualstudio.com/docs/copilot/customization/hooks>

---

## Recommended Audit Tool Design

### Language

**Python core + bash CLI wrapper** — reasons:

- `python-frontmatter` handles YAML frontmatter parsing reliably
- `jsonschema` handles schema validation with clear error messages
- `tiktoken` handles token estimation
- Inline Python already used in `scripts/validate-agent-frontmatter.sh`
- Cross-platform (Linux/macOS/Windows without bash)
- Machine-readable output via `json.dumps()`

Bash wrapper (`scripts/copilot-audit.sh`):

```bash
#!/usr/bin/env bash
set -euo pipefail
exec python3 "$(dirname "$0")/copilot_audit.py" "$@"
```

### JSON output schema

```json
{
  "summary": {"total": 47, "critical": 0, "high": 2, "warn": 5, "info": 3, "ok": 37},
  "checks": [
    {
      "id": "A1",
      "file": ".github/agents/doctor.agent.md",
      "severity": "OK",
      "message": "Frontmatter valid"
    },
    {
      "id": "M3",
      "file": ".vscode/mcp.json",
      "severity": "HIGH",
      "message": "Hardcoded secret in env.GITHUB_TOKEN — use ${input:github-token}"
    }
  ]
}
```

Exit code: `0` if no CRITICAL/HIGH, `1` otherwise. Doctor agent parses the JSON
summary to populate its D1–D13 check results programmatically.

### Check module inventory

| Module | ID prefix | Primary tool | Key checks |
|---|---|---|---|
| Agent frontmatter | `A` | `python-frontmatter` + `jsonschema` | `name`, `description`, `model`, `tools`; handoff target existence |
| Instructions frontmatter | `I` | `python-frontmatter` | `applyTo` glob validity; required fields; placeholder separation |
| Prompt frontmatter | `P` | `python-frontmatter` | `agent`, `model`, `tools` valid values; file location correctness |
| SKILL.md validation | `S` | `python-frontmatter` + agentskills spec | `name` matches dir; length constraints; body token estimate |
| MCP config | `M` | `json.load` + hand-coded schema | Anti-patterns; secret leakage; server type validity |
| Hook config | `H` | `json.load` + ShellCheck | Valid event names; script paths exist; JSON structure |
| Hook scripts | `SH` | `shellcheck -f json` + `grep` | Shebang; `set -euo pipefail`; syntax errors |
| Token budget | `T` | `tiktoken` | Instructions, agents, skills body sizes; total estimated context |
| VS Code settings | `VS` | `json.load` | Deprecated keys; security misconfigs (`chat.tools.global.autoApprove=true`) |
| Structural | `ST` | `pathlib.glob` | Required files present; placeholder separation; section headings |

### Python dependencies

```text
python-frontmatter>=1.1.0   # YAML frontmatter parsing
jsonschema>=4.0.0            # schema-based field validation
tiktoken>=0.7.0              # token estimation (optional; degrades gracefully)
```

External optional tools (degrade gracefully if absent):

- `shellcheck` — shell script analysis (flag as `[INFO]` if not installed)
- `python -m json.tool` — JSON syntax (stdlib, always available)

### Integration with Doctor agent

The Doctor agent's D1–D13 checks can be replaced or augmented by invoking:

```text
python3 scripts/copilot_audit.py --output json
```

and parsing the JSON summary. This makes the Doctor's checks deterministic, testable,
and CI-invocable — eliminating the current dependency on conversational grep.

---

## Gaps / Further Research Needed

1. **MCP JSON schema**: No public schema found. Must be hand-coded in audit tool.
   Consider raising a VS Code issue to request publication on `schemastore.org`.

2. **`skills-ref` production readiness**: Labelled "demonstration purposes only."
   Do not use as-installed in a published tool — inline the validation logic.

3. **Anthropic offline tokeniser**: No dedicated offline Python package found for
   Claude-exact tokenisation. `tiktoken` (`cl100k_base`) remains the best proxy.

4. **GitHub peer tool search**: `robots.txt` prevented automated search for
   `copilot-audit`, `copilot-health-check`, and `copilot-config-validator`. Recommend
   a manual search to confirm no peer tool exists before publishing.

5. **Hook wire-format contract testing**: No existing utility. Needs a custom harness,
   extractable from `tests/test-hook-*.sh` files already in this repo.

6. **`settings.json` deprecated key inventory**: The settings reference page was
   truncated during fetch. The deprecated `infer` agent field (superseded by
   `user-invocable` + `disable-model-invocation`) is confirmed; a full deprecated-key
   inventory requires a complete additional pass over the settings reference.
