# Setup Companion File Manifests

> Data reference for SETUP.md §2.5–§3. Fetch URLs, file lists, configs, and
> token-replacement rules. SETUP.md owns write targets and conditions.

Base URL: `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main`

---

## Agent files (§ 2.5)

Use **dynamic discovery** via GitHub API tree to enumerate all agents:

```text
GET https://api.github.com/repos/asafelobotomy/copilot-instructions-template/git/trees/main?recursive=1
```

Filter for `type == "blob"` and `path` matching `.github/agents/*.agent.md`. Fetch each verbatim. If `"truncated": true`, fall back to the `agents` array in `workspace-index.json` (fetched in § 3).

---

## Skill files (§ 2.6)

Dynamic discovery: filter API tree for `template/skills/*/SKILL.md`. If truncated, fall back to the `skills.template` array in `workspace-index.json`.

---

## Path instruction stubs (§ 2.7)

| Stub | When to copy |
|------|-------------|
| `tests.instructions.md` | Test files present |
| `api-routes.instructions.md` | API routes present |
| `config.instructions.md` | Config files present |
| `docs.instructions.md` | Markdown/docs present |

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

Fetch pattern: `{BASE_URL}/template/prompts/{name}`

After writing, replace `{{THREE_CHECK_COMMAND}}`, `{{TEST_FRAMEWORK}}`, `{{TEST_COMMAND}}`.

---

## Hook scripts (§ 2.12)

**Configuration**: fetch `{BASE_URL}/template/hooks/copilot-hooks.json` → `.github/hooks/copilot-hooks.json`

Fetch all scripts listed in the `hookScripts.shell` and `hookScripts.powershell` arrays from `workspace-index.json`.

**Bash scripts** → `.github/hooks/scripts/`:

Fetch pattern: `{BASE_URL}/template/hooks/scripts/{name}`

**PowerShell scripts** → `.github/hooks/scripts/`:

Fetch pattern: `{BASE_URL}/template/hooks/scripts/{name}`

After writing `.sh` files: `chmod +x .github/hooks/scripts/*.sh`

---

## Workspace identity files (§ 3)

| Target path | Source |
|-------------|--------|
| `.copilot/workspace/IDENTITY.md` | `template/workspace/IDENTITY.md` |
| `.copilot/workspace/SOUL.md` | `template/workspace/SOUL.md` |
| `.copilot/workspace/USER.md` | `template/workspace/USER.md` |
| `.copilot/workspace/TOOLS.md` | `template/workspace/TOOLS.md` |
| `.copilot/workspace/MEMORY.md` | `template/workspace/MEMORY.md` |
| `.copilot/workspace/workspace-index.json` | `template/workspace/workspace-index.json` |
| `.copilot/workspace/BOOTSTRAP.md` | `template/workspace/BOOTSTRAP.md` |
| `.copilot/workspace/HEARTBEAT.md` | `template/workspace/HEARTBEAT.md` |
| `.copilot/workspace/RESEARCH.md` | `template/workspace/RESEARCH.md` |

Token replacement: `{{PLACEHOLDER}}` tokens from §1, `{{SETUP_DATE}}` → today's date.

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
      "allowWrite": ["${userHome}/.npm"]
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
      "args": ["mcp-server-fetch"],
      "disabled": true
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "disabled": true
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
      "args": ["mcp-server-fetch"],
      "disabled": true
    },
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "disabled": true
    }
  }
}
```

### Stack-specific servers (E22 = C)

Enable from base config when appropriate:

| Server | When to enable |
|--------|----------------|
| `github` | Project uses GitHub |
| `fetch` | Agent reads web docs/APIs |
| `context7` | Project uses third-party libs |

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
for f in .github/agents/*.agent.md .github/skills/*/SKILL.md \
  .github/hooks/copilot-hooks.json .github/hooks/scripts/*.sh \
  .github/hooks/scripts/*.ps1 .github/instructions/*.instructions.md \
  .github/prompts/*.prompt.md .github/workflows/copilot-setup-steps.yml \
  .copilot/workspace/*.md .copilot/workspace/workspace-index.json; do
  [ -f "$f" ] || continue; echo "${f}=$(sha256sum "$f" | cut -c1-12)"
done
```

Write to `.github/copilot-version.md`:

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
