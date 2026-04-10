# Setup Companion File Manifests

> Data reference for SETUP.md §2.5–§3. Fetch URLs, file lists, configs, and
> token-replacement rules. SETUP.md owns write targets and conditions.

Base URL: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main`

---

## Protocol sources

Use `SETUP.md` and `UPDATE.md` for behaviour. Use this section as the canonical
inventory of supporting upstream sources so `AGENTS.md` and
`.github/agents/setup.agent.md` do not need to restate the same fetch lists.

| Protocol | Canonical behaviour file | Supporting upstream sources |
|----------|--------------------------|-----------------------------|
| Setup | `SETUP.md` | `template/copilot-instructions.md`, `template/setup/interview.md`, `template/setup/manifests.md`, `template/workspace/operations/workspace-index.json`, `template/copilot-setup-steps.yml`, `template/vscode/settings.json`, `template/vscode/extensions.json`, `starter-kits/REGISTRY.json` |
| Update, backup restore, and factory restore | `UPDATE.md` | `VERSION.md`, `MIGRATION.md`, `MIGRATION.archive.md`, `CHANGELOG.md`, `template/copilot-instructions.md`, `template/setup/manifests.md`, `SETUP.md` |

---

## Agent files (§ 2.5)

Use **dynamic discovery** via GitHub API tree to enumerate all agent assets:

```text
GET https://api.github.com/repos/asafelobotomy/copilot-instructions-template/git/trees/main?recursive=1
```

Filter for `type == "blob"` and `path` matching `.github/agents/*.agent.md` or `.github/agents/*.json`. Fetch each verbatim. This currently includes the routing sidecar `.github/agents/routing-manifest.json`. If `"truncated": true`, fall back to the `agents` and `agentSupportFiles` arrays in the workspace-index payload prefetched by SETUP.md §2. Write that same payload to `.copilot/workspace/operations/workspace-index.json` later in §3.

---

## Skill files (§ 2.6)

Dynamic discovery: filter API tree for `template/skills/*/SKILL.md`. If truncated, fall back to the `skills.template` array in the workspace-index payload prefetched by SETUP.md §2.

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

Fetch pattern: `{BASE_URL}/template/instructions/{name}`

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

Fetch pattern: `{BASE_URL}/template/prompts/{name}`

After writing, replace `{{THREE_CHECK_COMMAND}}`, `{{TEST_FRAMEWORK}}`, `{{TEST_COMMAND}}`.

---

## Hook scripts (§ 2.12)

**Configuration**: fetch `{BASE_URL}/template/hooks/copilot-hooks.json` → `.github/hooks/copilot-hooks.json`

Fetch all files listed in the `hookScripts.shell`, `hookScripts.powershell`, `hookScripts.python`, and `hookScripts.json` arrays from the workspace-index payload prefetched by SETUP.md §2.

**Bash scripts** → `.github/hooks/scripts/`:

Fetch pattern: `{BASE_URL}/template/hooks/scripts/{name}`

**PowerShell scripts** → `.github/hooks/scripts/`:

Fetch pattern: `{BASE_URL}/template/hooks/scripts/{name}`

**Python support files** → `.github/hooks/scripts/`:

Fetch pattern: `{BASE_URL}/template/hooks/scripts/{name}`

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
| `.copilot/workspace/operations/ledger.md` | `template/workspace/operations/ledger.md` |
| `.copilot/workspace/knowledge/diaries/README.md` | `template/workspace/knowledge/diaries/README.md` |

Token replacement: `{{PLACEHOLDER}}` tokens from §1, `{{SETUP_DATE}}` → today's date, `{{SPATIAL_THEME}}` → chosen one-word metaphor, `{{SPATIAL_VOCAB}}` → the resolved Markdown row set from SETUP.md §2.

---

## MCP server configs (§ 2.10)

### Sandbox detection (Linux only)

```bash
[[ "$(readlink -f /home)" != "/home" ]] && echo "immutable" || echo "standard"
```

- `standard` (or macOS): use **sandboxed** config
- `immutable` (Fedora Atomic, Bazzite, NixOS etc.): use **unsandboxed** config

### Sandboxed config (default)

```json
{
  "sandbox": {
    "filesystem": {
      "allowWrite": ["${userHome}/.npm", "${userHome}/.cache/uv", "${userHome}/.local/share/uv"]
    },
    "network": {
      "allowedDomains": ["pypi.org", "files.pythonhosted.org"]
    }
  },
  "servers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${workspaceFolder}"],
      "sandboxEnabled": true,
      "sandbox": {
        "filesystem": {
          "allowWrite": ["${workspaceFolder}", "${userHome}/.npm"],
          "denyRead": ["${userHome}/.ssh", "${userHome}/.gnupg", "${userHome}/.aws"]
        }
      }
    },
    "git": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "${workspaceFolder}"],
      "sandboxEnabled": true,
      "sandbox": {
        "filesystem": {
          "allowWrite": ["${workspaceFolder}"],
          "denyRead": ["${userHome}/.ssh", "${userHome}/.gnupg", "${userHome}/.aws"]
        }
      }
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "disabled": true
    },
    "fetch": {
      "type": "stdio",
      "command": "uvx",
      "args": ["--with", "httpx[socks]>=0.28", "mcp-server-fetch"],
      "disabled": true,
      "sandboxEnabled": true,
      "sandbox": {
        "filesystem": {
          "denyRead": ["${userHome}/.ssh", "${userHome}/.gnupg", "${userHome}/.aws"]
        }
      }
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "disabled": true
    },
    "heartbeat": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "--from", "mcp[cli]",
        "mcp", "run",
        "${workspaceFolder}/.github/hooks/scripts/mcp-heartbeat-server.py"
      ],
      "sandboxEnabled": true,
      "sandbox": {
        "filesystem": {
          "allowWrite": ["${workspaceFolder}"],
          "denyRead": ["${userHome}/.ssh", "${userHome}/.gnupg", "${userHome}/.aws"]
        }
      }
    }
  }
}
```

### Unsandboxed config (immutable Linux distros)

```json
{
  "servers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${workspaceFolder}"]
    },
    "git": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "${workspaceFolder}"]
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "disabled": true
    },
    "fetch": {
      "type": "stdio",
      "command": "uvx",
      "args": ["--with", "httpx[socks]>=0.28", "mcp-server-fetch"],
      "disabled": true
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "disabled": true
    },
    "heartbeat": {
      "type": "stdio",
      "command": "uvx",
      "args": [
        "--from", "mcp[cli]",
        "mcp", "run",
        "${workspaceFolder}/.github/hooks/scripts/mcp-heartbeat-server.py"
      ]
    }
  }
}
```

### Optional and stack-specific servers (E22 = B)

Enable from base config when selected in E22a:

| Server | When to enable |
|--------|----------------|
| `github` | User selected GitHub integration |
| `fetch` | User selected web/docs retrieval |
| `context7` | User selected third-party library docs |

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

Compute section fingerprints and file manifest hashes:

```bash
# Section fingerprints
for i in $(seq 1 9); do
  fp=$(awk "/^## §${i} —/{found=1; next} /^## §/{if(found) exit} found{print}" \
    .github/copilot-instructions.md | sha256sum | cut -c1-12)
  echo "§${i}=${fp}"
done
# File manifest
for f in .github/agents/*.agent.md .github/agents/*.json .github/skills/*/SKILL.md \
  .github/starter-kits/*/plugin.json \
  .github/starter-kits/*/skills/*/SKILL.md \
  .github/starter-kits/*/instructions/*.instructions.md \
  .github/starter-kits/*/prompts/*.prompt.md \
  .github/hooks/copilot-hooks.json .github/hooks/scripts/*.sh \
  .github/hooks/scripts/*.ps1 .github/hooks/scripts/*.json \
  .github/hooks/scripts/*.py .github/instructions/*.instructions.md \
  .github/prompts/*.prompt.md .github/workflows/copilot-setup-steps.yml \
  .vscode/settings.json .vscode/extensions.json .vscode/mcp.json \
  CLAUDE.md \
  .copilot/workspace/identity/*.md .copilot/workspace/knowledge/*.md .copilot/workspace/operations/*.md .copilot/workspace/operations/workspace-index.json .copilot/workspace/knowledge/diaries/README.md; do
  [ -f "$f" ] || continue; echo "${f}=$(sha256sum "$f" | cut -c1-12)"
done
```

If `sha256sum` is unavailable, use this Python fallback instead:

```python
import hashlib, pathlib, glob

# Section fingerprints
text = pathlib.Path('.github/copilot-instructions.md').read_text(encoding='utf-8')
import re
for i in range(1, 10):
    match = re.search(rf'(?m)^## §{i} —.*?(?=^## §|\Z)', text, re.DOTALL)
    body = match.group(0) if match else ''
    fp = hashlib.sha256(body.encode()).hexdigest()[:12]
    print(f'§{i}={fp}')

# File manifest
patterns = [
  '.github/agents/*.agent.md', '.github/agents/*.json', '.github/skills/*/SKILL.md',
    '.github/starter-kits/*/plugin.json',
    '.github/starter-kits/*/skills/*/SKILL.md',
    '.github/starter-kits/*/instructions/*.instructions.md',
    '.github/starter-kits/*/prompts/*.prompt.md',
    '.github/hooks/copilot-hooks.json', '.github/hooks/scripts/*.sh',
  '.github/hooks/scripts/*.ps1', '.github/hooks/scripts/*.json',
  '.github/hooks/scripts/*.py', '.github/instructions/*.instructions.md',
    '.github/prompts/*.prompt.md', '.github/workflows/copilot-setup-steps.yml',
    '.vscode/settings.json', '.vscode/extensions.json', '.vscode/mcp.json',
    'CLAUDE.md',
    '.copilot/workspace/identity/*.md', '.copilot/workspace/knowledge/*.md',
    '.copilot/workspace/operations/*.md', '.copilot/workspace/operations/workspace-index.json',
    '.copilot/workspace/knowledge/diaries/README.md',
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

<!-- section-fingerprints
§1=<fp> ... §9=<fp>
-->

<!-- file-manifest
<path>=<hash> (one per installed companion file)
-->

<!-- setup-answers
PLACEHOLDER=value (one per resolved token)
-->
```

Omit fingerprint/manifest blocks if terminal unavailable. Always write setup-answers.

---

## Companion extension (§ 2.15)

Install: `code --install-extension asafelobotomy.copilot-profile-tools`
VSIX fallback: `https://api.github.com/repos/asafelobotomy/copilot-profile-tools/releases/latest`
