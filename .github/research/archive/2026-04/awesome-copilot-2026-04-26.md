# Research: github/awesome-copilot — Enhancement Opportunities for copilot-instructions-template

> Date: 2026-04-26 | Agent: Researcher | Status: complete

## Summary

`github/awesome-copilot` is GitHub's official community collection for Copilot customisation resources (agents, skills, instructions, hooks, plugins, agentic workflows). It is also a registered default plugin marketplace for VS Code and the Copilot CLI. Its dominant design choices are: machine-readable resource discovery (`llms.txt`), one-click VS Code install badges on every resource, rich plugin taxonomy with tags and featured status, a Learning Hub of onboarding guides, and a CLI-first install path (`copilot plugin install <name>@awesome-copilot`). Most of these patterns are transferable — at reduced scope — to a single-author template plugin.

## Same-Day Implementation Status

Several findings in this note were implemented in the current branch after the research pass:

- `llms.txt` now enumerates agents, skills, starter-kit manifests, and hook or runtime surfaces as a repo catalog.
- `README.md` and `SETUP.md` now document the `@agentPlugins` recovery path.
- `starter-kits/REGISTRY.json` now carries `featured` and `tags`, and Setup uses that metadata to rank matches.
- `README.md` now includes a hook catalog for all eight lifecycle events.

The remaining recommendations below are the ideas that still need a separate implementation decision.

## Sources

| URL | Relevance |
|-----|-----------|
| <https://github.com/github/awesome-copilot> | Main README — overview, install path, structure |
| <https://awesome-copilot.github.com/llms.txt> | Machine-readable index format |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/docs/README.agents.md> | Install badge pattern |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/docs/README.skills.md> | Bundled assets table, gh CLI install |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/docs/README.plugins.md> | Tags, featured status, `@agentPlugins` filter |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/docs/README.hooks.md> | Hook catalog and event types |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/docs/README.workflows.md> | Agentic workflow format |
| <https://raw.githubusercontent.com/github/awesome-copilot/main/CONTRIBUTING.md> | Quality criteria and exclusion rules |

## What awesome-copilot Emphasises

1. **One-click install badges** — every agent and skill listing has `[![Install in VS Code](badge)](vscode:chat-agent/install?url=...)` deeplinks. No manual UI navigation.
2. **Machine-readable `llms.txt`** — a single file at the website root enumerates every resource by URL, enabling any AI to discover the full catalog without repo exploration.
3. **Plugin marketplace as primary path** — `copilot plugin install <name>@awesome-copilot` is the lead install command. VS Code's `@agentPlugins` Extensions filter is a secondary path.
4. **Learning Hub** — 20+ onboarding guides (building agents, creating skills, hooks, MCP servers, context management). Linked from README and `llms.txt`.
5. **Tags and featured status on plugins** — each plugin entry has a `Tags` field (e.g., `azure, cloud, bicep`) and featured items appear at the top of the list.
6. **Bundled assets visibility** — skill tables include a `Bundled Assets` column listing scripts, templates, and reference files that ship inside the skill folder.
7. **Agentic Workflows as markdown** — `.md` files with YAML frontmatter, compiled to `.lock.yml` GitHub Actions via `gh aw compile`. Triggers: schedule, slash command, issue events.
8. **`gh skill install` CLI** — `gh skill install github/awesome-copilot <skill-name>` installs a skill via GitHub CLI v2.90.0+.
9. **Strict contribution quality bar** — CONTRIBUTING.md explicitly rejects: circumvention of Responsible AI guidelines, remote-source plugins, and content that duplicates model strengths without meaningful uplift.

## Findings

### F1 — VS Code Install Deeplink Badge

Every agent entry in awesome-copilot uses:

```markdown
[![Install in VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF...)](vscode:chat-agent/install?url=https://raw.githubusercontent.com/...)
```

The current README agent table has no deeplinks. Users must find and use `Chat: Install Plugin` manually.

**Gap**: High-friction install path vs one-click.

### F2 — Machine-Readable llms.txt as Resource Index

At research time, `llms.txt` described the repo structure at a high level. The current repo now ships a broader catalog for agents, skills, starter kits, and hook or runtime surfaces. `awesome-copilot.github.com/llms.txt` still remains the reference pattern for explicit resource enumeration.

**Status**: Addressed in the current branch. `MODELS.md` now also states that `sync-models` only owns the model summary table inside `llms.txt`.

### F3 — `@agentPlugins` Extensions Filter

awesome-copilot's plugin README says to open the Extensions search view and type `@agentPlugins`. This is a VS Code built-in filter that surfaces all installed Copilot agent plugins. At research time, the current README and SETUP.md did not mention it.

**Status**: Addressed in the current branch. README and SETUP now document the recovery path.

### F4 — Skill Tags

awesome-copilot plugins carry a `tags` array (e.g., `azure, cloud, infrastructure, bicep, terraform, serverless, architecture, devops`). This enables filtering on the website and the CLI.

The current skills in `skills/` have descriptions but no tags. The workspace-index.json has no tag field. Searching for "security" or "testing" skills requires reading each description.

**Gap**: Tag-free skills reduce signal density for both AI and human navigators.

### F5 — Bundled Assets Column in Skill Tables

awesome-copilot's skills README has a `Bundled Assets` column listing `scripts/`, `references/`, and `assets/` subdirectories. Users can immediately see which skills are "fat" (bundled scripts) vs "lean" (instruction-only).

The current README skill section shows only name and one-line description. The `workspace-index.json` does not expose bundled assets.

**Gap**: Users picking a skill have no visibility into what non-instruction content it ships.

### F6 — Learning Hub / Onboarding Guides

awesome-copilot's Learning Hub covers: building custom agents, creating skills, using hooks, connecting MCP servers, context engineering, the CLI for beginners, and understanding the coding agent. 20+ articles. Linked from README and `llms.txt`.

The current SETUP.md covers only installation. Once the template is installed, users who want to author new skills or agents must read raw agent `.md` files with no guided path.

**Gap**: No guided authoring documentation. Users who want to extend the template (add a skill, write a hook) start from zero.

### F7 — Pre-built Agentic Workflow Files

awesome-copilot ships ready-to-use `.md` agentic workflow files: daily issues report, org health report, stale repo report, OSS release compliance checker, relevance check. These are compiled to `.lock.yml` via `gh aw compile`.

The current `skills/agentic-workflows/SKILL.md` teaches how to use agentic workflows but ships no ready-to-use examples.

**Gap**: The skill teaches the format but doesn't demonstrate it with working examples. A pre-built "weekly repo health" or "session auto-report" workflow would be an immediate value-add.

### F8 — `copilot plugin install` CLI Quickstart

awesome-copilot leads with `copilot plugin install <name>@awesome-copilot`. The current README leads with VS Code UI navigation (`Chat: Install Plugin` → search → install).

**Gap**: Power users and headless/SSH environments have no documented CLI install path. If the plugin is available in any registered marketplace, the CLI command should be the first option.

### F9 — Featured/Priority in REGISTRY.json

awesome-copilot features highlighted plugins at the top of the plugin list (⭐ icon). At research time, `starter-kits/REGISTRY.json` had no priority or featured field, so Setup had no authored ranking signal when multiple kits matched.

**Status**: Addressed in the current branch. `REGISTRY.json` now includes `featured` and `tags`, and Setup prefers featured matches first.

### F10 — Hook Catalog Discoverability

awesome-copilot's hook catalog lists named hooks with event types and bundled assets. At research time, the current repo referenced hooks in `hooks/hooks.json`, but the README had no hook catalog table.

**Status**: Addressed in the current branch. README now includes a hook catalog for the eight lifecycle events.

## Recommendations

### Quick Wins (low effort, high signal)

**QW1 — Add VS Code Install badge to README** (README.md)
Add a `[![Install in VS Code](badge)](vscode:chat-plugin/install?url=...)` deeplink below the Install section header. Pattern from awesome-copilot agent badges, adapted for plugin install. Effort: ~30 min.

**QW2 — Add `@agentPlugins` filter tip to SETUP.md** (Implemented in current branch)
README.md and SETUP.md now include the `@agentPlugins` recovery hint.

**QW3 — Expand llms.txt to enumerate all resources** (Implemented in current branch)
`llms.txt` now enumerates agents, skills, starter kits, and hook or runtime surfaces as repo-local links.

**QW4 — Add `"featured"` and `"tags"` fields to REGISTRY.json** (Implemented in current branch)
`starter-kits/REGISTRY.json` now carries `featured` and `tags`, and the Setup agent uses them when presenting matches.

### Medium Effort

**ME1 — Add Bundled Assets column to skill documentation** (README.md, workspace-index.json)
Audit each skill folder for non-SKILL.md files (scripts, templates, references). Add a `Bundled` column to the README skill table and a `bundledAssets` array to each skill entry in workspace-index.json. Effort: ~2h.

**ME2 — Add skill tags** (workspace-index.json, SKILL.md files)
Add a `tags` array to each skill's metadata in workspace-index.json. This does not require editing SKILL.md files — the index is the canonical catalog. Could be surfaced in the README skill table. Effort: ~1–2h.

**ME3 — Add hook catalog table to README** (Implemented in current branch)
README.md now includes a Hooks section that lists the eight lifecycle events, their primary scripts, and each event's purpose.

**ME4 — Ship 2–3 pre-built agentic workflow files** (new `workflows/` directory)
Add `workflows/weekly-repo-health.md` and `workflows/daily-session-digest.md` as markdown agentic workflow stubs. Update `agentic-workflows` skill to reference them as examples. Effort: ~3–4h.

**ME5 — Add an Authoring Guide** (new `.github/docs/authoring-guide.md` or wiki)
One-page guide covering: how to add a skill, how to write a hook script, how to add a starter kit. This is the "Learning Hub" equivalent at minimal scale — enough to unblock a user who wants to extend the template. Effort: ~2–3h.

### Reject or Be Cautious About

**REJECT — Full companion website with full-text search**
awesome-copilot's website (`awesome-copilot.github.com`) is a community resource for hundreds of contributors. A single-author template does not justify the maintenance overhead of a static site generator, search indexing, and hosting pipeline. The `llms.txt` expansion (QW3) achieves 80% of the discoverability benefit at near-zero cost.

**CAUTION — Community CONTRIBUTING.md model**
awesome-copilot's CONTRIBUTING.md is designed for a community repo accepting third-party submissions. This template is author-controlled. Adding a public CONTRIBUTING.md would imply open submissions are accepted. The quality criteria from CONTRIBUTING.md are worth adopting as internal authoring guidelines, but framed as internal standards rather than community contribution gates.

**CAUTION — `gh skill install` CLI support**
`gh skill install github/awesome-copilot <skill-name>` requires GitHub CLI v2.90.0+ and depends on the skill being in a `github/*` repo. This feature appears to be currently scoped to github-org repositories. Monitor for generalisation but do not document it as an install path for `asafelobotomy/*` until confirmed.

**CAUTION — Marketplace `@` address in CLI**
`copilot plugin install <name>@awesome-copilot` works because awesome-copilot is a registered default marketplace. The current plugin is installed from source URL, not via a named marketplace address. Document the source-URL install path (`copilot plugin install --source https://github.com/asafelobotomy/copilot-instructions-template`) rather than implying a `@` address that may not resolve.

## Discoverability / Searchability Highlights

The two highest-leverage discoverability ideas that would help Copilot or users find the right setup/update path faster:

1. **llms.txt resource enumeration** (QW3): An AI agent that reads `llms.txt` first (before exploring the repo tree) would immediately get the complete skill/agent/starter-kit URL inventory. This is especially important for the Setup agent deciding which starter kit to recommend — it can resolve the question without scanning `starter-kits/*/` directories. This is the highest-ROI single change.

2. **VS Code install badge** (QW1): A user arriving at the GitHub repo sees a badge they can click to install immediately. This eliminates the "open VS Code, find the chat panel, find Chat: Install Plugin, search for the name" path. awesome-copilot uses the URI scheme `vscode:chat-agent/install?url=<raw-url>` for per-agent install; the equivalent for a plugin is `vscode:chat-plugin/install?url=<repo-url>` (verify the exact scheme against current VS Code docs before implementing).

## Gaps / Further Research Needed

- Confirm the exact VS Code URI scheme for plugin install (not per-agent install) — the awesome-copilot pattern uses `vscode:chat-agent/install?url=` but a plugin install deeplink may differ.
- Verify whether `gh skill install` has been generalised beyond `github/*` repos as of GitHub CLI v2.90.0+.
- Check whether the `copilot plugin install --source` flag accepts full GitHub repo URLs for source-URL install path documentation.
