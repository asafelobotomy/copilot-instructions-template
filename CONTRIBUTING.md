# Contributing to copilot-instructions-template

Thanks for your interest in contributing! This project is a Lean/Kaizen Copilot instructions template — contributions that improve the methodology, fix bugs, or enhance documentation are welcome.

---

## Reporting issues

Use the [GitHub issue templates](https://github.com/asafelobotomy/copilot-instructions-template/issues/new/choose):

- **Bug report** — something isn't working as documented
- **Feature request** — propose a new capability or improvement

---

## Pull requests

1. **Fork** the repo and create a branch from `main`.
2. Make your changes — keep commits small and focused.
3. Run all tests locally before pushing:

   ```bash
   bash tests/test-hooks.sh && bash tests/test-guard-destructive.sh && bash tests/test-sync-version.sh && bash tests/test-security-edge-cases.sh
   ```

4. If you changed `VERSION.md`, run the version sync script to propagate the version to all `x-release-please-version` markers:

   ```bash
   bash scripts/sync-version.sh
   ```

5. Update `CHANGELOG.md` under `[Unreleased]` with a description of your change.
6. Open a PR — the [PR template](.github/PULL_REQUEST_TEMPLATE.md) will guide you through the checklist.

---

## What to contribute

**Good first contributions**:

- Fix typos or stale references in docs
- Add a new stack mapping to the Extension Review table (§2)
- Improve a human-readable guide in `docs/`

**Larger contributions** (open an issue first to discuss):

- New sections in `copilot-instructions.md`
- Changes to the setup interview questions
- New agent files or workflow additions
- Changes to the update/restore protocol

---

## Style guide

- All documentation is Markdown, linted by [markdownlint](https://github.com/DavidAnson/markdownlint) (see `.markdownlint.json` for config).
- Keep lines at a reasonable length — MD013 (line length) is disabled.
- Use `§N` notation when referencing instruction sections.
- Placeholder tokens use `{{UPPER_SNAKE_CASE}}`.

---

## Attention budget (copilot-instructions.md)

`.github/copilot-instructions.md` is loaded into the LLM context on **every** interaction. Long instructions cause attention degradation — the agent misses rules buried in the middle. To prevent this, the file has a line budget enforced by CI:

| Scope | Max lines |
|-------|-----------|
| Entire file (§1–§13) | 800 |
| §2 (Operating Modes) | 210 |
| Other §1–§9 sections | 120 each |
| §11–§13 protocol sections | 150 each |
| §10 (project-specific) | No hard limit |

If your change would push a section over budget, extract detail into a skill (`.github/skills/`), path-specific instruction (`.github/instructions/`), or prompt file (`.github/prompts/`) and leave a one-line reference in the main section. See §8 (Attention Budget) in the instructions file for the full rationale.

CI will fail if these limits are exceeded in the **template** file. Consumer projects inherit the budgets but are free to adjust them in §10.

---

## Code of conduct

Be respectful, constructive, and inclusive. We're all here to make AI-assisted development better.
