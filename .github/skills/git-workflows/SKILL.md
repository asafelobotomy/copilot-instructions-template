---
name: git-workflows
description: Step-by-step git workflows for commit, push, tag/release, branch, sync, stash, merge-conflict, and pull-request operations — including MCP tool preferences
compatibility: ">=2.0"
---

# Git Workflows

> Skill metadata: version "1.0"; license MIT; tags [git, commit, push, branch, merge, stash, pr, release]; compatibility ">=2.0"; recommended tools [runCommands, editFiles, askQuestions, githubRepo].

Detailed per-operation procedures for the Commit agent. Load this skill at the start of any git lifecycle operation.

## Commit workflow

1. Run `git status` and `git diff --cached --stat` to understand what is staged.
2. If nothing is staged, run `git diff --stat` to see unstaged changes. Ask the user which files to stage, or stage all if they say "all" or "everything".
3. If the plan involves more than one commit, run the multi-commit mode gate (in agent body) before proceeding.
4. Run the preflight workflow for the candidate commit scope.
5. Apply the message format from `commit-style.md`. If that file specifies Conventional Commits, load the `conventional-commit` skill.
6. Unless pre-approved by the mode gate, present the commit message using `askQuestions` before committing:

   ```yaml
   header: "Commit: <type>(<scope>): <subject>"
   question: "Approve this commit message, or type an edited version below."
   allowFreeformInput: true
   options:
     - label: "Approve as-is"
       recommended: true
     - label: "Skip this commit"
       description: "Leave these files staged but do not commit them now"
     - label: "Abort all remaining commits"
       description: "Stop here; keep what is already committed"
   ```

   - **Approve as-is**: proceed with the displayed message.
   - **Freeform text**: treat it as the replacement message and proceed.
   - **Skip this commit**: unstage these files, record them as skipped, continue to the next commit.
   - **Abort all remaining commits**: stop immediately, report what was committed and what was not.

7. Verify the per-commit checklist (in agent body) before executing.
8. Execute the commit:
   - **Subject only** (no body): `git commit -m "<subject>"` or `mcp_git_git_commit`.
   - **Subject + body**: Prefer `mcp_git_git_commit` (handles newlines safely). When using the terminal, write the message to a temp file and use `git commit -F <tmpfile>`, then remove the file. Do NOT use `git commit -m "subject\n\nbody"` — shell newline escaping is unreliable.
   - **Fixup/squash**: When `squash-fixups: true` is set in `commit-style.md`, offer `git commit --fixup=<hash>` (absorbs silently) or `git commit --squash=<hash>` (prompts at rebase). These work with `git rebase -i --autosquash`.
9. After a successful commit, print the short hash and subject: `[<hash>] <subject>`.

## Push workflow

1. Run `git log origin/<branch>..HEAD --oneline` to show unpushed commits.
2. Run the preflight workflow for the unpushed diff.
3. Confirm the target branch and remote, then ask for push authorisation via `askQuestions`:

   ```yaml
   header: "Push to origin/<branch>"
   question: "Ready to push N commit(s) to origin/<branch>. Confirm?"
   allowFreeformInput: false
   options:
     - label: "Push now"
       recommended: true
     - label: "Abort — keep commits local"
       description: "Stop here; commits remain local and can be pushed later"
   ```

4. Execute `git push` (or `git push --set-upstream origin <branch>` for new branches) only after the user selects **Push now**.
   - Force-push: use `git push --force-with-lease` by default. Only use `git push --force` if the user explicitly requests it after being warned that `--force-with-lease` is the safer option.
5. Report the result.

## Tag / Release workflow

1. Confirm the version string using `askQuestions`:

   ```yaml
   header: "Tag / Release: v<version>"
   question: "Create annotated tag v<version> on the current commit and push to origin?"
   allowFreeformInput: false
   options:
     - label: "Confirm — create tag and push"
       recommended: true
     - label: "Abort — no tag created"
   ```

2. For a tag only: `git tag -a v<version> -m "<subject>"` → `git push origin v<version>`.
3. For a GitHub release: show a draft of the release title and body for approval using `askQuestions`, then use `gh release create`.
4. Never amend published commits or force-push without explicit user authorisation and a warning.

## Branch workflow

1. **List**: `git branch -a` or `mcp_git_git_branch` to show local and remote branches.
2. **Create**: `git checkout -b <name>` from the current HEAD, or from a specified base.
3. **Switch**: `git checkout <branch>`. If there are uncommitted changes, offer to stash first.
4. **Delete**: confirm the branch name and whether it has been merged. Use `git branch -d` (safe) by default. Only use `-D` (force) with explicit user approval.
5. After any branch operation, show the current branch: `git branch --show-current`.

## Sync workflow

1. **Fetch**: `git fetch origin` — updates remote tracking refs without modifying the working tree.
2. **Pull** (default merge): `git pull origin <branch>`. If `commit-style.md` sets `pull-strategy: rebase`, use `git pull --rebase` instead.
3. **Rebase**: `git rebase <target>`. Warn that this rewrites history. On shared branches, confirm before proceeding.
   - Conflicts: enter the Merge conflict resolution workflow below.
   - Abort: `git rebase --abort`. Continue: `git rebase --continue`.
4. **Merge**: `git merge <source>`. Use `--no-ff` when the user wants an explicit merge commit.
   - Conflicts: enter the Merge conflict resolution workflow below.
5. **Cherry-pick**: `git cherry-pick <commit>`. Show the commit details before applying. Conflicts: enter the Merge conflict resolution workflow below.
6. After any sync, show `git log --oneline -5` so the user can verify the result.

## Stash workflow

1. **Save**: `git stash push -m "<description>"`. Generate the description from the current diff summary if not provided.
2. **List**: `git stash list` to show all stashed entries.
3. **Apply**: `git stash pop` (default, removes from stash) or `git stash apply` (keeps in stash). Ask which entry if multiple exist.
4. **Drop**: `git stash drop stash@{n}`. Confirm before dropping.

## Merge conflict resolution workflow

Enter when a merge, rebase, cherry-pick, or pull produces conflicts.

1. Run `git diff --name-only --diff-filter=U` to list conflicted files.
2. For each conflicted file, show the conflict markers and surrounding context.
3. Use `askQuestions` to present resolution options per file:
   - Accept incoming (theirs)
   - Accept current (ours)
   - Manual edit (open file for editing)
   - Use `git blame` to understand authorship of each side
4. After resolving all conflicts, stage the resolved files with `git add`.
5. Continue the interrupted operation: `git merge --continue`, `git rebase --continue`, or `git cherry-pick --continue`.
6. To abandon: `git merge --abort`, `git rebase --abort`, or `git cherry-pick --abort`.

## Pull Request workflow

1. **Create**: confirm the source branch, target branch, title, and body. Use `mcp_github_create_pull_request` or `gh pr create`.
   - Auto-fill the title from the most recent commit subject if not specified.
   - Check for `.github/pull_request_template.md` first; use it as the body skeleton. If absent, auto-fill from the commit log between target and source branches.
   - Confirm draft or ready status:

     ```yaml
     header: "Pull Request: <title>"
     question: "Create this PR as draft or ready for review?"
     allowFreeformInput: false
     options:
       - label: "Ready for review"
         recommended: true
       - label: "Draft"
         description: "Mark as draft — not yet ready for review"
     ```

2. **Update**: use `mcp_github_update_pull_request` to change title, body, reviewers, or draft status.
3. **Sync branch**: use `mcp_github_update_pull_request_branch` to update the PR branch with the latest base.
4. Never merge a PR without explicit user instruction.

## Commit splitting

When asked to "split into multiple commits" or "organise my commits", use `git add -p` interactive staging via the terminal to group changes into logical commits with clear messages.

## MCP tool preferences

Prefer MCP tools over raw terminal commands when both are available.

| Operation | Preferred MCP tool | Terminal fallback |
|-----------|-------------------|-------------------|
| Status | `mcp_git_git_status` | `git status` |
| Stage | `mcp_git_git_add` | `git add` |
| Unstage | `mcp_git_git_reset` | `git reset` |
| Diff (staged) | `mcp_git_git_diff_staged` | `git diff --cached` |
| Diff (unstaged) | `mcp_git_git_diff_unstaged` | `git diff` |
| Commit | `mcp_git_git_commit` | `git commit` |
| Log | `mcp_git_git_log` | `git log` |
| Show | `mcp_git_git_show` | `git show` |
| Push | — | `git push` |
| Branch | `mcp_git_git_branch` | `git branch` |
| Checkout | `mcp_git_git_checkout` | `git checkout` |
| Stash | — | `git stash` |
| Blame | — | `git blame` |
| Commit split | — | `git add -p` |
| Merge conflicts | `get_changed_files` (merge-conflicts) | `git diff --name-only --diff-filter=U` |
| PR create | `mcp_github_create_pull_request` | `gh pr create` |
| PR update | `mcp_github_update_pull_request` | `gh pr edit` |

For rebase, merge, cherry-pick, fetch, and pull — no MCP tools exist; use terminal commands.
