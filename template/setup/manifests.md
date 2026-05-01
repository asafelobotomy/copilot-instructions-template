# Setup Companion File Manifests

> Data reference for the Setup agent §2.5–§3. Fetch URLs, file lists, configs, and
> token-replacement rules. The Setup agent owns write targets and conditions.

Base URL: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main`

---

## Protocol sources

Use `agents/setup.agent.md` for behaviour. Use this section as the canonical
inventory of supporting upstream sources so `AGENTS.md` and
`.github/agents/setup.agent.md` do not need to restate the same fetch lists.

| Protocol | Canonical behaviour file | Supporting upstream sources |
|----------|--------------------------|-----------------------------|
| Setup | `agents/setup.agent.md` | `template/copilot-instructions.md`, `template/setup/interview.md`, `template/setup/manifests.md`, `template/workspace/operations/workspace-index.json`, `template/copilot-setup-steps.yml`, `template/vscode/settings.json`, `template/vscode/extensions.json`, `starter-kits/REGISTRY.json` |
| Update, backup restore, and factory restore | `agents/setup.agent.md` | `VERSION.md`, `CHANGELOG.md`, `template/copilot-instructions.md`, `template/setup/manifests.md`, `template/setup/interview.md`, `template/workspace/operations/workspace-index.json`, `template/vscode/mcp.json`, `starter-kits/REGISTRY.json` |

---

## Agent files (§ 2.5)

**All-local mode** (S6 = All-local or per-surface local): Copy all agent files
from `${CLAUDE_PLUGIN_ROOT}/agents/` to `.github/agents/`. This includes all
`*.agent.md` files and the routing sidecar `routing-manifest.json`.

**Plugin-backed mode** (S6 = Plugin-backed or per-surface plugin): Skip. Agents
are delivered by the plugin and discovered automatically. Do not create
`.github/agents/`.

---

## Skill files (§ 2.6)

**All-local mode**: Copy all skill directories from
`${CLAUDE_PLUGIN_ROOT}/skills/` to `.github/skills/`. Each skill directory
contains a `SKILL.md` frontmatter file.

**Plugin-backed mode**: Skip. Skills are delivered by the plugin and discovered
automatically. Do not create `.github/skills/`.

---

## Path instruction stubs (§ 2.7)

For each stub, evaluate the `condition` before installing. A condition `exists:GLOB` is satisfied when at least one file in the workspace matches the glob. Install the stub if any listed condition is true.

| Stub | Install conditions |
|------|-------------------|
| `tests.instructions.md` | `exists:**/*.test.*` OR `exists:**/*.spec.*` OR `exists:**/tests/**` OR `exists:**/test/**` OR `exists:**/__tests__/**` |
| `api-routes.instructions.md` | `exists:**/api/**` OR `exists:**/routes/**` OR `exists:**/controllers/**` OR `exists:**/handlers/**` |
| `config.instructions.md` | `exists:**/*.config.*` OR `exists:**/.eslintrc*` OR `exists:**/.prettierrc*` OR `exists:**/.stylelintrc*` OR language detected as JavaScript/TypeScript/Python |
| `docs.instructions.md` | `exists:**/*.md` (true for almost every project) |
| `terminal.instructions.md` | `exists:**/*` (install for every non-empty project; terminal discipline applies regardless of source language) |
| `plugin-components.instructions.md` | S6 = All-local **and** A18 ≠ No |

Fetch pattern: `${CLAUDE_PLUGIN_ROOT}/template/instructions/{name}`

After writing, replace `{{TEST_FRAMEWORK}}` and `{{TEST_COMMAND}}` tokens in stubs that contain them.

---

## Prompt files (§ 2.8)

| File |
|------|
| `explain.prompt.md` |
| `context-map.prompt.md` |
| `refactor.prompt.md` |
| `test-gen.prompt.md` |
| `review-file.prompt.md` |
| `commit-msg.prompt.md` |
| `onboard-commit-style.prompt.md` |

Fetch pattern: `${CLAUDE_PLUGIN_ROOT}/template/prompts/{name}`

After writing, replace `{{THREE_CHECK_COMMAND}}`, `{{TEST_FRAMEWORK}}`, `{{TEST_COMMAND}}`.

---

## Hook scripts (§ 2.12)

**Plugin-backed mode — OpenPlugin or Claude-format**: Skip. Hooks are delivered
by the plugin's `hooks/hooks.json` and execute from the plugin root using
`${PLUGIN_ROOT}` or `${CLAUDE_PLUGIN_ROOT}` paths. Do not create `.github/hooks/`.

**Plugin-backed mode — VS Code Copilot format**: The VS Code Copilot plugin
format (`plugin.json`) does not deliver hooks. If A16 = Yes, install hooks
locally even in plugin-backed mode (same steps as All-local below).

**All-local mode** (S6 = All-local or per-surface local, and A16 = Yes):

**Configuration**: Copy `${CLAUDE_PLUGIN_ROOT}/template/hooks/copilot-hooks.json` → `.github/hooks/copilot-hooks.json`

Fetch all files listed in the `hookScripts.shell`, `hookScripts.powershell`, `hookScripts.python`, and `hookScripts.json` arrays from the workspace-index payload.

**Bash scripts** → `.github/hooks/scripts/`:

Source: `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/{name}`

**PowerShell scripts** → `.github/hooks/scripts/`:

Source: `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/{name}`

**Python support files** → `.github/hooks/scripts/`:

Source: `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/{name}`

After writing `.sh` files: `chmod +x .github/hooks/scripts/*.sh`

---

## Workspace identity files (§ 3)

| Target path | Source |
|-------------|--------|
| `.copilot/workspace/identity/IDENTITY.md` | `template/workspace/identity/IDENTITY.md` |
| `.copilot/workspace/identity/SOUL.md` | `template/workspace/identity/SOUL.md` |
| `.copilot/workspace/knowledge/USER.md` | `template/workspace/knowledge/USER.md` |
| `.copilot/workspace/knowledge/TOOLS.md` | `template/workspace/knowledge/TOOLS.md` |
| `.copilot/workspace/knowledge/MEMORY.md` | `template/workspace/knowledge/MEMORY.md` |
| `.copilot/workspace/operations/commit-style.md` | `template/workspace/operations/commit-style.md` |
| `.copilot/workspace/operations/workspace-index.json` | `template/workspace/operations/workspace-index.json` |
| `.copilot/workspace/identity/BOOTSTRAP.md` | `template/workspace/identity/BOOTSTRAP.md` |
| `.copilot/workspace/operations/HEARTBEAT.md` | `template/workspace/operations/HEARTBEAT.md` |
| `.copilot/workspace/knowledge/RESEARCH.md` | `template/workspace/knowledge/RESEARCH.md` |
| `.copilot/workspace/knowledge/MEMORY-GUIDE.md` | `template/workspace/knowledge/MEMORY-GUIDE.md` |
| `.copilot/workspace/knowledge/diaries/README.md` | `template/workspace/knowledge/diaries/README.md` |

Token replacement: `{{PLACEHOLDER}}` tokens from §1, `{{SETUP_DATE}}` → today's date.

---

## MCP server configs (§ 2.10)

### Sandbox detection (Linux only)

```bash
if [[ "$OSTYPE" == darwin* ]]; then
  echo "standard"
else
  [[ "$(readlink -f /home)" != "/home" ]] && echo "immutable" || echo "standard"
fi
```

- `standard` (Linux and macOS): write `template/vscode/mcp.json` → `.vscode/mcp.json`
- `immutable` (Fedora Atomic, Bazzite, NixOS etc.): write `template/vscode/mcp-unsandboxed.json` → `.vscode/mcp.json`

Full server configs: `${CLAUDE_PLUGIN_ROOT}/template/vscode/mcp.json` (sandboxed) and
`${CLAUDE_PLUGIN_ROOT}/template/vscode/mcp-unsandboxed.json` (unsandboxed).

### Optional and stack-specific servers (E22 = B)

Enable from base config when selected in E22a:

> **Always enabled** (no selection required): `heartbeat` and `sequential-thinking` are enabled by default in the base config. `heartbeat` requires hook scripts to be installed (A16 = Yes or plugin-backed mode); if hooks are skipped it fails softly without breaking other functionality.

| Server | When to enable |
|--------|----------------|
| `github` | User selected GitHub integration |
| `fetch` | User selected web/docs retrieval |
| `context7` | User selected third-party library docs |
| `playwright` | User selected browser automation for agent-driven website navigation |

Add for detected dependencies:

| Stack | Server | Transport |
|-------|--------|-----------|
| Browser/UI | `@playwright/mcp` | `npx -y @playwright/mcp@latest` |
| PostgreSQL | Search MCP Marketplace | varies |
| SQLite | Search MCP Marketplace | varies |
| Redis | Search MCP Marketplace | varies |
| Docker | Search MCP Marketplace | varies |
| AWS | Search MCP Marketplace | varies |

---


## VS Code settings (§ 2.11)

Merge into `.vscode/settings.json` (do not overwrite existing values):

```json
{
  "chat.mcp.autostart": "newAndOutdated",
  "chat.subagents.allowInvocationsFromSubagents": true,
  "chat.useAgentsMdFile": true,
  "chat.useNestedAgentsMdFiles": true,
  "chat.useCustomAgentHooks": true,
  "chat.promptFilesRecommendations": true,
  "chat.plugins.enabled": true
}
```

Also merge extension recommendations from `{BASE_URL}/template/vscode/extensions.json` into `.vscode/extensions.json`.

---

## Version file template (§ 2.13)

Compute section fingerprints and file manifest hashes. When ownership mode is
`plugin-backed`, skip file-manifest entries for surfaces managed by the plugin
(agents, skills, hook scripts) — those files do not exist locally.

When ownership mode is `all-local`, hash all surfaces as before.

```bash
# Section fingerprints (§10 is user-modified; included for drift visibility)
for i in $(seq 1 14); do
  fp=$(awk "/^## §${i} —/{found=1; next} /^## §/{if(found) exit} found{print}" \
    .github/copilot-instructions.md | sha256sum | cut -c1-12)
  echo "§${i}=${fp}"
done
# File manifest
for f in .github/agents/*.agent.md .github/agents/*.json .github/skills/*/SKILL.md \
  .github/starter-kits/*/.claude-plugin/plugin.json \
  .github/starter-kits/*/skills/*/SKILL.md \
  .github/starter-kits/*/commands/*.md \
  .github/hooks/copilot-hooks.json .github/hooks/scripts/*.sh \
  .github/hooks/scripts/*.ps1 .github/hooks/scripts/*.json \
  .github/hooks/scripts/*.py .github/instructions/*.instructions.md \
  .github/prompts/*.prompt.md .github/workflows/copilot-setup-steps.yml \
  .vscode/settings.json .vscode/extensions.json .vscode/mcp.json \
  CLAUDE.md \
  .copilot/workspace/identity/*.md .copilot/workspace/knowledge/*.md .copilot/workspace/operations/*.md .copilot/workspace/operations/workspace-index.json .copilot/workspace/knowledge/diaries/*.md; do
  [ -f "$f" ] || continue; echo "${f}=$(sha256sum "$f" | cut -c1-12)"
done
```

If `sha256sum` is unavailable, use this Python fallback instead:

```python
import hashlib, pathlib, glob

# Section fingerprints (§10 is user-modified; included for drift visibility)
text = pathlib.Path('.github/copilot-instructions.md').read_text(encoding='utf-8')
import re
for i in range(1, 15):
    match = re.search(rf'(?m)^## §{i} —.*?(?=^## §|\Z)', text, re.DOTALL)
    body = match.group(0) if match else ''
    fp = hashlib.sha256(body.encode()).hexdigest()[:12]
    print(f'§{i}={fp}')

# File manifest
patterns = [
  '.github/agents/*.agent.md', '.github/agents/*.json', '.github/skills/*/SKILL.md',
    '.github/starter-kits/*/.claude-plugin/plugin.json',
    '.github/starter-kits/*/skills/*/SKILL.md',
    '.github/starter-kits/*/commands/*.md',
    '.github/hooks/copilot-hooks.json', '.github/hooks/scripts/*.sh',
  '.github/hooks/scripts/*.ps1', '.github/hooks/scripts/*.json',
  '.github/hooks/scripts/*.py', '.github/instructions/*.instructions.md',
    '.github/prompts/*.prompt.md', '.github/workflows/copilot-setup-steps.yml',
    '.vscode/settings.json', '.vscode/extensions.json', '.vscode/mcp.json',
    'CLAUDE.md',
    '.copilot/workspace/identity/*.md', '.copilot/workspace/knowledge/*.md',
    '.copilot/workspace/operations/*.md', '.copilot/workspace/operations/workspace-index.json',
    '.copilot/workspace/knowledge/diaries/*.md',
]
for pattern in patterns:
    for f in sorted(glob.glob(pattern)):
        h = hashlib.sha256(pathlib.Path(f).read_bytes()).hexdigest()[:12]
        print(f'{f}={h}')
```

Omit fingerprint/manifest blocks only if neither `sha256sum` nor Python is available. Always write setup-answers.

```markdown
# Installed Template Version

X.Y.Z
Applied: YYYY-MM-DD
Ownership: plugin-backed | all-local

<!-- ownership-mode
OWNERSHIP_MODE=plugin-backed|all-local
AGENTS=plugin|local
SKILLS=plugin|local
HOOKS=plugin|local
-->

<!-- section-fingerprints
§1=<fp> ... §14=<fp>
-->

<!-- file-manifest
<path>=<hash> (one per installed companion file)
-->

<!-- setup-answers
PLACEHOLDER=value (one per resolved token)
-->

<!-- install-metadata
MCP_AVAILABLE=<comma-separated IDs of all configured optional servers>
MCP_ENABLED=<comma-separated IDs of enabled optional servers>
INSTRUCTION_STUBS=<comma-separated filenames of installed instruction stubs>
STARTER_KITS_MATCHED=<comma-separated names of stack-matched kits>
STARTER_KITS_INSTALLED=<comma-separated name@version of installed kits>
-->
```

---

## Companion extension (§ 2.15)

Install: `code --install-extension asafelobotomy.copilot-extension`
VSIX fallback: `https://api.github.com/repos/asafelobotomy/copilot-extension/releases/latest`
