---
name: compress-prose
description: Tighten prose by shortening sentences, trimming repetition, and reducing token-heavy wording without losing required meaning
compatibility: ">=1.4"
---

# Compress Prose

> Skill metadata: version "1.0"; license MIT; tags [writing, brevity, docs, compression, editing]; compatibility ">=1.4"; recommended tools [codebase, editFiles].

Tighten prose so it is shorter, clearer, and cheaper in tokens while preserving
the instructions, facts, and user-visible meaning that must not drift.

## When to use

- The user asks to shorten text, trim a document, compress language, or reduce token-heavy wording.
- A Markdown or prose file is correct but padded with repetition, throat-clearing, or long sentences.
- You need a tighter variant of existing documentation without changing policy or behavior.

## When NOT to use

- The text is legal, contractual, safety-critical, or otherwise sensitive to wording drift.
- The text is machine-parsed or depends on exact formatting, token strings, or placeholders.
- The task actually needs a rewrite, reorganization, or behavior change rather than compression.

## Steps

1. Identify the compression target and the invariants. List what must stay exact: commands, paths, versions, code blocks, numbered procedures, and normative requirements.
2. Remove duplication before shortening sentences. Cut repeated caveats, repeated summaries, and redundant headings first.
3. Tighten sentence structure. Prefer one direct clause over stacked qualifiers, replace filler with concrete verbs, and collapse obvious phrasing like "in order to" to "to".
4. Keep familiar Markdown. Prefer standard headings, bullets, and tables over exotic shorthand or custom notation that may save file tokens but increase reading and retrieval cost.
5. Preserve scannability. Keep section intent obvious, avoid dense walls of text, and keep lists only when the content is genuinely list-shaped.
6. Re-read for drift. Confirm the shorter version still says the same thing, keeps all hard requirements, and does not weaken any constraint.
7. Verify the result with a before-and-after check: the new text is shorter, still accurate, and still easy to act on.

## Verify

- [ ] Commands, file paths, versions, and required keywords are unchanged where exact wording matters
- [ ] Repetition was removed before sentence-level tightening
- [ ] The compressed text is shorter without introducing ambiguity
- [ ] Familiar Markdown structure was preserved
- [ ] No behavioral, policy, or semantic drift was introduced