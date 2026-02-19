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
3. Ensure CI passes locally before pushing:
   - VERSION is valid semver
   - CHANGELOG has an `[Unreleased]` section and an entry for the current VERSION
   - All required files are present
   - `copilot-instructions.md` has §1–§11
   - README docs-table links resolve
   - No merge-conflict markers
   - Markdown lint passes
4. Update `CHANGELOG.md` under `[Unreleased]` with a description of your change.
5. Open a PR — the [PR template](.github/PULL_REQUEST_TEMPLATE.md) will guide you through the checklist.

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

## Code of conduct

Be respectful, constructive, and inclusive. We're all here to make AI-assisted development better.
