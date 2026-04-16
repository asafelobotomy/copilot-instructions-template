---
name: conventional-commit
description: Write a commit message following the Conventional Commits specification with scope and body
compatibility: ">=1.4"
---

# Conventional Commit

> Skill metadata: version "1.1"; license MIT; tags [git, commit, conventional-commits, changelog, versioning]; compatibility ">=1.4"; recommended tools [codebase, runCommands].

Write a well-structured commit message following the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## When to use

- The user asks to "write a commit message" or "commit these changes"
- Changes are staged and ready to commit
- The user wants consistent, parseable commit history

## When NOT to use

- Project has its own commit format in §10 of Copilot instructions
- Project uses a different convention (check §4 and §10 first)

## Steps

1. **Read the staged changes** — Run `git diff --cached --stat` to see which files changed, then `git diff --cached` for the full diff.

2. **Determine the type** — Choose the most appropriate type:

   | Type | When to use |
   |------|------------|
   | `feat` | A new feature or capability |
   | `fix` | A bug fix |
   | `docs` | Documentation-only changes |
   | `style` | Formatting, whitespace, semicolons — no logic change |
   | `refactor` | Code change that neither fixes a bug nor adds a feature |
   | `perf` | Performance improvement |
   | `test` | Adding or correcting tests |
   | `build` | Build system or external dependency changes |
   | `ci` | CI configuration changes |
   | `chore` | Maintenance tasks that don't modify src or test files |

3. **Determine the scope** — Primary area affected (directory or module name). Omit if change spans many areas.

4. **Write the subject line** — `<type>(<scope>): <imperative summary>`. Imperative mood, lowercase after colon, no period, ≤72 chars.

5. **Write the body** (non-trivial changes): blank line after subject, explain *what* and *why* (not *how*), wrap at 72 chars, reference issues (`Fixes #123`).

6. **Breaking change** (if applicable): `!` after type/scope + `BREAKING CHANGE: <description and migration path>` footer.

7. **Present the message** — Show the complete commit message for user review:

   ```text
   <type>(<scope>): <subject>

   <body>

   <footer>
   ```

8. **Wait for approval** — Present the message and wait. Do not run `git commit` until the user approves or modifies the message.

9. **Execute** — Once the user approves, run:

   ```bash
   git commit -m "<subject>" -m "<body>"
   ```

   For multi-line messages with footers, use a heredoc or a temporary file to avoid shell escaping issues:

   ```bash
   git commit -F - <<'EOF'
   <type>(<scope>): <subject>

   <body>

   <footer>
   EOF
   ```

   Confirm the commit was created: `git log --oneline -1`

## Co-author attribution

VS Code 1.110+ `git.addAICoAuthor` (enabled by default) auto-appends `Co-authored-by: GitHub Copilot`. Check/change in VS Code Settings.

## Verify

- [ ] Type is one of the standard Conventional Commits types
- [ ] Subject line is imperative mood, ≤ 72 characters, no trailing period
- [ ] Body explains what and why (if present)
- [ ] Breaking changes have both `!` marker and `BREAKING CHANGE:` footer
- [ ] The message accurately describes all staged changes
- [ ] `git log --oneline -1` confirms the commit was created
