---
name: agentic-workflows
description: Set up and manage GitHub Actions workflows that use Copilot coding agents for automated PR handling and issue resolution
compatibility: ">=3.2"
---

# Agentic Workflows

> Skill metadata: version "1.0"; license MIT; tags [github-actions, automation, ci, agents, pull-requests]; compatibility ">=3.2"; recommended tools [codebase, editFiles, runCommands, githubRepo].

Set up GitHub Actions workflows that invoke Copilot coding agents to automate issue resolution, PR creation, and code review via GitHub events.

## When to use

- User asks to "automate issue handling", "set up agentic workflows", or "use Copilot in CI"
- User wants agents responding to GitHub events (issues, PRs, comments)

## When NOT to use

- Interactive Copilot chat (default experience, not a workflow)
- Fixing a failing CI pipeline — use **fix-ci-failure** skill
- Non-GitHub-Actions CI

## Prerequisites

- GitHub Copilot enabled for the repository/organization
- Repository uses GitHub Actions
- `copilot-setup-steps.yml` exists (provides agent environment)
- Workflow permissions configured (`contents: write`, `pull-requests: write`, `issues: read`)

## Concepts

### Copilot coding agent

Headless Copilot session triggered by a workflow. Reads issue/event context, plans a fix, implements it, and opens a PR using a Codex-class model.

### copilot-setup-steps.yml

Reusable workflow configuring the agent's environment (runtime, deps, tools). Runs before the agent. Template at `template/copilot-setup-steps.yml`.

### Event triggers

| Trigger | Use case |
|---------|----------|
| `issues.labeled` | Auto-assign agent when a specific label is added |
| `issue_comment.created` | Agent responds to a command comment (e.g., `/fix`) |
| `pull_request.opened` | Auto-review new PRs |
| `workflow_dispatch` | Manual agent invocation |

## Steps

1. **Verify setup steps exist** — Check that `.github/workflows/copilot-setup-steps.yml` exists. If not, fetch and write it:

   ```text
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/copilot-setup-steps.yml
   ```

2. **Choose the trigger pattern** — Ask the user which event should invoke the agent:

   | Pattern | Workflow trigger | Agent receives |
   |---------|-----------------|----------------|
   | Label-based | `issues.labeled` | Issue body and comments |
   | Comment-based | `issue_comment.created` | Comment text and issue context |
   | PR review | `pull_request.opened` | PR diff and description |
   | Manual | `workflow_dispatch` | User-provided inputs |

3. **Create the workflow** — Write `.github/workflows/copilot-agent.yml`:

   ```yaml
   name: Copilot Agent
   on:
     issues:
       types: [labeled]

   jobs:
     agent:
       if: github.event.label.name == 'copilot'
       runs-on: ubuntu-latest
       permissions:
         contents: write
         pull-requests: write
         issues: read
       steps:
         - uses: actions/checkout@v4
         - uses: ./.github/workflows/copilot-setup-steps.yml
         # The Copilot coding agent handles the rest automatically
   ```

   Adjust the trigger and condition based on the user's choice in step 2.

4. **Configure guardrails** — Agent inherits `.github/copilot-instructions.md` automatically. Add label filter, least-privilege `permissions`, and optional `concurrency` group.

5. **Test** — Create a test issue, apply trigger label/comment, verify in Actions tab.

6. **Document** — Add trigger phrase and label to `AGENTS.md`.

## Security considerations

- Never grant `permissions: write-all` — scope exactly
- Restrict label permissions to prevent unauthorized invocations
- Review agent PRs before merging — automated ≠ trusted
- Consider branch protection requiring human approval

## Waste categories

| Risk | Waste code | Mitigation |
|------|-----------|------------|
| Agent runs on irrelevant issues | W1 Overproduction | Use specific labels and filters |
| Agent waits for human review | W2 Waiting | Enable auto-merge for low-risk changes only |
| Duplicate agent runs | W5 Inventory | Add `concurrency` groups |
| Over-trusting agent output | W16 Over-trust | Require human review on all agent PRs |
