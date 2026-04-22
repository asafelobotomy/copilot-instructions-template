# Research: GitHub Copilot Bootstrap & Distribution Options

> Date: 2026-04-12 | Agent: Researcher | Status: final

## Summary

GitHub Copilot in VS Code has a clearly preferred native path for distributing
repo-specific customisation bundles: the **Agent Plugin** (preview as of April 2026).
A plugin is a Git-repo-shaped bundle of skills, agents, hooks, and MCP servers that
users install via a single Command Palette action or a workspace recommendation.
The current template's script-bootstrap approach (user triggers a phrase → Copilot
agent fetches raw files from GitHub) is still valid and low-friction for Copilot
users but predates the plugin model. OS-native package formats (.exe/.deb/.dmg,
homebrew, winget) are an engineering dead-end for this use case — they solve the
wrong problem at the wrong level of abstraction.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://code.visualstudio.com/docs/copilot/customization/agent-plugins | Full agent-plugins spec: structure, marketplace, install from source, workspace recommendations |
| https://code.visualstudio.com/docs/copilot/copilot-customization | Overview of all customisation types |
| https://code.visualstudio.com/docs/copilot/customization/custom-agents | Custom agent frontmatter and file locations |
| https://code.visualstudio.com/docs/copilot/customization/agent-skills | Agent Skills open standard, portability across agents |
| https://code.visualstudio.com/docs/copilot/security | Trust boundaries: workspace, extension publisher, MCP server, network domain |
| https://code.visualstudio.com/docs/editor/workspace-trust | Workspace Trust Restricted Mode — disables agents, tasks, debugging |
| https://code.visualstudio.com/docs/devcontainers/create-dev-container | devcontainer.json: postCreateCommand, extension auto-install |
| https://code.visualstudio.com/api/working-with-extensions/publishing-extension | VSIX packaging and Marketplace publishing via vsce |
| https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-template-repository | GitHub template repositories |
| https://github.com/github/copilot-plugins | Official default Copilot plugin marketplace repo |

---

## Findings

### 1 — Platform constraints that matter

**Workspace Trust gate**
VS Code's Workspace Trust model is the primary security boundary.
Restricted Mode (untrusted workspace) disables agents, tasks, and debugging.
Any bootstrap flow that involves running code or scripts must already be in a
trusted workspace. This means:
- Agent-driven bootstrap (the current SETUP.md approach) only works after the
  user has trusted the workspace.
- `.vscode/tasks.json` scripts run but require a trust prompt on first execution.

**Extension publisher trust**
Installing a VSIX (sideloaded or from Marketplace) prompts for publisher trust.
This is a one-time gate per publisher. Once trusted, the extension activates.

**MCP server trust**
Each MCP server entry triggers an individual trust prompt unless it arrives
bundled inside an agent plugin — plugin MCP servers are implicitly trusted when
the plugin is installed.

**Agent sandboxing**
On macOS and Linux (WSL2 on Windows), `chat.tools.terminal.sandbox.enabled`
restricts file system and network access for agent-executed terminal commands.
Any bootstrap script the agent runs is subject to sandbox constraints, including
the `/tmp` read-only restriction (must use `$TMPDIR`).

**Plugin hooks and MCP servers run arbitrary code**
The agent-plugins docs explicitly warn: "Review the plugin contents and publisher
before installing, especially for plugins from community marketplaces." Plugin
MCP servers are started automatically when the plugin is enabled, but are still
subject to filesystem sandbox rules.

**No silent arbitrary downloads**
Copilot cannot silently download and execute binaries. All agent file-write and
terminal-execute actions go through the normal tool-approval flow, which the
user has either session-approved or pre-approved by trust level. This is the
fundamental reason OS package formats add no value: the user must explicitly
consent to every download/execute step anyway.

---

### 2 — Viable distribution approaches, ranked by practicality

#### Tier 1 — Recommend

**A. Agent Plugin (preview, April 2026)**
*Practicality: highest for this repo*

Structure:
```
my-plugin/
  plugin.json              # metadata
  skills/<name>/SKILL.md   # skills
  agents/*.agent.md        # custom agents
  hooks.json               # hook config
  scripts/                 # hook scripts
  .mcp.json                # MCP servers
```

Install path 1 — user invokes:
```
Chat: Install Plugin From Source
→ enter: https://github.com/asafelobotomy/copilot-instructions-template
```
VS Code clones and installs in one step.

Install path 2 — **workspace recommendation** (zero extra friction for team
members):
```jsonc
// .vscode/settings.json
{
  "enabledPlugins": {
    "copilot-instructions-template@asafelobotomy": true
  },
  "extraKnownMarketplaces": {
    "asafelobotomy": {
      "source": { "source": "github", "repo": "asafelobotomy/copilot-instructions-template" }
    }
  }
}
```
When a team member opens the repo and sends their first chat message, VS Code
notifies them to enable the recommended plugin.

Constraints:
- Preview status: schema may change.
- Hooks and MCP servers in the plugin run code — users see a trust prompt on
  first install from a new marketplace.
- Plugin MCP servers bypass the per-server trust prompt, so the plugin itself
  is the trust boundary.
- Plugin-root tokens are format-specific in VS Code: `${CLAUDE_PLUGIN_ROOT}` for Claude format, `${PLUGIN_ROOT}` for OpenPlugin, and no documented equivalent for Copilot format.
  Personal/workspace copilot-instructions.md from SETUP.md is **not** installed
  by the plugin — the plugin supplements a workspace, it does not bootstrap files
  outside the plugin directory.

Summary: the plugin model aligns naturally with this repo's existing structure
(.github/skills/, .github/agents/, .github/hooks/). It adds a first-class
discovery and install path without requiring any new scripting.

---

**B. Script Bootstrap via Copilot Agent (current approach)**
*Practicality: high — already working*

The current SETUP.md approach (user says "Setup from
asafelobotomy/copilot-instructions-template" → Copilot fetches raw files and
writes them to the consumer project) is well-suited to the Copilot-native
audience. Its advantages:
- No external tooling required beyond already-running Copilot.
- Works for initial setup of a project that has no `.github/` yet.
- Full access to `editFiles` to write `.github/copilot-instructions.md`,
  `.vscode/mcp.json`, agents, skills, and hooks.
- Update and rollback flows are already implemented.

Limitations:
- Cannot install Copilot itself — the user must already have it.
- Fetch calls are blocked by the VS Code sandbox until the domain is trusted;
  raw.githubusercontent.com is generally pre-approved.
- Does not persist across uninstalls — the agent writes files, but if the user
  deletes `.github/` the content is gone.

---

#### Tier 2 — Situationally useful

**C. GitHub Template Repository**
*Practicality: medium — best for greenfield projects*

Mark the template repo as a GitHub Template Repository. Users click
"Use this template" in the GitHub UI:
- Creates a new repo with the full `.github/` structure pre-populated.
- No tooling required; works for any new project.
- Copilot customisations (agents, skills, instructions) are present from day 0.

Limitation: does not help users who already have an existing project. Does not
install anything — just copies files. No ongoing sync once deployed.

---

**D. devcontainer**
*Practicality: medium — good for Docker-using teams*

`.devcontainer/devcontainer.json` with:
- `customizations.vscode.extensions`: auto-installs GitHub Copilot extension.
- `postCreateCommand`: runs `bash SETUP.md`-style script or `git clone` of
  the instructions into `.github/`.

Limitations:
- Requires Docker — significant additional dependency.
- "Reopen in Container" is a user-initiated step, not invisible.
- Does not help users who open the project locally without Docker.
- Dev Containers extension itself must be pre-installed.

---

**E. VS Code Extension (VSIX)**
*Practicality: low for this use case*

A full VSIX can contribute commands, activate on workspace open, and write
arbitrary files. It could run the entire SETUP.md flow as an activation
command.

Limitations:
- Requires TypeScript/Node.js extension development, Yeoman scaffolding,
  Azure DevOps publisher account, and ongoing extension maintenance.
- Users must explicitly install from Marketplace or sideload `.vsix`.
- Extension publisher trust prompt on first install.
- Heavy engineering overhead for a task that is already handled by the Copilot
  agent script-bootstrap approach.
- Appropriate only if this repo needs to contribute VS Code UI elements (sidebar
  panels, commands, etc.) — it does not.

---

#### Tier 3 — Not recommended

**F. npm/pip/cargo/homebrew CLI installer**

A `npx copilot-instructions-template init` or `pip install` + CLI approach is
viable technically but loses the Copilot-native feel. It would work for teams
that do not uniformly use VS Code/Copilot. More friction than the agent approach
for the target audience (VS Code + Copilot users).

Homebrew/winget formulae are sensible for binary tools, not for distributing
Markdown and shell script files.

---

**G. OS installers (.exe, .deb, .dmg, .msi)**
*See section 3.*

---

### 3 — Why .exe/.deb-style installers are not a good fit

| Factor | Assessment |
|--------|-----------|
| **Target artefacts** | The template distributes Markdown files, YAML, and shell scripts — not compiled binaries. OS installers are designed for binaries and system libraries. |
| **Trust model mismatch** | VS Code's trust model gates on workspace and publisher trust, not OS-level package signatures. A signed `.deb` does not earn VS Code workspace trust. |
| **Platform multiplication** | Maintaining `.exe` (NSIS/WiX), `.deb`, `.rpm`, `.pkg`/`.dmg`, winget manifest, and homebrew formula for a set of text files has an extremely high maintenance cost with no user-experience benefit. |
| **Installation target** | OS packages install to system paths; the template needs to write into `.github/` inside the consumer's project directory. These are structurally incompatible targets. |
| **Existing ecosystem** | The VS Code + GitHub Copilot agent plugin system and the `git clone` bootstrap script solve the problem with native tooling. |
| **Friction** | Downloading an installer, running it, and trusting a UAC / polkit prompt adds user friction that script-bootstrap and plugin-install do not have. |

Conclusion: OS package formats solve a different problem (system-level binary
distribution). They are the wrong abstraction for distributing text-file-based
developer tooling.

---

### 4 — Opportunities to reduce manual steps (doc-backed)

**4.1 Workspace plugin recommendations (zero-friction team propagation)**
`settings.json` can list `enabledPlugins` and `extraKnownMarketplaces`. When a
new team member opens the workspace and starts a chat session, VS Code notifies
them to enable the recommended plugin. This is the lowest-friction team-wide
distribution path for the plugin model.
Source: agent-plugins docs §"Workspace plugin recommendations"

**4.2 `/init` slash command (project onboarding)**
VS Code Copilot provides `/init` to generate `.github/copilot-instructions.md`
tailored to the open codebase. This could serve as an alternative entry point
for users who find the SETUP.md trigger phrase non-obvious.
Source: copilot-customization overview §"Get started"

**4.3 Parent repository discovery (`chat.useCustomizationsInParentRepositories`)**
For monorepo consumers, enabling this setting means agents, skills, and
instructions at the repo root are discovered without copying them into each
package subfolder. Reduces per-package manual setup.
Source: copilot-customization overview §"Parent repository discovery"

**4.4 devcontainer extension auto-install**
```jsonc
// .devcontainer/devcontainer.json
{
  "customizations": {
    "vscode": {
      "extensions": ["github.copilot", "github.copilot-chat"]
    }
  },
  "postCreateCommand": "bash scripts/bootstrap.sh"
}
```
New contributors using containers get Copilot and the template installed
automatically. No manual trigger phrase required.
Source: devcontainer.json docs

**4.5 Agent plugin `postInstall` hook (if/when it ships)**
The plugin marketplace schema is still evolving (github/copilot-plugins repo
describes hooks and MCP servers as "coming soon" as of April 2026). A
`SessionStart` hook in the plugin could run a bootstrap check on first use.

---

## Recommendations

1. **Package as an agent plugin** alongside the existing SETUP.md bootstrap.
   The plugin covers the ongoing-use case (skills, agents, hooks active in any
   workspace where the plugin is installed). SETUP.md covers the one-time file
   bootstrap (writing `.github/copilot-instructions.md` etc. into the consumer
   project).

2. **Add workspace plugin recommendations** to the template's `.vscode/settings.json`
   so that consumers who use the template automatically propagate the plugin to
   team members via `enabledPlugins`.

3. **Ship a `plugin.json`** at the repo root and wire `.github/skills/`,
   `.github/agents/`, and `.github/hooks/` into it. This makes the repo usable
   as a direct-from-source plugin install target today.

4. **Add a devcontainer** for teams that use Docker. Include Copilot extension
   auto-install + `postCreateCommand` calling the setup script.

5. **Do not pursue OS package formats**. The maintenance-to-benefit ratio is
   extremely poor for this class of artefact.

---

## Gaps / Further research needed

- The `plugin.json` schema is not yet formally documented in VS Code docs.
  Claude Code plugin marketplace documentation (code.claude.com) is the
  current reference. Schema stability should be verified before committing.
- `github/copilot-plugins` marketplace is early-stage (skills only, MCP servers
  and hooks marked "coming soon"). Submitting to the official marketplace may
  have review requirements not yet published.
- Plugin `postInstall` lifecycle event: not confirmed to exist yet. Monitor
  plugin changelog in VS Code release notes.
