---
name: extension-review
description: Audit VS Code extensions against the current project stack and recommend keep/add/remove actions
compatibility: ">=3.2"
---

# Extension Review

> Skill metadata: version "1.1"; license MIT; tags [extensions, vscode, audit, tooling, review, plugins]; compatibility ">=3.2"; recommended tools [codebase, fetch, runCommands].

Review the current project's VS Code extensions and recommend what to keep, add, or remove based on the actual stack in the repository.

## When to use

- User asks to "review extensions", "check my extensions", or "audit VS Code extensions"
- User wants extension recommendations or wants to find duplicates/stale extensions

## When NOT to use

- User knows the exact extension to install
- Task is to edit `.vscode/extensions.json` directly without audit

## Steps

1. **Get the installed list** - Try to enumerate extensions automatically using the `runCommands` tool:

   ```bash
   code --list-extensions --show-versions | sort
   ```

   If the command fails (e.g., `code` CLI not on PATH or terminal unavailable), fall back to asking the user to run `code --list-extensions | sort` and paste the output.

2. **Profile check** — Detect repo-specific VS Code Profile. If on Default Profile, recommend creating a dedicated Empty Profile. If profile detection is limited, note it and recommend repo-specific profile.

3. **Read workspace recommendations** — Inspect `.vscode/extensions.json` and `.vscode/settings.json`.

4. **Detect the stack** — Scan repo for language, runtime, linter, formatter, test, and config signals.

5. **Audit agent plugins** — `@agentPlugins` in Extensions view. Check for overlap with extensions, MCP server duplication, and stack relevance.

6. **Check MCP-contributing extensions** — Cross-reference `.vscode/mcp.json` with extension-contributed servers for duplicates.

7. **Compare installed vs needed** — Build: **Keep** (relevant), **Recommended additions** (needed for stack), **Consider removing** (irrelevant/duplicate/deprecated).

8. **Unknown stacks** — Research Marketplace; only recommend if installs >100k, rating ≥4.0, updated within 12 months.

9. **Persist new mappings** — Append to `.copilot/workspace/knowledge/TOOLS.md` under `Extension registry`.

10. **Present the report** - Use this structure:

    ```markdown
    ## Extension Review - <project>

    ### Keep
    - `publisher.extension` - why it still fits

    ### Recommended additions
    - `publisher.extension` - what it provides | why needed
      Install: Ctrl+P -> `ext install publisher.extension`

    ### Consider removing
    - `publisher.extension` - duplicate / unused language / deprecated

    ### Agent plugins
    - `plugin-name` - keep / remove / overlaps with `publisher.extension`

    ### Notes
    - stack signals discovered
    - unknown stacks researched
    - extension registry updates made
    - MCP server overlaps identified
    ```

11. **Wait** - Do not modify `.vscode/extensions.json` or install/uninstall anything until the user explicitly asks.

## Verify

- [ ] Installed extensions obtained (auto-detected or user-provided)
- [ ] Profile status checked; repo-specific profile recommended if needed
- [ ] Agent plugins audited for overlap and relevance
- [ ] MCP-contributing extensions cross-referenced
- [ ] Every recommendation tied to actual stack signal
- [ ] Unknown-stack recommendations passed quality gate
- [ ] No extensions installed/uninstalled/written automatically
