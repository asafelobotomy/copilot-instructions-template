# Setup Guide

Use this guide when you want to install the template into a consumer project, verify that the setup path is valid, or phrase the request so Copilot can route it quickly.

## Use These Trigger Phrases

These exact phrases are the highest-signal entry points:

- `Install the copilot-instructions-template plugin`
- `Setup from asafelobotomy/copilot-instructions-template`
- `Set up this project`
- `Update your instructions`
- `Restore instructions from backup`
- `Factory restore instructions`

Use the install phrase when the plugin is not installed yet. Use `Set up this project` after the plugin is already available in the workspace.

## Install Through The Plugin Marketplace

This is the supported default path.

1. Open VS Code.
2. Open Chat and run `Chat: Install Plugin`.
3. Search for `copilot-instructions-template`.
4. Install the plugin.
5. Reload VS Code if the Setup agent does not appear immediately.
6. Tell Copilot `Set up this project`.

The Setup agent then runs the interview, writes `.github/copilot-instructions.md`, installs companion files, and records the installed version in `.github/copilot-version.md`.

## Use Manual Copilot Bootstrap

Use this path when the marketplace entry is unavailable or you are testing the plugin from source. This is still plugin-based setup. It is not a manual copy-files workflow.

### Install From Source

1. Open VS Code.
2. Run `Chat: Install Plugin From Source`.
3. Enter the full repository URL:

```text
https://github.com/asafelobotomy/copilot-instructions-template
```

4. Reload VS Code if needed.
5. Tell Copilot `Set up this project`.

### Use A Local Plugin Path

Use this only for local development or local testing of the template.

Add the repo root to your VS Code settings:

```json
{
  "chat.pluginLocations": {
    "/absolute/path/to/copilot-instructions-template": true
  }
}
```

Then reload VS Code and tell Copilot `Set up this project`.

For local plugin paths, prefer repo-relative entries for workspace-installed starter kits. Do not commit machine-specific home-directory paths.

## Choose Ownership Mode During Setup

The setup interview asks how to deliver agents, skills, and hooks.

- `Plugin-backed`: keep agents, skills, and hooks in the plugin. This is the default.
- `All-local`: copy those surfaces into `.github/` for full local ownership.
- `Ask per surface`: choose plugin-backed or local delivery for each supported surface.

Use `Plugin-backed` unless you need local customization or want to inspect and edit the installed files directly.

## Verify The Result

After setup, confirm these outcomes:

1. `.github/copilot-instructions.md` exists in the consumer project.
2. `.github/copilot-version.md` exists and records the installed version.
3. The Setup trigger `Update your instructions` resolves to the lifecycle update flow.
4. The Agent Debug Panel shows the expected agent, skill, and hook sources.
5. If hooks are local, `.github/hooks/copilot-hooks.json` points at `.github/hooks/scripts/...`.

## Update Or Repair An Existing Install

Use these phrases after the first setup:

- `Update your instructions`
- `Check for instruction updates`
- `Restore instructions from backup`
- `Factory restore instructions`

The Setup agent handles setup, update, backup restore, and factory restore from the same lifecycle entry point. See [AGENTS.md](AGENTS.md) for the full trigger table.