# Extension Review Guide

> **Audience**: humans. This explains the Extension Review feature in `.github/copilot-instructions.md §2` in plain English.
> For the machine-readable protocol, see [§2 — Operating Modes → Extension Review](../.github/copilot-instructions.md).

---

## What is Extension Review?

Extension Review is a capability built into the Lean/Kaizen template that lets Copilot audit your VS Code extensions for a specific project — recommending what to add, what to remove, and researching anything it doesn't recognise — without auto-installing anything.

Think of it as a code review, but for your extension list.

---

## How to trigger it

Say any of the following in a Copilot chat:

- *"Review extensions"*
- *"Check my extensions"*
- *"Audit VS Code extensions"*
- *"What extensions should I install?"*
- *"Do I have the right extensions?"*
- *"Check for missing extensions"*
- *"Recommend extensions for this project"*

---

## What Copilot needs from you first

Copilot chat **cannot read your installed extensions directly**. Before it can audit, it asks you to:

1. Run this in a terminal:
   ```
   code --list-extensions | sort
   ```
2. Paste the output into the chat.

Copilot will also automatically read `.vscode/extensions.json` and `.vscode/settings.json` if they exist.

---

## What Copilot does

1. **Reads your extension list** from what you pasted + `.vscode/extensions.json`
2. **Detects your stack** from project files: language, runtime, linters, formatters, test framework, config files (`oxlint.json`, `pyproject.toml`, `Cargo.toml`, `biome.json`, etc.)
3. **Matches against the built-in stack detection table** — curated mappings of stack signals to recommended extensions
4. **For unknown stacks**, searches the VS Code Marketplace, evaluates by install count (>100k), rating (≥4.0), and recency (updated within 12 months), then:
   - Adds qualifying extensions to the report
   - **Persists the new mapping** to `.copilot/workspace/TOOLS.md` under "Extension registry" so future audits in this project already know about it
5. **Presents a structured report** in the chat window:
   - ✅ **Keep** — installed extensions that are relevant and useful
   - ➕ **Recommended additions** — missing but needed, with one-line install commands
   - ❌ **Consider removing** — installed extensions that are irrelevant, redundant, or deprecated
6. **Waits** — does nothing until you act on the recommendations

---

## What Copilot will NOT do

- Auto-install or uninstall extensions
- Modify `.vscode/extensions.json` without being explicitly asked
- Recommend extensions with install count <100k, rating <4.0, or last updated >2 years ago (for unknown stacks)
- Recommend extensions that target languages not present in your project

To write an updated `.vscode/extensions.json`, say: *"Apply these changes"* or *"Write the updated extensions.json"*

---

## Built-in stack detection table

| Language / Tool | VS Code extension(s) |
|----------------|----------------------|
| Bash / Shell | `timonwong.shellcheck` · `foxundermoon.shell-format` |
| JS / TS (ESLint) | `dbaeumer.vscode-eslint` · `esbenp.prettier-vscode` |
| JS / TS (Oxc) | `oxc.oxc-vscode` *(covers both oxlint **and** oxfmt — one extension)* |
| JS / TS (Biome) | `biomejs.biome` |
| Python | `ms-python.python` · `charliermarsh.ruff` |
| Rust | `rust-lang.rust-analyzer` · `tamasfe.even-better-toml` |
| Go | `golang.go` |
| C# / .NET | `ms-dotnettools.csharp` |
| Java | `vscjava.vscode-java-pack` |
| Docker | `ms-azuretools.vscode-docker` |
| Vue | `Vue.volar` |
| Svelte | `svelte.svelte-vscode` |
| Markdown (doc-heavy) | `yzhang.markdown-all-in-one` |
| CSS / SCSS / Less | `stylelint.vscode-stylelint` |
| YAML (schemas, k8s, Actions) | `redhat.vscode-yaml` |
| TOML (non-Rust) | `tamasfe.even-better-toml` |

> This table grows over time. When Copilot discovers and validates a new stack mapping during an audit, it appends it to `.copilot/workspace/TOOLS.md` under "Extension registry", making future audits in that project smarter without modifying this template.

---

## How unknown stacks are handled

1. Copilot detects a tool, language, or framework not in the built-in table
2. Searches the VS Code Marketplace for matching extensions
3. Filters by quality: install count >100k · rating ≥4.0 · updated within 12 months
4. Includes qualifying extensions in the **➕ Recommended additions** section
5. Appends the new `stack → extension` mapping to `.copilot/workspace/TOOLS.md` under **"Extension registry"**

This means the more extension audits you run, the more the agent learns about your specific technology choices.

---

## Applying recommendations

| Action | How |
|--------|-----|
| Install an extension | `Ctrl+P` → type `ext install publisher.extension-id` |
| Uninstall an extension | Extensions view → right-click extension → Uninstall |
| Write updated `extensions.json` | Tell Copilot: *"Apply these changes"* or *"Write the updated extensions.json"* |

---

*See also: `AGENTS.md` (all trigger phrases) · `docs/INSTRUCTIONS-GUIDE.md` (full instructions guide) · `.github/copilot-instructions.md §2` (machine-readable protocol)*
