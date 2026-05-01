# Research: Agent Scope Control, Bounded Initiative, and the Adjacent-Work Problem

> Date: 2026-05-01 | Agent: Researcher | Status: complete

## Summary

Mature agent instruction sets address scope control through three distinct
layers: a **completion gate** (task ends when the stated request is done),
a **scope-lock rule** (no mid-task expansion), and a **minimal-footprint
principle** (least authority + prefer reversibility). The "adjacent useful
work" problem is handled via explicit checkpoint language, not blanket
prohibition. No published vocabulary uses "bounded initiative" as a term
of art; the closest established term from Anthropic is "minimal footprint".
The existing Lean/Kaizen template already covers scope lock and task-complete
semantics; the one genuine gap is an explicit statement of **when** adjacent
work is acceptable and what "done" means for a single user turn.

---

## Sources

| URL | Relevance |
|-----|-----------|
| <https://www.anthropic.com/engineering/building-effective-agents> | Authoritative guidance: three principles, stopping conditions, checkpoints |
| <https://claudebeat.ai/articles/2026/01/2026-01-01.html> | Summary of Anthropic Jan 2026 model spec — "minimal footprint" definition |
| <https://www.mindstudio.ai/blog/anthropic-vs-openai-vs-google-agent-strategy> | Cross-vendor comparison of autonomy philosophies |
| <https://raw.githubusercontent.com/microsoft/vscode/main/.github/copilot-instructions.md> | Canonical real-world copilot-instructions.md example |
| <https://code.visualstudio.com/docs/copilot/customization/custom-instructions> | VS Code official custom-instructions guidance |
| <https://code.claude.com/docs/en/best-practices.md> | Claude Code best practices — scope-the-task patterns |
| <https://code.claude.com/docs/en/memory.md> | CLAUDE.md authoring guidance — conciseness rule |

---

## Findings by Question

### Q1 — Scope reset on new user turn vs. plan context preservation

**Short answer**: No published instruction set uses explicit per-turn scope
reset language. The pattern is implicit.

**Detail**: The sources surveyed (VS Code custom instructions docs, GitHub
Copilot cloud agent docs, Claude Code best practices, cursor rules community)
do not explicitly distinguish "new turn resets scope" from "prior plan context
is preserved". Instead they rely on two complementary patterns:

- **Scope lock at Plan time**: "Once Plan is set, do not expand scope
  mid-task." (existing template; Anthropic Building Effective Agents
  recommends Plan Mode separation). This implicitly means any new user message
  *re-establishes* the scope because the prior plan is superseded by the new
  request.
- **Plan Mode as an explicit gate**: Claude Code uses a "Plan Mode → confirm
  → act" workflow. The plan is confirmed per task and is not assumed to carry
  across unrelated turns.

**Implication for the template**: The existing `Scope lock` rule already
handles this correctly for multi-step tasks. The missing piece is a short
sentence clarifying that **each new user message establishes a fresh scope**
unless the user explicitly says "continue the plan". This prevents the agent
from carrying forward a stale plan across a conceptually unrelated follow-up.

---

### Q2 — "Do the thing asked, then stop" without a rigid no-initiative rule

**Short answer**: The pattern that works is "complete → report → wait",
not a prohibition. Three distinct formulations appear in mature instruction
sets:

1. **Completion-gate formulation** (VS Code microsoft/vscode):
   > "MANDATORY: Always check for compilation errors before running any tests
   > or validation scripts, or declaring work complete, then fix all
   > compilation errors before moving forward."
   — This defines *what done means* precisely, which implicitly prevents
   continuation beyond that point.

2. **Task-termination + stopping conditions** (Anthropic Building Effective
   Agents):
   > "The task often terminates upon completion, but it's also common to
   > include stopping conditions (such as a maximum number of iterations)
   > to maintain control."
   > "Agents can then pause for human feedback at checkpoints or when
   > encountering blockers."
   — Note: "often terminates upon completion" — completion is the natural
   stopping signal, not a special rule.

3. **Cleanup + handoff** (VS Code microsoft/vscode):
   > "If you create any temporary new files, scripts, or helper files for
   > iteration, clean up these files by removing them at the end of the task."
   — Implies a well-defined task boundary.

**None of these formulations create a rigid no-initiative rule**. They define
a completion state and expect the agent to stop there. The Anthropic Building
Effective Agents article frames it as: when the task is done, the task is
done. Additional work requires a new instruction.

---

### Q3 — YAGNI / "adjacent useful work" — when acceptable vs. when to checkpoint

**Short answer**: Two patterns govern this in practice — "strictly necessary"
gating and "note-for-follow-up" discipline.

**Anthropic Building Effective Agents** frames it as:
> "We recommend finding the simplest solution possible, and only increasing
> complexity when needed. This might mean not building agentic systems at all."

Applied to in-task scope: the agent should use the simplest change that
satisfies the stated requirement. Adjacent improvements are not "needed" by
that test.

**Claude Code best practices** applies the same principle to CLAUDE.md
authoring but it generalises:
> "For each line, ask: 'Would removing this cause Claude to make mistakes?'
> If not, cut it."

The analogous question for adjacent code changes: "Would skipping this change
cause the stated request to fail?" If not, skip it.

**Claude Code best practices also allows adjacent exploration** when the
request is deliberately open-ended:
> "Vague prompts can be useful when you're exploring and can afford to
> course-correct. A prompt like 'what would you improve in this file?' can
> surface things you wouldn't have thought to ask about."

This gives the criterion: adjacent work is acceptable when (a) the user's
request is explicitly open-ended, or (b) the adjacent change is strictly
necessary for correctness. In all other cases, note the finding and wait.

**The "note for follow-up" discipline** already in the existing template's
scope-lock rule is well-aligned with published practice. No change is needed
to that specific rule.

---

### Q4 — Established terms and Lean/Kaizen mappings

| Term | Source | Lean/Kaizen mapping |
|------|--------|---------------------|
| **Minimal footprint** | Anthropic model spec (Jan 2026 refresh) | Muda elimination (W1 Overproduction, W5 Inventory) |
| **Prefer reversible** | Anthropic model spec | Error-proofing (Poka-yoke); relates to W7 Defects |
| **Stopping conditions** | Anthropic Building Effective Agents | Kanban stop-the-line; standardised work exit criteria |
| **Checkpoints** | Anthropic Building Effective Agents | PDCA Check gate; visual management |
| **Scope lock** | Existing template (§3) | Standardised work; prevents W1 Overproduction |
| **Task boundary** | Existing template (§3) | Pull system boundary; one-piece flow |
| **Bounded initiative** | Not found in published literature | — |
| **Adjacent useful work** | Not found in published literature | — |

**Conclusion**: "Minimal footprint" is the one established term from
Anthropic's model spec that maps cleanly onto Lean waste reduction. It is
precise, sourced, and widely reproduced in the agent architecture community.
"Bounded initiative" and "adjacent useful work" are not established terms.

---

### Q5 — GitHub Copilot agent customization: scope and autonomy

**VS Code custom instructions docs** provide no specific scope-control
vocabulary. Their framing is:

> "Use them [always-on instructions] for project-wide coding standards,
> architecture decisions, and conventions that apply to all code."

The docs recommend keeping instructions "concise and focused for optimal
results" but give no agent-autonomy guidance beyond that.

**GitHub Copilot cloud agent docs** address autonomy at the task-selection
level ("assign straightforward backlog items to Copilot") but provide no
per-turn scope guidance for interactive sessions.

**VS Code Copilot's existing best-practice pattern** for instruction files is:
- Include what Claude can't figure out on its own
- Exclude what Claude already knows
- Keep it short enough that instructions are reliably followed

This is the closest the VS Code/GitHub ecosystem comes to a scope principle.

---

## Wording Patterns and Snippets

The following five patterns are concrete, minimal, and sourced. They are
ready to weave into an existing Lean/Kaizen instruction template.

### Snippet 1 — Minimal-footprint completion gate (Anthropic model spec)

```
Request only the access and changes necessary for the current task.
Prefer reversible changes over irreversible ones.
When uncertainty is high relative to the consequence of an error, pause and confirm.
```

**Where to add**: §3 Structured Thinking, after the Intent-Gate step, or as
an addition to the scope-lock rule.

---

### Snippet 2 — "Done means done" task-termination rule (adapted from Anthropic)

```
Task complete means the user-visible request is satisfied and verification
has passed — not that interesting adjacent improvements have been identified.
When the task is complete, stop and report. Do not proceed to adjacent work
without a new explicit request.
```

**Where to add**: Extends the existing "Task complete" bullet in §3.

---

### Snippet 3 — Adjacent-work checkpoint (adapted from Anthropic + Claude Code)

```
Adjacent-work test: "Is this change strictly necessary for the stated request
to succeed?" If yes, make it. If no, note it as a follow-up and stop.
Treat "useful", "related", and "while we're here" as failing this test.
```

**Where to add**: Alongside or replacing the current scope-lock bullet, or
as a YAGNI corollary in §1 Lean Principles.

---

### Snippet 4 — Turn-boundary scope reset (no published equivalent — derived)

```
Each new user message establishes a fresh task scope. A plan set in a prior
turn is not automatically carried forward. If the new request is a
continuation of the prior plan, the user will say so explicitly.
```

**Where to add**: §3 Structured Thinking, at the top of the Intent-Gate
step or as a note to the scope-lock rule.

---

### Snippet 5 — Minimal-footprint in YAGNI language (Lean-compatible)

```
Minimal footprint: build the smallest change that satisfies the stated
requirement. Every addition beyond that is W1 Overproduction. Propose
adjacent improvements in a follow-up note; do not implement them in the
same task.
```

**Where to add**: §1 Lean Principles table row 4 ("Establish pull") or
as a corollary to the YAGNI principle if one is added.

---

## Recommendation — Smallest Possible Change to Existing Template

The existing template's scope-lock rule in §3 Structured Thinking reads:

> **Scope lock**: once Plan is set, do not expand scope mid-task.
> If new work is discovered, note it for a follow-up task.

Extend it with one sentence from Snippet 4 and the adjacent-work test from
Snippet 3:

**Proposed revision** (adds ~25 words):

> **Scope lock**: once Plan is set, do not expand scope mid-task.
> If new work is discovered, note it for a follow-up task.
> Each new user message establishes a fresh scope; a prior plan does not
> carry forward unless the user explicitly says so.
> Adjacent-work test: "Is this change strictly necessary for the stated
> request to succeed?" Useful and related do not pass this test.

This single change:
- Resolves Q1 (turn-boundary semantics) without adding a new protocol
- Expresses Q2 ("done means done") via the adjacent-work test
- Addresses Q3 (when adjacent work is acceptable — only if strictly necessary)
- Uses no jargon not already in the template ("scope lock" and "follow-up task"
  are already established in §3)
- Adds no new section, no new table, and no new protocol

An optional complement: add "Minimal footprint — W1 Overproduction" as a
one-line example in the Waste Catalogue (§6) or as a principle clarifier in
§1 row 4. This surfaces the Anthropic-established term without requiring
structural changes.

---

## Gaps / Further Research Needed

- **Turn-boundary semantics in multi-agent orchestration**: how orchestrators
  signal scope boundaries between agent turns is not covered by any public
  instruction-set guidance found.
- **Quantitative threshold for "adjacent"**: no published instruction set
  provides a testable threshold (e.g., "adjacent = same file, same function").
  This remains a judgment call.
- **OpenAI Agents SDK scope guidance**: the OpenAI Agents SDK docs were not
  accessible during this session. The SDK's "guardrails" concept may include
  relevant scope-control patterns.
- **Cursor rules scope control**: the community `.cursorrules` corpus does not
  appear to have converged on scope-control vocabulary. A broader survey of
  the top-100 cursor rules might surface patterns not found in this sample.

