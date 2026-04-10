# Setup Interview Questions

> Fetched by the Setup agent during § 0d. Question content only — batching and
> presentation rules are in SETUP.md.

---

## Tier Q questions (always ask)

**Batch 1 (S1–S4)**:

- **S1 — Response style**: How much explanation do you want?
  Options: Concise (code + one-liner) | Balanced (code + brief explanation) | Verbose (code + full reasoning)

- **S2 — Experience level**: How experienced are you with this stack?
  Options: Beginner (explain basics) | Intermediate (assume language knowledge) | Expert (assume deep knowledge)

- **S3 — Primary mode**: What's your main priority?
  Options: Speed (fast iteration) | Quality (hardened production code) | Learning (teach as you go) | Balanced

- **S4 — Testing**: How should I handle tests?
  Options: Always write tests alongside code | Suggest tests but don't write | Skip unless asked

**Batch 2 (S5)**:

- **S5 — Autonomy**: How should I act when something is ambiguous?
  Options: Ask first (always confirm before acting) | Act then tell (proceed and report) | Best judgement

---

## Tier S additional questions (A6–A17)

**Batch 3 (A6–A9)**:

- **A6 — Code style**: How are formatting decisions made?
  Options: Infer from existing code | Follow a linter/formatter (specify which) | Follow a style guide (specify which)

- **A7 — Documentation**: How much inline documentation do you expect?
  Options: Minimal (self-documenting names only) | Standard (public APIs documented) | Full (all functions documented)

- **A8 — Error handling**: What's your error handling philosophy?
  Options: Fail fast (panic early, fix root cause) | Defensive (handle all errors explicitly) | Graceful degradation (recover where possible)

- **A9 — Security**: How aggressively should I flag security concerns?
  Options: Flag everything (even low severity) | Flag medium and above | Flag critical only

**Batch 4 (A10–A13)**:

- **A10 — File size**: What LOC thresholds should I enforce?
  Options: Strict (warn 150, hard 300) | Standard (warn 250, hard 400) | Relaxed (warn 400, hard 600) | None

- **A11 — Dependencies**: What's your dependency philosophy?
  Options: Minimal (avoid deps, write it yourself) | Pragmatic (use well-known libs) | Ecosystem-first (use the ecosystem liberally)

- **A12 — Instruction editing**: Can I edit the instructions file when I learn new patterns?
  Options: Free (edit anytime) | Ask (propose and wait for approval) | Suggest only (surface as recommendations) | Locked (never edit)

- **A13 — Refactoring**: How should I handle code smells I notice?
  Options: Fix proactively | Flag them | Ignore unless asked

**Batch 5 (A14–A17)**:

- **A14 — Reporting**: How should I report completed work?
  Options: Summary (what changed and why) | Detailed (files, LOC delta, test results) | Minimal (one sentence)

- **A15 — Skill search**: When I need a reusable workflow, should I search online skill repositories?
  Options: Local only (`.github/skills/` only) | Search online (agentskills.io and registries) | Ask each time

- **A16 — Lifecycle hooks**: Should I install agent lifecycle hook scripts?
  Options: Yes (install all hooks) | No | Ask about each hook

- **A17 — Prompt commands**: Should I scaffold VS Code slash command prompts?
  Options: Yes (install all prompts) | No | Ask about each

---

## Tier F additional questions (E16–E18, E20–E24)

> E19 removed — Global autonomy derived from S5: Ask first → level 2, Act then tell → level 3, Best judgement → level 4.

**Batch 6 (E16–E18)**:

- **E16 — Tool availability**: What should I do when a required tool isn't installed?
  Options: Install it (with permission) | Skip and note it | Report and stop

- **E17 — Agent persona**: What personality/tone do you want?
  Options: Professional | Mentor (teach and explain) | Pair-programmer (collaborative) | Direct (minimal preamble)

- **E18 — VS Code settings**: May I modify `.vscode/settings.json`?
  Options: Yes | No | Ask each time

**Batch 7 (E20–E24, E22a)**:

- **E20 — Mood lightener**: Should I occasionally add light humour?
  Options: Yes | No

- **E21 — Verification trust**: Which directories get auto-approve vs. pause-and-confirm?
  Options: All auto | Sensitive dirs require confirmation | Ask me to define

- **E22 — MCP servers**: Should I configure Model Context Protocol servers?
  Options: A — No (skip MCP entirely) | B — Yes (configure core MCP servers and optional selections)

- **E22a — Optional MCP servers**: Which optional MCP servers should I enable?
  Options: GitHub | Fetch | Context7 | None
  Ask only when E22 = B. Multi-select allowed. Default: None (keep core only: filesystem, git, heartbeat)

- **E23 — Claude compatibility**: Should I generate a `CLAUDE.md` file for Claude Code compatibility?
  Options: Yes | No

- **E24 — Thinking effort**: How should I configure thinking effort for reasoning models?
  Options: A — Use MODELS.md recommendations | B — All High | C — All Medium | D — Skip (VS Code defaults)
