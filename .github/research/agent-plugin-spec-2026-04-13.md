# Research: VS Code Agent Plugin Specification

> Date: 2026-04-13 | Agent: Researcher | Status: final

## Summary

VS Code agent plugins (Preview, v1.110+) use a `plugin.json` manifest whose
only required field is `name`. The canonical spec is the Claude Code plugin
reference; VS Code auto-detects and parses Claude Code plugin format. Fields
like `engines.vscode`, `publisher`, and `contributes` are **not part of the
spec** — they belong to VS Code Extension `package.json`, a completely
different packaging system. The `vscode://chat-plugin/install?source=…` URL
scheme is not documented; the documented "Install from Source" UI takes a
plain Git repository URL pointing to the repo root — subdirectory install is
only available through marketplace `git-subdir` source entries.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://code.visualstudio.com/docs/copilot/customization/agent-plugins> | VS Code agent-plugins primary doc — directory structure, install flows, hooks, MCP |
| <https://code.claude.com/docs/en/plugins-reference> | Canonical plugin manifest schema — required/optional fields, component paths, complete schema |
| <https://code.claude.com/docs/en/plugin-marketplaces> | Marketplace schema — `git-subdir` source type for subdirectory installs |
| <https://code.visualstudio.com/updates/v1_110> | v1.110 Feb 2026 release notes — agent plugins experimental, `chat.plugins.*` settings |
| <https://github.com/github/copilot-plugins> | Official GitHub Copilot plugins marketplace repo |
| <https://github.com/github/awesome-copilot> | Community marketplace — plugins, skills, agents, hooks for Copilot |
| <https://raw.githubusercontent.com/rwoll/markdown-review/main/plugin.json> | Real-world plugin.json cited in official VS Code docs — shows actual field usage |

---

## Findings

### 1. Complete `plugin.json` Schema

**Canonical source:** `code.claude.com/docs/en/plugins-reference` (Plugin manifest schema section)

**Manifest location (Claude Code format):** `.claude-plugin/plugin.json`
**Manifest location (VS Code format):** `plugin.json` at plugin root (VS Code auto-detects both)

**The manifest is optional.** If omitted, VS Code auto-discovers components in
default directories (`skills/`, `agents/`, `hooks/hooks.json`, `.mcp.json`) and
derives the plugin name from the directory name.

#### Required fields (when manifest is present)

| Field | Type | Note |
|-------|------|------|
| `name` | string | Only required field. Kebab-case, no spaces. |

#### Optional metadata fields

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Semver (e.g. `"1.2.0"`). If set in both manifest and marketplace entry, manifest wins. |
| `description` | string | Brief purpose description. |
| `author` | object | `{ name, email?, url? }` |
| `homepage` | string | Documentation URL. |
| `repository` | string | Source code URL. |
| `license` | string | SPDX identifier (e.g. `"MIT"`). |
| `keywords` | array | Discovery tags. |
| `category` | string | Category for organisation (e.g. `"productivity"`). |

#### Optional component path fields

| Field | Type | Description |
|-------|------|-------------|
| `skills` | string\|array | Directories containing `<name>/SKILL.md`. Replaces default `skills/`. |
| `commands` | string\|array | Flat `.md` skill files or directories. |
| `agents` | string\|array | Agent markdown files. |
| `hooks` | string\|array\|object | Hook config path or inline hook config. |
| `mcpServers` | string\|array\|object | MCP server config path or inline config. |
| `outputStyles` | string\|array | Output style file/directory paths. |
| `lspServers` | string\|array\|object | LSP server configs. |
| `userConfig` | object | User-configurable values prompted at enable time. |
| `channels` | array | Message channel declarations (Telegram/Slack/Discord-style). |

#### Fields that do NOT exist in the spec

| Field | Origin | Note |
|-------|--------|------|
| `engines.vscode` | VS Code Extension `package.json` | Entirely different packaging system. Not used in agent plugins. |
| `publisher` | VS Code Extension `package.json` | Not part of agent plugin spec. |
| `contributes` | VS Code Extension `package.json` | Not part of agent plugin spec. Component references use top-level `skills`, `agents`, etc. directly. |
| `displayName` | Undocumented | Not in the canonical spec. Currently used in this repo's starter-kits. Likely silently ignored. |

#### Real-world example — `rwoll/markdown-review` (cited in official VS Code docs)

```json
{
  "name": "markdown-review",
  "description": "Markdown viewer with inline commenting",
  "version": "0.0.8",
  "author": { "name": "rwoll" },
  "repository": "https://github.com/rwoll/markdown-review",
  "license": "MIT",
  "keywords": ["review", "plan", "feedback", "markdown", "annotation"],
  "category": "productivity",
  "skills": "packages/copilot-plugin/skills/"
}
```

No `displayName`, no `engines.vscode`, no `publisher`, no `contributes`.

---

### 2. `vscode://chat-plugin/install?source=…` URL Handler

**This URL scheme is not documented in any official VS Code or Claude Code
documentation.** The documented install paths are:

| Method | What it accepts | Subdirectory? |
|--------|----------------|---------------|
| Extensions view → `@agentPlugins` | Browse marketplace | N/A |
| `Chat: Install Plugin From Source` (Command Palette) | Full Git repo URL | **No** |
| `chat.pluginLocations` setting | Local filesystem path | Any path |
| `chat.plugins.marketplaces` entry with `git-subdir` | Marketplace `source` object | **Yes** (via `git-subdir`) |

**From the official doc (agent-plugins page):**
> "Enter a Git repository URL (for example, `https://github.com/rwoll/markdown-review`) and VS Code clones and installs the plugin."

This is a full repository URL with no subdirectory support.

#### Subdirectory support — marketplace `git-subdir` source

Subdirectory installation **is** supported, but only via a marketplace
entry's `source` field in `marketplace.json`:

```json
{
  "name": "my-plugin",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/acme-corp/monorepo.git",
    "path": "tools/claude-plugin",
    "ref": "main"
  }
}
```

This requires setting up a marketplace repository with a `marketplace.json`
file and registering it via `chat.plugins.marketplaces` in VS Code settings.
Users cannot install from a subdirectory via a direct URL or the Command
Palette Install from Source flow.

---

### 3. Additional Findings Relevant to Packaging the Template as a Plugin

#### Plugin directory structure (auto-discovery)

VS Code/Claude Code auto-discovers components at the plugin root if no manifest
is present (or if manifest has no component paths):

```
plugin-root/
  plugin.json            ← at root (VS Code) or .claude-plugin/plugin.json (Claude Code)
  skills/
    <skill-name>/
      SKILL.md            ← auto-discovered
  agents/
    reviewer.agent.md     ← auto-discovered
  hooks/
    hooks.json            ← auto-discovered at this path
  .mcp.json               ← auto-discovered
```

#### Instructions and prompts are NOT plugin components

The plugin spec does not include `instructions/` (`.instructions.md` files)
or `prompts/` (`.prompt.md` files) as recognized component types. These are
VS Code workspace customisation files deployed separately, not via plugins.
The official plugin format bundles only: skills, commands, agents, hooks, MCP
servers, LSP servers.

Implication: the `instructions/` and `prompts/` directories in starter-kits
are not automatically deployed when a plugin is installed. They would require
a separate mechanism (e.g., VS Code workspace recommendations or manual
placement in `.github/`).

#### Marketplace registration is the canonical install path

For the template to be installable as a plugin from a monorepo subdirectory,
the recommended path is:
1. Create a `marketplace.json` in a dedicated marketplace repo (or this repo)
2. List each starter-kit as a `git-subdir` source entry
3. Register via `chat.plugins.marketplaces` or publish the marketplace to
   `copilot-plugins` / `awesome-copilot`

#### `chat.pluginLocations` for local development

For local testing, the `chat.pluginLocations` VS Code setting can point
directly at any directory — including `starter-kits/typescript/`:

```json
"chat.pluginLocations": {
  "/path/to/copilot-instructions-template/starter-kits/typescript": true
}
```

---

### 4. Gaps Between Current 4-Field `plugin.json` and the Spec

Current starter-kit `plugin.json` (all 8 kits follow this pattern):

```json
{
  "name": "typescript-starter-kit",
  "displayName": "TypeScript Starter Kit",
  "description": "...",
  "version": "1.0.0"
}
```

| Issue | Severity | Detail |
|-------|----------|--------|
| `displayName` is not in the spec | Low | Undocumented field, silently ignored. Display name is not a plugin concept — the `name` field is public-facing. |
| Skills auto-discovery should work | None | `skills/<name>/SKILL.md` structure matches the spec exactly. |
| `instructions/` not deployed by plugin | Medium | `.instructions.md` files will not be installed when the plugin is installed. No plugin mechanism exists for these. |
| `prompts/` not deployed by plugin | Medium | `.prompt.md` files will not be installed when the plugin is installed. No plugin mechanism exists for these. |
| No `author`, `license`, `keywords`, `category` | Low | These are optional but improve marketplace discoverability. |
| No component path declarations | Low | Auto-discovery covers `skills/`; explicit paths not required. |
| `engines.vscode` not needed | N/A | Confirmed absent from all starter-kits — correct as-is. |
| `publisher` not needed | N/A | Confirmed absent from all starter-kits — correct as-is. |
| `contributes` not needed | N/A | Confirmed absent from all starter-kits — correct as-is. |

---

## Recommendations

1. **Remove `displayName`** from all starter-kit `plugin.json` files — it is
   not in the spec and will be silently ignored.

2. **Add `category`, `keywords`, `license`** for marketplace discoverability.

3. **Accept the instructions/prompts gap** — these files serve VS Code
   workspace customisation (placed in `.github/`), not the plugin install
   flow. Document this clearly: the starter-kit plugin installs skills only;
   instructions and prompts are deployed separately via the setup workflow.

4. **For subdirectory install** across kits: create a `marketplace.json` at
   the repo root (or a dedicated marketplace repo) using `git-subdir` source
   entries for each kit. Register the marketplace via
   `chat.plugins.marketplaces`.

5. **The `vscode://chat-plugin/install?source=…` URL does not appear to be
   a documented handler.** Do not rely on it. Use marketplace registration or
   `chat.pluginLocations` for local workflows.

---

## Gaps / Further Research Needed

- Whether VS Code's "Install from Source" UI will eventually support the
  `git-subdir` pattern (currently only for marketplace entries).
- Whether VS Code has a plan to add `instructions` and `prompts` as plugin
  component types (not in the spec as of v1.114).
- The exact `vscode://chat-plugin/install` URL scheme (if it exists) — no
  official documentation found.
