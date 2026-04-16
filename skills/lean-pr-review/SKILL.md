---
name: lean-pr-review
description: Review a pull request using Lean waste categories and structured severity ratings
compatibility: ">=1.4"
---

# Lean PR Review

> Skill metadata: version "1.1"; license MIT; tags [review, pull-request, lean, kaizen, code-review]; compatibility ">=1.4"; recommended tools [codebase, githubRepo].

Perform a structured pull request review using §5 Review Mode conventions and §6 waste categories.

## When to use

- User asks to "review this PR", "review these changes", or "check my diff"
- Review agent hands off a PR-scoped task, or PR needs quality gate before merge

## When NOT to use

- Full architectural review needed (use Review Mode with full codebase)
- Single-line typo fix (just approve)

## Steps

1. **Get the diff** — Read PR diff or changed files. Locally: `git diff main...HEAD`.

2. **Scan each changed file** — Read full files (not just hunks) for context.

3. **Classify each finding** — `[severity] | [file:line] | [waste category] | [description]`

   Severity: `critical` (blocks merge), `major` (fix before merge), `minor` (nice to fix), `advisory` (informational).

   Waste categories (§6) — full list W1–W16; most common in PR review:

   | Code | Name | Typical PR signal |
   |------|------|------------------|
   | W1 | Overproduction | Dead code, unused exports, features not yet needed |
   | W2 | Waiting | Blocking sync calls, missing timeouts |
   | W3 | Transport | Unnecessary data copying, prop drilling 3+ levels |
   | W4 | Over-processing | Abstraction for its own sake, premature generalisation |
   | W5 | Inventory | Large WIP; changes that could be split into smaller PRs |
   | W6 | Motion | Logic scattered across many files without justification |
   | W7 | Defects | Bugs, type errors, missing error handling, test failures |
   | W8 | Unused talent | Missing tests, missing automation, repetitive manual patterns |
   | W11 | Hallucination rework | Phantom API usage, methods that don't exist, incorrect assumptions |
   | W14 | Model-task mismatch | Overly complex solution to a trivial problem |

   For W9–W10, W12–W13, W15–W16 definitions, see §6 of `.github/copilot-instructions.md`.

4. **Check test coverage** — New/changed behaviour must have tests. Flag untested paths as `major | W7`.

5. **Check baselines** — §2 baselines: file LOC limits, dependency budget, zero type errors.

6. **Produce the report** — Format as:

   ```markdown
   ## PR Review — <PR title or branch name>

   ### Summary
   <1–2 sentence overview of the changes and their quality>

   ### Findings (<N> total: <critical> critical, <major> major, <minor> minor, <advisory> advisory)

   #### Critical
   - [critical] | [file:line] | [W7] | <description>

   #### Major
   - [major] | [file:line] | [W4] | <description>

   #### Minor
   - [minor] | [file:line] | [W1] | <description>

   #### Advisory
   - [advisory] | [file:line] | [W8] | <description>

   ### Verdict
   <APPROVE / REQUEST CHANGES / COMMENT>
   ```

7. **Wait** — Do not apply fixes. Present the report and wait for the user to decide what to address.

## Verify

- [ ] Every finding has all four fields: severity, file:line, waste category, description
- [ ] Critical findings are genuinely blocking (not inflated)
- [ ] Test coverage was checked for all new behaviour
- [ ] Baseline breaches are flagged
- [ ] Report ends with a clear verdict
