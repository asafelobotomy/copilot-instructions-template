# Copilot Setup — Run Once

> **Running in remote mode?** If you arrived here because a user said something like *"Setup from asafelobotomy/copilot-instructions-template"*, you are in **remote mode** — no local file copying is needed.
>
> **Remote fetch sequence (complete before starting Step 0)**:
>
> 1. You have already read this file (`SETUP.md`) from GitHub. ✓
> 2. Fetch the instructions template and hold it in memory:
>    `https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/copilot-instructions.md`
> 3. Proceed with Steps 0–6 below, operating in the **user's current project** — not the template repo. Do not write anything to `asafelobotomy/copilot-instructions-template`. All file stubs are embedded inline in this document; no further fetching is required.
>
> **Running in local mode?** If the user manually placed this file in their project, proceed directly to Step 0 below.
>
> **Instructions for Copilot (both modes)**: Read **every step** before starting anything. Complete Steps 0a–0e fully before writing a single file. Tell the user exactly what you found, what you plan to do, and wait for confirmation at each decision point before proceeding.

---

> ⛔ **MANDATORY: THIS IS AN INTERACTIVE INTERVIEW — NOT A TASK LIST**
>
> This document contains an interview that MUST be conducted interactively with the user.
> Each question requires the user's typed response before proceeding.
>
> - Do NOT assume, infer, or auto-fill any answer.
> - Do NOT skip the interview or use defaults without the user explicitly typing "skip."
> - Do NOT proceed past any "Wait for..." instruction without a user response in chat.
> - If you are unable to ask questions interactively (e.g., running as a background
>   coding agent, in a CI pipeline, or in batch/autonomous mode), **STOP** and tell the user:
>   *"This setup requires an interactive chat session. Please use the Setup agent
>   (@setup) or run this in an interactive Copilot chat window."*
> - **Codex models** (GPT-5.3-Codex, GPT-5.2-Codex, etc.) are designed for autonomous
>   execution and are **not suitable for this setup**. Use the Setup agent (@setup),
>   which pins Claude Sonnet 4.6 for interactive instruction-following.

---

## Step 0 — Pre-flight

Before writing anything, run steps 0a through 0e in order. No files should be created or modified until Step 0e is complete and confirmed.

---

### 0a — Detect existing Copilot instructions

Check whether `.github/copilot-instructions.md` already exists.

**If it does NOT exist** → proceed directly to 0b. No prompt needed.

**If it DOES exist** → read the file in full, then present the user with the following choice before doing anything else:

---

> **Existing Copilot instructions detected** at `.github/copilot-instructions.md`.
>
> How would you like to handle them?
>
> **1 — Archive** Save the current instructions to `.github/archive/copilot-instructions-<YYYY-MM-DD>.md`, then replace the live file with the populated template. Your existing instructions are preserved in the archive folder and referenced from the new file.
>
> **2 — Delete** Remove the current instructions entirely and replace with the freshly populated template. Use this if the existing file is outdated or irrelevant.
>
> **3 — Merge** Read both the existing instructions and the new template, then produce a single unified file that:
>
> - Uses the template's structure (sections §1–§9 unchanged).
> - Preserves every unique convention, rule, pattern, or anti-pattern from the existing file that is not already covered by the template.
> - Places all preserved unique content into §10 (Project-Specific Overrides), clearly labelled as migrated from the previous instructions.
> - Discards any content from the existing file that is directly contradicted by or duplicated in the template.

---

Wait for the user to reply with **1**, **2**, or **3** (or equivalent phrasing) before proceeding.

#### Archive procedure (option 1)

1. Create the directory `.github/archive/` if it does not exist.
2. Copy the current `.github/copilot-instructions.md` to `.github/archive/copilot-instructions-<TODAY>.md`.
3. Add a comment at the top of the archived file:

   ```markdown
   <!-- Archived on <TODAY> during copilot-instructions-template setup. -->
   <!-- See .github/copilot-instructions.md for the live instructions.  -->
   ```

4. Continue to 0b; the new template file will be written in Step 2.
5. After the new file is written, add a note to its §10 section:

   ```markdown
   > Previous instructions archived at `.github/archive/copilot-instructions-<TODAY>.md`.
   > Review that file for any conventions that were not automatically migrated.
   ```

#### Delete procedure (option 2)

1. Delete `.github/copilot-instructions.md`.
2. Continue to 0b; a fresh template file will be written in Step 2.

#### Merge procedure (option 3)

1. **Extract from the existing file** — read it and identify:
   - Any project-specific conventions (naming rules, code patterns, tool usage rules).
   - Any anti-patterns documented.
   - Any workflow or command sequences.
   - Any metric thresholds that differ from the template defaults (250/400 LOC, dep budget, etc.).
   - Any sections or headings that have no equivalent in the template.

2. **Populate the template** — proceed through Steps 1–2 as normal (discover stack, fill placeholders).

3. **Graft unique content** — for each unique item extracted above:
   - If it belongs naturally in §1–§9, add it there with a `<!-- migrated -->` comment.
   - If it doesn't fit neatly, add it to §10 under "Conventions from previous instructions".
   - If it contradicts the template, note the conflict and ask the user which version to keep.

4. **Produce a summary** — tell the user how many items were migrated, how many conflicts were found, and what was intentionally discarded and why.

5. Do **not** create an archive in this path. If the user also wants an archive, they can request option 1 first.

---

### 0b — Detect existing workspace identity files

Check whether `.copilot/workspace/` exists and contains any of the seven identity files (IDENTITY.md, SOUL.md, USER.md, TOOLS.md, MEMORY.md, BOOTSTRAP.md, HEARTBEAT.md).

**If none exist** → proceed; Step 3 will create them all.

**If some or all exist** → report which ones were found, then ask:

> **Existing workspace identity files detected**: `<list of files found>`
>
> These files may contain session history and learned preferences.
>
> - **Keep all** (default) — skip creating any file that already exists. *(Recommended if Copilot has been working in this project.)*
> - **Overwrite all** — replace all existing identity files with fresh stubs.
> - **Selective** — tell me which files to keep and which to overwrite.

Wait for the user's response before proceeding.

---

### 0c — Detect existing documentation stubs

Check for the presence of: `CHANGELOG.md`, `JOURNAL.md`, `BIBLIOGRAPHY.md`, `METRICS.md`.

Report which exist, then state:

> The following files already exist: `<list>`. I will **skip** creating these and only create the missing ones: `<list>`. If you would like me to append setup entries to the existing files instead of skipping them, say **"append entries"**.

Wait for confirmation or "append entries" before proceeding.

If **"append entries"**: for each existing file, append the appropriate setup entry rather than replacing the file.

---

### 0d — User Preference Interview

> **Purpose**: Before building the instructions, learn how you want Copilot to behave in this project. Answers are written into §10 of the instructions file and used throughout to calibrate Copilot's tone, depth, and autonomy. This interview takes 1–3 minutes depending on the setup level you choose.
>
> ⛔ **INTERACTIVE CHECKPOINT**: You are about to conduct a user interview.
> Each batch of questions below MUST be asked via `ask_questions` (or as text
> if the tool is unavailable) and you MUST wait for the user's response before
> proceeding to the next batch. Do not auto-fill or skip.

Present the following to the user:

---

> **Setup mode**: Which level of configuration would you like?
>
> - **S — Simple Setup** (5 questions, ~1 min) — Essential preferences only. Advanced and Expert options use sensible defaults.
> - **A — Advanced Setup** (15 questions, ~2 min) — Full control over Copilot's coding behaviour.
> - **E — Expert Setup** (22 questions, ~3 min) — Everything in Advanced, plus persona, autonomy failsafe, tool availability, VS Code settings, MCP servers, and more.
>
> *(You can also type "skip" to use all defaults and proceed immediately.)*

---

Wait for the user's response, then proceed with the corresponding question set below. If the user types "skip", apply all default values from the mapping tables and proceed to Step 0e.

---

#### Tooling and Batch Plan

> **`ask_questions` tool constraints**: max **4 questions per call**, max **6 options per question**, `header` max **12 characters**. If `ask_questions` is not available (e.g., non-VS-Code IDE, GitHub.com chat), present questions as numbered text in chat and wait for the user's typed response to each batch before continuing.

Use the batch plan below. Do not combine questions across tiers in a single call. Wait for the user's response to each batch before issuing the next.

| Batch | Tier | Questions | Suggested headers |
|-------|------|-----------|-------------------|
| 1 | Simple | S1, S2, S3, S4 | Style, Level, Mode, Testing |
| 2 | Simple | S5 | Autonomy |
| 3 | Advanced | A6, A7, A8, A9 | Code style, Docs, Errors, Security |
| 4 | Advanced | A10, A11, A12, A13 | File size, Deps, Self-edit, Refactor |
| 5 | Advanced | A14, A15 | Reporting, Skills |
| 6 | Expert | E16, E17, E18, E19 | Tools, Persona, VS Code, Failsafe |
| 7 | Expert | E20, E21, E22 | Mood, Trust, MCP |

**Simple** = batches 1–2. **Advanced** = batches 1–5. **Expert** = batches 1–7.

---

#### Simple Setup — 5 questions (batches 1–2)

Present questions in **2 batches** following the batch plan above. Collect answers from each batch before issuing the next.

---

**S1 — Response style**

> How would you like Copilot to communicate with you?
>
> **A — Concise**: Give me the code and a one-line summary. Minimal explanation.
> **B — Balanced** *(default)*: Code plus brief reasoning. Explain non-obvious decisions.
> **C — Thorough**: Explain all decisions, alternatives considered, and trade-offs.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Keep all responses concise. Provide code first, then a one-sentence summary of what changed and why. Omit explanations unless the decision is non-obvious." |
| B | "Balance code with reasoning. Always explain decisions that aren't obvious from context. Skip explanations of standard patterns the user already knows." |
| C | "Be thorough. For every significant decision, explain the reasoning, any alternatives considered, and the trade-offs. The user wants to understand, not just receive output." |

---

**S2 — Experience level with this stack**

> How familiar are you with this project's technology stack?
>
> **A — Novice**: I'm learning. Explain concepts, patterns, and why you chose them.
> **B — Intermediate** *(default)*: Familiar with the basics. Explain complex or non-obvious choices only.
> **C — Expert**: I know this stack well. Skip basics — focus on the problem.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "The user is learning this stack. Define terms when first used. Explain patterns before applying them. Prefer simpler solutions over clever ones when both work." |
| B | "The user knows the basics of this stack. Explain non-obvious choices, but skip well-known patterns. Don't over-explain standard library usage." |
| C | "The user is an expert in this stack. Skip all introductory explanation. Use precise technical language. Prefer idiomatic solutions." |

---

**S3 — Primary working mode**

> What is your most common intent when working in this project?
>
> **A — Ship features**: Speed matters. Pragmatic over perfect.
> **B — Code quality** *(default)*: Correctness, maintainability, and test coverage first.
> **C — Learning**: I want to understand the code I write. Prefer clarity over brevity.
> **D — Production hardening**: Security, observability, and resilience. Assume this runs in prod.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Optimise for speed of delivery. Prefer working solutions over elegant ones. Flag tech debt but don't block on it. Perfect is the enemy of shipped." |
| B | "Optimise for code quality. Correctness and test coverage take priority over delivery speed. Flag and address technical debt proactively." |
| C | "Optimise for learning. Prefer clear, idiomatic code over clever solutions. Explain patterns before applying them. Suggest simpler alternatives when they exist." |
| D | "Treat every change as if it runs in production. Proactively flag security concerns, error handling gaps, and observability gaps. Never silently swallow errors." |

---

**S4 — Testing expectations**

> What are your expectations for tests?
>
> **A — Write tests alongside every change** *(default)*: Tests are non-negotiable.
> **B — Suggest tests, don't write them**: Point out what should be tested; I'll write them.
> **C — Write tests only when I explicitly ask**: I'll request tests.
> **D — No tests for this project**: Skip all test guidance.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Write tests alongside every code change. Never submit a change without at least one test covering the new or modified behaviour. Writing tests is not optional." |
| B | "Do not automatically write tests. After every change, list the scenarios that should be tested and why, so the user can write them." |
| C | "Only write tests when explicitly asked. Do not mention tests unless requested." |
| D | "This project has no automated tests. Do not suggest or write tests. Do not flag missing test coverage." |

---

**S5 — Autonomy level**

> How much should Copilot act vs. pause to ask?
>
> **A — Always ask first**: Describe the plan and wait for my approval before making changes.
> **B — Act then summarise** *(default)*: Make changes, then explain what was done.
> **C — Ask only for risky changes**: Act freely; pause only before destructive or irreversible changes.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Always describe the planned approach and wait for explicit user approval before creating, modifying, or deleting any file. Do not act until approved." |
| B | "Implement changes directly, then provide a clear summary of what was done and why. Ask for confirmation only when the scope is significantly larger than expected." |
| C | "Act freely on routine changes. Before deleting files, overwriting significant content, or making changes that are hard to reverse, pause and ask for confirmation." |

---

#### Advanced Setup — 10 additional questions A6–A15 (batches 3–5)

If the user chose **A — Advanced Setup** or **E — Expert Setup**, present these 10 questions in **3 batches** following the batch plan above. Collect answers from each batch before issuing the next. If the user chose **S — Simple Setup**, skip these and proceed to 0e.

**Questions in this section** (verify all 10 are asked):
A6 (Code style) · A7 (Documentation) · A8 (Error handling) · A9 (Security) ·
A10 (File size) · A11 (Dependencies) · A12 (Instruction editing) ·
A13 (Refactoring) · A14 (Reporting format) · A15 (Skill search)

---

**A6 — Code style and formatting**

> How should Copilot determine coding style and formatting?
>
> **A — Infer from existing code** *(default)*: Read the codebase, linter configs, and formatter configs, then match what's there.
> **B — Follow project linter/formatter**: Defer entirely to the project's configured tools (ESLint, Prettier, Biome, Ruff, rustfmt, etc.). If none configured, ask.
> **C — Follow community style guide**: Use the official style guide for the primary language (Airbnb JS, PEP 8, Rust style guide, gofmt, etc.).
> **D — I'll provide a style guide**: Type the path or URL to your style guide now.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Infer coding style from existing code, linter configs (`.eslintrc.*`, `biome.json`, `ruff.toml`, etc.), and formatter configs (`.prettierrc.*`, `rustfmt.toml`, etc.). Match the patterns already present before applying any external standard." |
| B | "Defer entirely to the project's configured linter and formatter for all style decisions. If no linter or formatter is configured, flag this and ask the user which to set up." |
| C | "Follow the official community style guide for the project's primary language. For JS/TS: Airbnb or Standard. For Python: PEP 8. For Rust: the Rust style guide. For Go: gofmt. Adapt to the ecosystem." |
| D | *(User types the guide URL/path)* "Follow the style guide at `<user_input>`. When in conflict with auto-detected patterns, the style guide takes precedence." |

---

**A7 — Documentation standard**

> What level of inline documentation do you expect?
>
> **A — Type signatures + brief comments on non-obvious code** *(default)*: Minimal but accurate.
> **B — Full JSDoc / docstrings on all public APIs**: Every exported function documented.
> **C — README-driven**: Prefer good README files over inline docs.
> **D — Minimal**: Code should be self-documenting. Comments only for truly non-obvious logic.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Add brief inline comments only for non-obvious logic. Public functions and types should have type signatures. Avoid comment noise on obvious code." |
| B | "Every public function, class, and type must have a JSDoc/docstring. Include `@param`, `@returns`, and `@throws` tags as relevant." |
| C | "Keep inline docs minimal. Update README files to document APIs, usage patterns, and architecture decisions instead of scattered inline comments." |
| D | "Write self-documenting code — clear names, small functions, expressive types. Only comment when the code cannot speak for itself." |

---

**A8 — Error handling philosophy**

> How should errors be handled in this codebase?
>
> **A — Fail fast**: Throw / panic on unexpected states. Errors should be loud and obvious.
> **B — Defensive (return values)** *(default)*: Prefer returning `null` / `Result` / `Option`. Caller decides.
> **C — Graceful degradation**: Keep the system running; log errors and continue where safe.
> **D — Domain-specific**: I'll describe the approach myself. *(Type it now.)*

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Fail fast. Throw exceptions or panic on unexpected states. Do not silently swallow errors. Errors should surface immediately and loudly." |
| B | "Prefer returning error values (`null`, `Result<T,E>`, `Option<T>`) over throwing. Let the caller decide how to handle failure. Reserve exceptions for truly unrecoverable states." |
| C | "Prefer graceful degradation. Log errors with sufficient context and continue operating where it is safe to do so. Reserve hard failures for unrecoverable states." |
| D | *(User types their approach)* — Record verbatim as the error-handling instruction. |

---

**A9 — Security sensitivity**

> How security-conscious should Copilot be in this project?
>
> **A — Flag all potential issues**: Even speculative security concerns.
> **B — Flag when directly relevant** *(default)*: Only when the change touches auth, data handling, or external input.
> **C — Security-critical project**: Treat every change as a potential attack surface.
> **D — Not a concern**: Internal tool, no sensitive data. Skip security guidance.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Proactively flag any potential security concern, including speculative ones. Prefer over-caution over missing a vulnerability." |
| B | "Flag security concerns only when the change directly touches authentication, authorisation, data handling, or external input processing." |
| C | "Treat every change as a potential attack surface. Apply security review to all code regardless of context. Reference OWASP Top 10 where relevant." |
| D | "This is an internal tool with no sensitive data. Do not apply security review or flag security concerns unless asked." |

---

**A10 — File size discipline**

> How strictly should Copilot enforce file length limits? (These set the §3 LOC baselines.)
>
> **A — Strict** (150 / 300): Flag at 150 lines, refuse to extend past 300. Forces aggressive decomposition.
> **B — Standard** *(default)* (250 / 400): Flag at 250 lines, refuse to extend past 400. Good balance for most projects.
> **C — Relaxed** (400 / 600): Flag at 400 lines, refuse to extend past 600. For projects with inherently larger files (generated code, config-heavy).
> **D — No limits**: Do not enforce file length limits. Focus on logical coherence instead of line counts.

| Answer | Instruction written to §10 | §3 values set |
|--------|---------------------------|---------------|
| A | "Strictly enforce file size limits. Flag any file exceeding 150 lines; refuse to extend past 300 without decomposing first." | `LOC_WARN=150`, `LOC_HIGH=300` |
| B | "Enforce standard file size limits. Flag files exceeding 250 lines; refuse to extend past 400 without decomposing first." | `LOC_WARN=250`, `LOC_HIGH=400` |
| C | "Apply relaxed file size limits. Flag files exceeding 400 lines; refuse to extend past 600 without decomposing first." | `LOC_WARN=400`, `LOC_HIGH=600` |
| D | "Do not enforce file length limits. Focus on logical coherence and readability. Remove LOC baselines from §3." | LOC baselines disabled |

---

**A11 — Dependency management**

> How should Copilot handle adding new dependencies?
>
> **A — Minimal**: Avoid new dependencies whenever possible. Prefer stdlib or hand-written code.
> **B — Pragmatic** *(default)*: Add dependencies when they provide clear value. Justify additions and propose removal of unused ones first.
> **C — Ecosystem-first**: Freely use well-maintained packages. Don't reinvent the wheel.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Minimise dependencies. Prefer standard library or hand-written solutions over adding packages. Every new dependency needs explicit justification and a matching removal proposal for an existing one." |
| B | "Add dependencies when they provide clear value and are well-maintained. Always check if existing dependencies cover the need. Propose removing unused dependencies before adding new ones." |
| C | "Freely use well-maintained ecosystem packages. Don't reinvent the wheel. Trust popular, actively maintained packages. Flag only unmaintained or duplicate dependencies." |

---

**A12 — Instruction self-editing**

> The template includes a Living Update Protocol (§8) that allows Copilot to evolve its own instructions as patterns emerge. How should this work?
>
> **A — Free to update**: Copilot can add rules and patterns to the instructions file as it discovers them. Report changes after the fact.
> **B — Ask first** *(default)*: Copilot proposes instruction changes and waits for approval before editing.
> **C — Suggest only**: Copilot suggests instruction improvements in chat but never edits the file directly.
> **D — Locked**: Instructions are static after setup. Do not propose or make changes.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "You may update `.github/copilot-instructions.md` freely when patterns stabilise. Append to §10 or add rules to §4. Report what was changed at the end of the session." |
| B | "Before editing `.github/copilot-instructions.md`, describe the proposed change and wait for approval. Never edit §1–§7 without explicit user instruction." |
| C | "Do not edit `.github/copilot-instructions.md`. When you identify a pattern that could become a rule, suggest it in chat. The user will apply it manually if desired." |
| D | "The instructions file is frozen after setup. Do not propose, suggest, or make changes to `.github/copilot-instructions.md` under any circumstances." |

---

**A13 — Refactoring appetite**

> When Copilot encounters code smells, tech debt, or waste (§6) while working on a task, should it proactively address them?
>
> **A — Fix proactively**: Clean up smells and waste whenever encountered. Include refactoring in the PDCA scope.
> **B — Flag and suggest** *(default)*: Note smells and waste in the response but don't fix unless asked.
> **C — Ignore unless asked**: Focus only on the requested task. Don't mention smells or tech debt.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Proactively refactor code smells and waste when encountered during any task. Include cleanup in the PDCA scope. Tag each refactoring with its waste category (§6)." |
| B | "Flag code smells, tech debt, and waste (§6) when encountered, but do not fix them unless asked. Log improvement suggestions in the session summary." |
| C | "Focus exclusively on the requested task. Do not flag code smells, tech debt, or refactoring opportunities unless explicitly asked to review." |

---

**A14 — Change reporting format**

> When Copilot completes a task, how should it report what it did?
>
> **A — Bullet list of files changed** *(default)*: Quick, scannable.
> **B — CHANGELOG-style**: Formatted for direct paste into CHANGELOG.md.
> **C — PR description**: Written as if opening a pull request.
> **D — Narrative paragraph**: Explain in prose what changed and why.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "After completing a task, provide a bullet list of files created/modified/deleted and a one-line description of what changed in each." |
| B | "After completing a task, provide a CHANGELOG entry formatted for Keep-a-Changelog (`### Added / Changed / Fixed`), ready to paste into CHANGELOG.md." |
| C | "After completing a task, provide a PR description with a Summary, Changes Made, and Testing Notes section." |
| D | "After completing a task, write a short narrative paragraph explaining what changed, the key decisions made, and any follow-up items." |

---

**A15 — Skill search preference**

> The template includes an Agent Skills system (§12) that provides reusable workflow instructions. When a task would benefit from a skill that doesn't exist locally, should Copilot search online skill repositories?
>
> **A — Local only** *(default)*: Only use skills already in `.github/skills/`. Create new skills in-house when needed. No online searching.
> **B — Official repositories only**: Search official skill repositories (Anthropic, OpenAI, GitHub) for proven workflows. Adapt and save locally before use.
> **C — Official + community**: Search official repositories first, then community sources. Community skills are quality-checked before adoption.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Skill search: local only. Use only skills present in `.github/skills/` or `~/.copilot/skills/`. When no matching skill exists, create one from scratch following the §12 authoring rules. Do not search online repositories." |
| B | "Skill search: official repositories only. When no local skill matches, search official sources (anthropics/skills, openai/skills, github/awesome-copilot). Evaluate fit, adapt to project conventions, and save locally before use." |
| C | "Skill search: official + community. Search official repositories first, then community sources (GitHub search, awesome-agent-skills). Community skills must pass the §12 quality gate before adoption." |

| Answer | `{{SKILL_SEARCH_PREFERENCE}}` value |
|--------|--------------------------------------|
| A | `local-only` |
| B | `official-only` |
| C | `official-and-community` |

---

#### Expert Setup — 7 additional questions E16–E22 (batches 6–7)

If the user chose **E — Expert Setup**, present these 7 questions in **2 batches** following the batch plan above. Collect answers from each batch before issuing the next. If the user chose **S — Simple Setup** or **A — Advanced Setup**, skip these and proceed to 0e.

**Questions in this section** (verify all 7 are asked):
E16 (Tool availability) · E17 (Agent persona) · E18 (VS Code settings) ·
E19 (Global autonomy) · E20 (Mood lightener) · E21 (Verification trust) · E22 (MCP servers)

---

**E16 — Tool and dependency availability**

> When Copilot needs a tool, dependency, or runtime that isn't currently available (e.g., trying to use `bun` but it's not installed), what should it do?
>
> **A — Stop and request** *(default)*: Stop, explain what's needed and why, and ask permission to install or configure it before proceeding.
> **B — Attempt workaround first**: Try an alternative approach. If no viable workaround exists, stop and explain the requirement.
> **C — Always work around**: Never request new tools or installations. Use only what's available, even if the result is less optimal or incomplete.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "When a required tool, dependency, or runtime is unavailable, stop immediately. Explain what is needed, why it's needed, and how to install/configure it. Do not attempt workarounds that compromise solution quality. Wait for the user to make it available." |
| B | "When a required tool or dependency is unavailable, first attempt a viable alternative approach. If no workaround maintains solution quality, stop and explain the requirement. Never silently degrade the solution." |
| C | "Never request new tools, dependencies, or installations. Work exclusively with what is currently available. If a task cannot be completed well with available tools, state the limitation but proceed with the best available approach." |

---

**E17 — Agent persona**

> Give your Copilot agent a personality. This affects tone, vocabulary, and conversational style — not technical capability.
>
> **A — Professional** *(default)*: Neutral, efficient, direct. No personality beyond clarity.
> **B — Mentor**: Patient, educational. Explains like a senior dev guiding a junior. Encouraging language.
> **C — Pair programmer**: Collaborative, thinks out loud. Uses "we" language. Brainstorms alternatives.
> **D — Ship-it captain**: High-energy, goal-focused. Celebrates wins. Keeps momentum high. 🚀
> **E — Zen master**: Calm, philosophical. Values simplicity. Occasionally quotes programming wisdom.
> **F — Rubber duck**: Minimal. Repeats your problem back in clearer terms. Asks clarifying questions. Lets you find the answer.
>
> *(The tool's built-in "Other" option allows you to describe a custom persona if none of the above fit.)*

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Maintain a professional, neutral tone. Be direct, efficient, and clear. No personality embellishments." |
| B | "Adopt a mentor persona. Be patient and educational. Explain reasoning as if guiding a junior developer. Use encouraging language: 'Great question', 'Good instinct', 'Here's why that matters'." |
| C | "Adopt a pair-programmer persona. Think out loud. Use 'we' language ('Let's try...', 'We could...'). Brainstorm alternatives before committing to an approach. Be conversational." |
| D | "Adopt a ship-it captain persona. Be high-energy and goal-focused. Celebrate wins ('Ship it! 🚀', 'Nice catch!'). Keep momentum high. Break down blockers aggressively." |
| E | "Adopt a zen master persona. Be calm and composed. Value simplicity above all. Occasionally share relevant programming wisdom ('Premature optimisation is the root of all evil'). Prefer the simplest solution." |
| F | "Adopt a rubber-duck persona. Be minimal. Repeat the user's problem back in clearer terms. Ask clarifying questions before offering solutions. Help the user reason through the problem themselves." |
| Other | *(User types their persona description)* — Record verbatim as the persona instruction. |

---

**E18 — VS Code settings management**

> Should Copilot modify VS Code workspace settings (`.vscode/settings.json`) when it believes a change would improve the development experience?
>
> **A — Never** *(default)*: Do not touch VS Code settings files. Suggest changes for me to apply manually.
> **B — Ask first**: Propose settings changes with an explanation and expected impact. Apply only after explicit approval.
> **C — Auto-apply workspace settings**: Freely modify `.vscode/settings.json` for this project. Never touch user-level settings.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Do not create or modify `.vscode/settings.json` or any VS Code configuration files. If a settings change would help, describe it in chat and let the user apply it." |
| B | "When a VS Code workspace settings change would improve the development experience, propose it with a clear explanation of what it does and why. Apply only after the user explicitly approves. Never modify user-level settings." |
| C | "Freely create or modify `.vscode/settings.json` when it improves the development experience (e.g., enabling formatOnSave, configuring linter paths, setting file associations). Summarise changes after applying. Never touch user-level settings." |

---

**E19 — Global autonomy override (failsafe)**

> Set a master autonomy ceiling on a 1–5 scale. This acts as a **hard override** that caps all other autonomy-related settings (S5, §8, etc.), regardless of what they allow.
>
> **1 — Full lockdown**: Every file create/modify/delete requires explicit approval. No exceptions. Overrides all other autonomy settings.
> **2 — Cautious**: All write operations require approval. Read-only analysis proceeds automatically.
> **3 — Balanced** *(default)*: No override — autonomy follows the S5 setting and §8 protocol normally.
> **4 — High autonomy**: Act independently on most tasks. Pause only for destructive operations or major architectural changes.
> **5 — Full autonomy**: Execute any action Copilot believes is correct, including destructive operations. Requires robust version control.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| 1 | "FAILSAFE ACTIVE — Global autonomy: 1 (Full lockdown). Every action that creates, modifies, or deletes a file requires explicit user approval. This overrides S5 and §8. No exceptions." |
| 2 | "Global autonomy: 2 (Cautious). All write operations require explicit approval. Read-only analysis, searches, and queries may proceed automatically. Overrides more permissive S5 settings." |
| 3 | "Global autonomy: 3 (Balanced). No autonomy override applied. Follow the S5 setting and §8 Living Update Protocol as configured." |
| 4 | "Global autonomy: 4 (High autonomy). Act independently on all routine tasks including file creation and modification. Pause only before: deleting files, overwriting large sections, changing config files, or making architectural decisions." |
| 5 | "Global autonomy: 5 (Full autonomy). Execute any action you believe is correct, including destructive operations. Use best judgment. Log all actions for post-session review. Requires robust version control." |

---

**E20 — Mood lightener**

> Long coding sessions can be stressful. Should Copilot occasionally lighten the mood?
>
> **A — Never** *(default)*: Keep all interactions strictly professional and task-focused.
> **B — Occasionally**: Drop a programming joke or encouraging comment after resolving a frustrating bug, finishing a long task, or during extended sessions.
> **C — Frequently**: Sprinkle humour throughout — dev jokes, light comments, relevant references between tasks. Life's too short for boring terminals.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Keep all interactions strictly professional and task-focused. No jokes, humour, or casual commentary." |
| B | "Occasionally lighten the mood. After resolving a frustrating bug, completing a long task, or during extended sessions, drop a brief programming joke or encouraging comment. Keep it natural — never forced." |
| C | "Actively lighten the mood. Include programming jokes, light comments, or dev culture references between tasks. Match tone to the moment — celebratory after wins, sympathetic after tough bugs, encouraging during long sessions." |

---

**E21 — Verification trust**

> The template includes a Graduated Trust Model (§10) that controls how much verification Copilot applies based on which files are being changed. Which directories should get automatic approval, standard review, or extra caution?
>
> **A — Use defaults** *(default)*: Tests and docs get auto-approval; source code requires review; config and CI files require pause-and-confirm.
> **B — Trust everything**: Auto-approve all paths. I use version control and will review diffs myself.
> **C — Review everything**: All paths require review. No auto-approval for any file.
> **D — Custom tiers**: I'll describe which paths get which trust level. *(Type it now.)*

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "Use the default Graduated Trust Model tiers: High trust for tests and docs (auto-approve), Standard for source code (review before writing), Guarded for config and CI files (pause and explain). No custom overrides." |
| B | "Override the Graduated Trust Model: set all paths to High trust. Auto-approve all changes. The user relies on version control for review." |
| C | "Override the Graduated Trust Model: set all paths to Standard trust. Describe every planned change and wait for approval before writing, regardless of file type." |
| D | *(User types their custom tier assignments)* — Record verbatim as `{{TRUST_OVERRIDES}}` in §10. |

| Answer | `{{TRUST_OVERRIDES}}` value |
|--------|----------------------------|
| A | *(empty — use defaults)* |
| B | `> **Trust override**: All paths set to High trust. Auto-approve all changes.` |
| C | `> **Trust override**: All paths set to Standard trust. Review before every write.` |
| D | *(user-provided custom tiers)* |

---

**E22 — MCP server configuration**

> The template includes a Model Context Protocol (MCP) integration (§13) that connects Copilot to external tools via `.vscode/mcp.json`. How should MCP servers be configured during setup?
>
> **A — None** *(default)*: Do not create an MCP configuration file. I will configure MCP servers manually if needed.
> **B — Always-on only**: Create `.vscode/mcp.json` with the three always-on servers (filesystem, memory, git) enabled. Credentials-required servers remain disabled.
> **C — Full configuration**: Create `.vscode/mcp.json` with all five default servers. I will provide credentials for GitHub and fetch servers. Also suggest stack-specific MCP servers based on my project's technology.

| Answer | Instruction written to §10 |
|--------|---------------------------|
| A | "MCP integration: None. No `.vscode/mcp.json` is created. The user will configure MCP servers manually if needed. §13 remains as reference documentation only." |
| B | "MCP integration: Always-on only. `.vscode/mcp.json` is configured with filesystem, memory, and git servers enabled. Credentials-required servers (GitHub, fetch) remain disabled. Suggest enabling them when external API access is needed." |
| C | "MCP integration: Full configuration. `.vscode/mcp.json` is configured with all five default servers. Suggest stack-specific MCP servers when relevant. Proactively recommend new servers from the MCP registry when a task would benefit from external tool access." |

| Answer | `{{MCP_STACK_SERVERS}}` | `{{MCP_CUSTOM_SERVERS}}` |
|--------|------------------------|--------------------------|
| A | *(empty)* | *(empty)* |
| B | *(empty — stack-specific servers not discovered)* | *(empty)* |
| C | *(populated from Step 2.12 stack-specific server discovery)* | *(populated from Step 2.12 if user adds custom servers)* |

---

#### Building the User Preferences block

Once all questions are answered, construct the following block and write it into §10 of the instructions file under a `### User Preferences` heading:

```markdown
### User Preferences

> *Set during initial setup on {{SETUP_DATE}}. Update this section using the Living Update Protocol when preferences change.*

| Dimension | Setting | Instruction |
|-----------|---------|-------------|
| Response style | <S1 answer label> | <S1 instruction text> |
| Experience level | <S2 answer label> | <S2 instruction text> |
| Primary mode | <S3 answer label> | <S3 instruction text> |
| Testing | <S4 answer label> | <S4 instruction text> |
| Autonomy | <S5 answer label> | <S5 instruction text> |
| Code style | <A6 answer label or default> | <instruction> |
| Documentation | <A7 answer label or default> | <instruction> |
| Error handling | <A8 answer label or default> | <instruction> |
| Security | <A9 answer label or default> | <instruction> |
| File size discipline | <A10 answer label or default> | <instruction> |
| Dependency management | <A11 answer label or default> | <instruction> |
| Instruction self-editing | <A12 answer label or default> | <instruction> |
| Refactoring appetite | <A13 answer label or default> | <instruction> |
| Reporting format | <A14 answer label or default> | <instruction> |
| Skill search | <A15 answer label or default> | <instruction> |
| Tool availability | <E16 answer label or default> | <instruction> |
| Agent persona | <E17 answer label or default> | <instruction> |
| VS Code settings | <E18 answer label or default> | <instruction> |
| Global autonomy | <E19 answer label or default> | <instruction> |
| Mood lightener | <E20 answer label or default> | <instruction> |
| Verification trust | <E21 answer label or default> | <instruction> |
| MCP servers | <E22 answer label or default> | <instruction> |
```

**Simple Setup defaults** (used for A6–A15 and E16–E22 when Simple is chosen):

| Question | Default answer | Default instruction |
|----------|---------------|---------------------|
| A6 — Code style | A | Infer from existing code and linter/formatter configs |
| A7 — Docs | A | Type signatures + brief comments on non-obvious code |
| A8 — Errors | B | Defensive — prefer return values over throwing |
| A9 — Security | B | Flag when directly relevant |
| A10 — File size | B | Standard (250 warn / 400 hard) |
| A11 — Dependencies | B | Pragmatic — add when clear value, justify additions |
| A12 — Self-editing | B | Ask first — propose changes, wait for approval |
| A13 — Refactoring | B | Flag and suggest — note smells but don't auto-fix |
| A14 — Reporting | A | Bullet list of files changed |
| A15 — Skill search | A | Local only — no online searching |
| E16 — Tool availability | A | Stop and request — explain the need, wait for approval |
| E17 — Persona | A | Professional — neutral, efficient, direct |
| E18 — VS Code settings | A | Never — suggest only, don't modify |
| E19 — Global autonomy | 3 | Balanced — no override, follow S5 setting |
| E20 — Mood lightener | A | Never — strictly professional |
| E21 — Verification trust | A | Use defaults — tests/docs auto-approve, source review, config pause |
| E22 — MCP servers | A | None — no MCP configuration file created |

**Advanced Setup defaults** (used for E16–E22 when Advanced is chosen):

| Question | Default answer | Default instruction |
|----------|---------------|---------------------|
| E16 — Tool availability | A | Stop and request — explain the need, wait for approval |
| E17 — Persona | A | Professional — neutral, efficient, direct |
| E18 — VS Code settings | A | Never — suggest only, don't modify |
| E19 — Global autonomy | 3 | Balanced — no override, follow S5 setting |
| E20 — Mood lightener | A | Never — strictly professional |
| E21 — Verification trust | A | Use defaults — tests/docs auto-approve, source review, config pause |
| E22 — MCP servers | A | None — no MCP configuration file created |

---

#### Interview Verification Gate — STOP and verify

Before proceeding to 0e, count your collected answers and verify against this table:

| Tier | User answers | Defaults applied | Total rows in §10 |
|------|-------------|-----------------|-------------------|
| Simple | 5 (S1–S5) | 17 (A6–A15 + E16–E22) | 22 |
| Advanced | 15 (S1–S5 + A6–A15) | 7 (E16–E22) | 22 |
| Expert | 22 (S1–S5 + A6–A15 + E16–E22) | 0 | 22 |

**If your count does not match**: STOP. Re-read §0d and identify which questions were missed. Ask them now before continuing.

List the missing questions by ID (e.g., "A11, A12, A13, A14 were not yet asked") and present them in the next `ask_questions` call.

---

### 0e — Pre-flight summary

After completing 0a–0d, present a single summary before writing anything.

> **Output the template below exactly.** Fill every `<label>` field. Show all 22
> USER PREFERENCES dimensions — for defaulted values, append "(default)" to the
> label. Do not omit Step 2.5 or Step 2.8 from NEXT STEPS. Do not rearrange or improvise.

```text
Pre-flight complete. Here is what I will do:

  EXISTING FILE HANDLING
    Instructions:        [archive to .github/archive/<date>.md / delete / merge / create fresh]
    Workspace files:     [keep existing / overwrite / selective: <details> / create all]
    Doc stubs:           [skip existing / append entries / create missing only]

  USER PREFERENCES (from interview)
    Response style:        <label>
    Experience level:      <label>
    Primary mode:          <label>
    Testing:               <label>
    Autonomy:              <label>
    Code style:            <label>
    Documentation:         <label>
    Error handling:        <label>
    Security:              <label>
    File size discipline:  <label>
    Dependency management: <label>
    Instruction editing:   <label>
    Refactoring appetite:  <label>
    Reporting format:      <label>
    Skill search:          <label>
    Tool availability:     <label>
    Agent persona:         <label>
    VS Code settings:      <label>
    Global autonomy:       <label>
    Mood lightener:        <label>
    Verification trust:    <label>
    MCP servers:           <label>

  NEXT STEPS
    1.   Discover project stack (Step 1)
    2.   Populate instructions file with placeholders + user preferences (Step 2)
    2.5. Write agent files for model-pinned workflows (.github/agents/) (Step 2.5)
    2.8. Scaffold skill library (.github/skills/) (Step 2.8)
    2.12. Configure MCP servers (.vscode/mcp.json) (Step 2.12)
    3.   Create workspace identity files (Step 3)
    4.   Capture METRICS baseline (Step 4)
    5.   Create documentation stubs (Step 5)
    6.   Finalise and remove SETUP.md (Step 6)

Proceeding in 10 seconds unless you say "wait" or "stop".
```

Wait the stated period (or for an explicit "go ahead") before starting Step 1.

---

## Step 1 — Discover the project

Read every project manifest file present in the repo root:

- `package.json` → language = TypeScript/JavaScript, runtime, test framework, scripts
- `pyproject.toml` / `setup.cfg` / `requirements.txt` → language = Python
- `Cargo.toml` → language = Rust
- `go.mod` → language = Go
- `pom.xml` / `build.gradle` → language = Java/Kotlin
- `Makefile` → extract test, build, lint targets
- `README.md` → project name, description, purpose

For each manifest found, extract and record:

| Placeholder | Where to find it |
|-------------|------------------|
| `{{PROJECT_NAME}}` | `package.json:name`, `Cargo.toml:[package].name`, `pyproject.toml:[project].name`, or repo name |
| `{{LANGUAGE}}` | Infer from manifest type; confirm with dominant file extension in `src/` or equivalent |
| `{{RUNTIME}}` | `package.json:engines`, or Node/Bun/Deno version, or Python version, etc. |
| `{{PACKAGE_MANAGER}}` | Presence of `bun.lockb`→Bun, `pnpm-lock.yaml`→pnpm, `yarn.lock`→Yarn, `package-lock.json`→npm, `uv.lock`→uv, etc. |
| `{{TEST_COMMAND}}` | `package.json:scripts.test`, `Makefile:test` target, `pyproject.toml:[tool.pytest.ini_options]`, etc. |
| `{{TYPE_CHECK_COMMAND}}` | `package.json:scripts.typecheck` / `check:types`, or `mypy src/`, or `cargo check`, etc. If none found, set to `echo "no type check configured"` |
| `{{LOC_COMMAND}}` | `package.json:scripts.check:loc` or `check:lines`, or `find src -name '*.{{EXT}}' \| xargs wc -l \| sort -n` |
| `{{THREE_CHECK_COMMAND}}` | Compose from TEST + TYPE_CHECK + LOC: `<test> && <typecheck> && <loc>` |
| `{{METRICS_COMMAND}}` | `package.json:scripts.kaizen` / `metrics`, or `make metrics`, or compose a one-liner |
| `{{LOC_WARN_THRESHOLD}}` | Default **250** unless existing codebase median file size suggests otherwise |
| `{{LOC_HIGH_THRESHOLD}}` | Default **400** |
| `{{DEP_BUDGET}}` | Count current runtime deps; use that count + 2 as the budget (min 6) |
| `{{DEP_BUDGET_WARN}}` | `{{DEP_BUDGET}}` + 2 |
| `{{TEST_FRAMEWORK}}` | From manifest devDependencies or test imports |
| `{{INTEGRATION_TEST_ENV_VAR}}` | Look for env-gated tests; default `INTEGRATION_TESTS=1` |
| `{{PREFERRED_SERIALISATION}}` | Default `JSON`; adjust if project uses YAML/MessagePack/Protobuf predominantly |
| `{{SUBAGENT_MAX_DEPTH}}` | Default `3` |
| `{{VALUE_STREAM_DESCRIPTION}}` | One sentence describing the main flow of value through the system (e.g., "User request → processing → response") |
| `{{FLOW_DESCRIPTION}}` | One sentence on how the system creates flow (e.g., "stream output; fast feedback loops") |
| `{{PROJECT_CORE_VALUE}}` | Noun phrase from README — what the project ultimately delivers to the user |
| `{{SETUP_DATE}}` | Today's date in ISO 8601 format |
| `{{EXTRA_METRIC_NAME}}` | If a domain-specific metric is obvious (e.g., "API response time"), add it; otherwise delete this row |

If a value cannot be determined, leave the `{{PLACEHOLDER}}` as-is and add a comment: `<!-- TODO: fill {{PLACEHOLDER}} once known -->`.

---

## Step 2 — Populate the instructions file

> **Skip this step** if Step 0a resulted in **Delete** — the template file was already written fresh in that path. Jump to Step 2.5.

1. Open `.github/copilot-instructions.md` (the template fetched during remote bootstrap, or the merged file if Merge was chosen, or the local copy if running in local mode).
2. Replace every remaining `{{PLACEHOLDER}}` with the resolved value from Step 1.
3. In the **Project-Specific Overrides** table (§10), fill the "Resolved value" column.
4. In the Lean Principles table (§1), update Principle 2 to `{{VALUE_STREAM_DESCRIPTION}}` and Principle 3 to `{{FLOW_DESCRIPTION}}`.
5. In §4 Coding Conventions, replace `{{CODING_PATTERNS}}` with a bullet list of the top 3–5 patterns observed in the existing source (or "*(to be discovered)*" for a new project).
6. Append the **User Preferences** block constructed in Step 0d to §10.
7. Save the file.

---

## Step 2.5 — Write agent files

> **VS Code users (1.106+)**: These files add model-pinned agents to the Copilot agent dropdown. When a user selects an agent, VS Code automatically switches to the pinned model for that session. **Skip this step** if the user is not using VS Code — the Model Quick Reference table at the top of the instructions file provides advisory guidance for other IDEs.

Create `.github/agents/` if it does not exist. Then write the four agent files using one of the following approaches:

- **Fetch from template** *(recommended)*: Fetch each file directly from the template repo and substitute `{{PROJECT_NAME}}` in the content. This ensures you always get the latest model identifiers without relying on the inline stubs below.

  ```text
  https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/setup.agent.md
  https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/coding.agent.md
  https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/review.agent.md
  https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/agents/fast.agent.md
  ```

- **Write from stubs**: Use the inline content below. Model identifiers may lag behind the live template repo; prefer the fetch option when network access is available.

> **Model identifier note**: The `model` arrays use display names exactly as shown in the VS Code Copilot model picker. Each entry is tried in order — VS Code uses the first model that is available on the user's plan. If a model fails to load at runtime, verify the exact display name in the picker and update the `model` field to match. Model names change as GitHub releases and retires models; review and update these files during template update runs.

### `.github/agents/setup.agent.md`

First-time setup, onboarding, and template operations. Claude Sonnet 4.6 is chosen for its strong instruction-following and nuanced context management. 1× multiplier, available on Pro+; falls back to Claude Sonnet 4.5 (also 1×) then GPT-5.1 for Free plan users.

```markdown
---
name: Setup
description: First-time setup, onboarding, and template operations — uses Claude Sonnet 4.6
model:
  - Claude Sonnet 4.6
  - Claude Sonnet 4.5
  - GPT-5.1
  - GPT-5 mini
tools: [editFiles, fetch, githubRepo, codebase]
---

You are the Setup agent for {{PROJECT_NAME}}.

Your role: run first-time project setup, populate the Copilot instructions template,
and handle template update or restore operations.

Guidelines:
- Follow `.github/copilot-instructions.md` at all times.
- Complete all pre-flight checks before writing any file.
- Prefer small, incremental file writes over large one-shot changes.
- Always confirm the pre-flight summary with the user before writing.
- Do not modify files in `asafelobotomy/copilot-instructions-template` — that is
  the template repo; all writes go to this project.
- CRITICAL: The §0d interview is interactive. Ask every question and wait for
  the user’s typed answer. Never auto-complete, assume, or skip questions.
- Use the batch plan in §0d to structure `ask_questions` calls (max 4 per call).
- Verify answer count matches the selected tier before proceeding to §0e.
- Copy the §0e and Step 6 summary templates exactly — do not improvise or
  omit sections.
```

### .github/agents/coding.agent.md

Implementation, refactoring, and multi-step coding workflows. GPT-5.3-Codex is GitHub's latest agentic coding model (GA Feb 9 2026 — 25% faster than GPT-5.2-Codex, real-time mid-task steering, 1× multiplier, Pro+). Falls back cleanly through the Codex lineage. Includes a handoff to the Review agent.

```markdown
---
name: Code
description: Implementation, refactoring, and multi-step coding — uses GPT-5.3-Codex
model:
  - GPT-5.3-Codex
  - GPT-5.2-Codex
  - GPT-5.1-Codex
  - GPT-5.1
  - GPT-5 mini
tools: [editFiles, terminal, codebase, githubRepo, runCommands]
handoffs:
  - label: Review changes
    agent: review
    prompt: >
      Review the changes just made for quality, correctness, and
      Lean/Kaizen alignment. Tag all findings with waste categories.
    send: false
---

You are the Coding agent for {{PROJECT_NAME}}.

Your role: implement features, refactor code, and run multi-step development tasks.

Guidelines:
- Follow `.github/copilot-instructions.md` at all times — especially §2 (Implement
  Mode) and §3 (Standardised Work Baselines).
- Full PDCA cycle is mandatory for every non-trivial change.
- Run the three-check ritual before marking any task done.
- Write or update tests alongside every change — never after.
- Update `BIBLIOGRAPHY.md` if a file is created, renamed, or deleted.
```

### `.github/agents/review.agent.md`

Deep code review and architectural analysis. Claude Opus 4.6 is Anthropic's most capable model (3× multiplier — reserve for genuinely complex reviews). Its "Agent Teams" capability (parallel sub-task delegation to specialised virtual agents) makes it uniquely suited for Lean/Kaizen architectural review. Claude Sonnet 4.6 (1×) is the first fallback for lighter workloads. Read-only by default; includes a handoff to the Coding agent.

```markdown
---
name: Review
description: Deep code review and architectural analysis — uses Claude Opus 4.6
model:
  - Claude Opus 4.6
  - Claude Opus 4.5
  - Claude Sonnet 4.6
  - GPT-5.1
tools: [codebase, githubRepo]
handoffs:
  - label: Implement fixes
    agent: coding
    prompt: >
      Implement the fixes and improvements identified in the review.
      Address critical and major findings first.
    send: false
---

You are the Review agent for {{PROJECT_NAME}}.

Your role: analyse code quality, architectural correctness, and Lean/Kaizen alignment.
This is a read-only role — do not modify files unless explicitly instructed.

Guidelines:
- Follow §2 Review Mode in `.github/copilot-instructions.md`.
- Tag every finding with a waste category from §6 (Muda).
- Reference specific file paths and line numbers for every finding.
- Structure output per finding: [severity] | [file:line] | [waste category] | [description]
- Severity levels: critical | major | minor | advisory
```

### `.github/agents/fast.agent.md`

Quick questions, syntax lookups, and single-file lightweight edits. Claude Haiku 4.5 (0.33×) and Grok Code Fast 1 (0.25×) are optimised for speed and low cost. Falls back to zero-cost models for Free plan users.

```markdown
---
name: Fast
description: Quick questions and lightweight single-file tasks — uses Claude Haiku 4.5
model:
  - Claude Haiku 4.5
  - Grok Code Fast 1
  - GPT-5 mini
  - GPT-4.1
tools: [codebase, editFiles]
---

You are the Fast agent for {{PROJECT_NAME}}.

Your role: quick answers, syntax lookups, and lightweight edits confined to a
single file or small scope.

Guidelines:
- Follow `.github/copilot-instructions.md`.
- Keep responses concise — code first, one-line explanation.
- If the task spans more than 2 files or has architectural impact, say so and
  suggest switching to the Code or Review agent instead.
- Do not run the full PDCA cycle for simple edits — just make the change and
  summarise in one line.
```

---

## Step 2.8 — Scaffold skill library

Create `.github/skills/` if it does not exist. Then copy the four starter skills from the template:

- **Fetch from template** *(recommended)*: Fetch each skill directly from the template repo:

  ```text
  https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/skills/skill-creator/SKILL.md
  https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/skills/fix-ci-failure/SKILL.md
  https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/skills/lean-pr-review/SKILL.md
  https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/skills/conventional-commit/SKILL.md
  ```

- **Write from stubs**: Use the inline content below if network access is unavailable.

For each skill, create `.github/skills/<name>/SKILL.md` in the user's project with the fetched or inline content. Substitute `{{PROJECT_NAME}}` if it appears.

### Starter skills

| Skill | What it does |
|-------|-------------|
| `skill-creator` | Meta-skill — teaches the agent how to author new skills following §12 |
| `fix-ci-failure` | Systematic CI/GitHub Actions failure diagnosis and resolution |
| `lean-pr-review` | Structured PR review using Lean waste categories (§6) and severity ratings |
| `conventional-commit` | Write commit messages following the Conventional Commits specification |

Set the `{{SKILL_SEARCH_PREFERENCE}}` placeholder value based on the A15 interview answer (default: `local-only`).

---

## Step 2.9 — Scaffold path-specific instruction files

Path-specific instruction files let Copilot apply different rules to different parts of the codebase. Each file uses `applyTo:` frontmatter with glob patterns.

1. Detect which instruction stubs are relevant based on the project structure discovered in Step 1:
   - **tests** — scaffold if any `*.test.*`, `*.spec.*`, `tests/`, or `__tests__/` directories exist.
   - **api-routes** — scaffold if any `api/`, `routes/`, `controllers/`, or `handlers/` directories exist.
   - **config** — scaffold if any `*.config.*` or `.*rc` files exist.
   - **docs** — scaffold if any `*.md` files or `docs/` directory exists (almost always true).
2. For each relevant stub, fetch from the template repo:

   ```text
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/instructions/tests.instructions.md
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/instructions/api-routes.instructions.md
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/instructions/config.instructions.md
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/instructions/docs.instructions.md
   ```

3. Create `.github/instructions/` in the user's project. Write each relevant file, substituting any `{{PLACEHOLDER}}` tokens with resolved values from Step 1.
4. Skip any stub whose `applyTo:` glob matches no files in the project.
5. Log each created file to JOURNAL.md.

---

## Step 2.10 — Scaffold prompt files

Prompt files become reusable slash commands in VS Code Copilot chat (e.g. `/explain`, `/refactor`).

1. Fetch all starter prompt files from the template repo:

   ```text
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/prompts/explain.prompt.md
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/prompts/refactor.prompt.md
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/prompts/test-gen.prompt.md
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/prompts/review-file.prompt.md
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/.github/prompts/commit-msg.prompt.md
   ```

2. Create `.github/prompts/` in the user's project. Write all five files, substituting any `{{PLACEHOLDER}}` tokens with resolved values from Step 1.
3. Log each created file to JOURNAL.md.

| Prompt | Slash command | What it does |
|--------|--------------|-------------|
| `explain.prompt.md` | `/explain` | Waste-aware code explanation |
| `refactor.prompt.md` | `/refactor` | Lean-principled refactoring with PDCA |
| `test-gen.prompt.md` | `/test-gen` | Generate tests following project conventions |
| `review-file.prompt.md` | `/review-file` | Single-file review using §2 Review Mode |
| `commit-msg.prompt.md` | `/commit-msg` | Conventional Commits message authoring |

---

## Step 2.11 — Scaffold Copilot setup steps workflow

The `copilot-setup-steps.yml` workflow runs before the GitHub Copilot coding agent starts a task, setting up the project environment.

1. Detect the project runtime from Step 1 (Node.js, Python, Go, Rust, Java, .NET, etc.).
2. Fetch the template:

   ```text
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/copilot-setup-steps.yml
   ```

3. Create `.github/workflows/copilot-setup-steps.yml` in the user's project.
4. Uncomment and populate the section matching the detected runtime:
   - Set `{{RUNTIME_VERSION}}` from Step 1 discovery.
   - Set `{{INSTALL_COMMAND}}`, `{{BUILD_COMMAND}}`, `{{TEST_COMMAND}}` from resolved placeholders.
5. Remove commented-out sections for other runtimes.
6. Log the created file to JOURNAL.md.

> **Release automation** (optional next step): If you want automated GitHub Releases for this project, the template provides two release strategies — a manual VERSION-bump approach and a Conventional Commits-based approach using release-please. See `docs/RELEASE-AUTOMATION-GUIDE.md` in the template repo for a trade-off comparison and full configuration instructions. If you adopt the release-please strategy, also scaffold `release-please-config.json` and `.release-please-manifest.json` at the project root (exact content is in the guide).

---

## Step 2.12 — Configure MCP servers

> **Skip this step** if the E22 interview answer was **A — None** (default). Proceed directly to Step 3.

The Model Context Protocol (MCP) connects Copilot to external tools via `.vscode/mcp.json`. This step scaffolds the configuration based on the user's E22 preference.

1. Fetch the MCP configuration template:

   ```text
   https://raw.githubusercontent.com/asafelobotomy/copilot-instructions-template/main/template/vscode/mcp.json
   ```

2. Create `.vscode/mcp.json` in the user's project with the fetched content.

3. Configure based on E22 answer:

   | E22 answer | Always-on servers | Credentials servers | Stack-specific |
   |------------|-------------------|--------------------:|----------------|
   | B — Always-on only | Enable filesystem, memory, git | Keep disabled | Skip |
   | C — Full configuration | Enable all | Enable github + fetch (prompt for token) | Discover and suggest |

4. **Stack-specific server discovery** (E22=C only): Based on the technology stack discovered in Step 1, suggest relevant MCP servers:

   | Stack signal | Suggested MCP server | Package |
   |-------------|---------------------|---------|
   | PostgreSQL (`pg`, `psycopg2`, `prisma`) | PostgreSQL server | `@modelcontextprotocol/server-postgres` |
   | SQLite (`sqlite3`, `better-sqlite3`) | SQLite server | `@modelcontextprotocol/server-sqlite` |
   | Redis (`redis`, `ioredis`) | Redis server | `@nicholasoxford/redis-mcp-server` |
   | Docker (`Dockerfile`, `docker-compose`) | Docker server | `docker-mcp-server` |
   | AWS (`aws-sdk`, `boto3`) | AWS server | `@aws/mcp-server-aws` |
   | Puppeteer / browser testing | Puppeteer server | `@modelcontextprotocol/server-puppeteer` |

   For each suggested server, ask the user if they want to add it. Add confirmed servers to `.vscode/mcp.json`.

5. Populate §13 placeholders in `.github/copilot-instructions.md`:
   - `{{MCP_STACK_SERVERS}}`: Table rows for any stack-specific servers added, or *(empty)* if none.
   - `{{MCP_CUSTOM_SERVERS}}`: Any additional custom server entries, or *(empty)* if none.

6. Log the created file to JOURNAL.md.

---

## Step 3 — Scaffold workspace identity files

> Apply the decisions made in Step 0b (keep / overwrite / selective).

Create the directory `.copilot/workspace/` if it does not exist. For each file below, create it **unless Step 0b determined that file should be kept**. Substitute all resolved placeholder values.

### `.copilot/workspace/IDENTITY.md`

```markdown
# Agent Identity — {{PROJECT_NAME}}

I am the Copilot agent for **{{PROJECT_NAME}}**. My role is to help build, maintain, and improve this project according to the Lean/Kaizen methodology described in `.github/copilot-instructions.md`.

*(This file is updated by me as I develop a clearer understanding of the project.)*
```

### `.copilot/workspace/SOUL.md`

```markdown
# Values & Reasoning Patterns — {{PROJECT_NAME}}

Core values I apply to every decision in this project:

- **YAGNI** — I do not build what is not needed today.
- **Small batches** — A 50-line PR is better than a 500-line PR.
- **Explicit over implicit** — Naming, types, and docs should remove ambiguity, not add it.
- **Reversibility** — I prefer decisions that can be undone.
- **Baselines** — I measure before and after any significant change.

*(Updated as reasoning patterns emerge.)*
```

### `.copilot/workspace/USER.md`

```markdown
# User Profile — {{PROJECT_NAME}}

| Attribute | Observed value |
|-----------|---------------|
| Communication style | *(to be discovered)* |
| Domain expertise | *(to be discovered)* |
| Preferences | *(to be discovered)* |
| Working hours / pace | *(to be discovered)* |
| Preferred review depth | *(to be discovered)* |

*(Updated as I learn through interaction.)*
```

### `.copilot/workspace/TOOLS.md`

```markdown
# Tool Usage Patterns — {{PROJECT_NAME}}

| Tool / command | Effective usage pattern |
|----------------|-------------------------|
| `{{TEST_COMMAND}}` | Run after every change; treat red as blocking |
| `{{TYPE_CHECK_COMMAND}}` | Run after every type definition change |
| `{{THREE_CHECK_COMMAND}}` | Three-check ritual — run before marking a task done |

*(Updated as effective workflows are discovered.)*
```

### `.copilot/workspace/MEMORY.md`

```markdown
# Memory Strategy — {{PROJECT_NAME}}

- Use project-scoped memory for conventions discovered in this codebase.
- Use session transcripts for recent context; do not rely on long-term memory for facts that are in source files.
- Always prefer reading the source file over recalling a cached summary of it.

*(Updated as the memory system is used.)*
```

### `.copilot/workspace/BOOTSTRAP.md`

```markdown
# Bootstrap Record — {{PROJECT_NAME}}

This workspace was scaffolded on **{{SETUP_DATE}}** using the [copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template).

## Initial stack

- Language: {{LANGUAGE}}
- Runtime: {{RUNTIME}}
- Package manager: {{PACKAGE_MANAGER}}
- Test framework: {{TEST_FRAMEWORK}}

## What was created

- `.github/copilot-instructions.md` — instructions populated from template
- `.github/agents/setup.agent.md` — model-pinned Setup agent (Claude Sonnet 4.6)
- `.github/agents/coding.agent.md` — model-pinned Coding agent (GPT-5.3-Codex)
- `.github/agents/review.agent.md` — model-pinned Review agent (Claude Opus 4.6)
- `.github/agents/fast.agent.md` — model-pinned Fast agent (Claude Haiku 4.5)
- `.github/skills/` — reusable agent skill library (§12)
- `.copilot/workspace/` — all seven identity files
- `CHANGELOG.md` — Keep-a-Changelog stub
- `JOURNAL.md` — ADR journal with setup entry
- `BIBLIOGRAPHY.md` — file catalogue with initial snapshot
- `METRICS.md` — baseline snapshot for this date

*(This file is not updated after setup. It is a permanent record of origin.)*
```

### `.copilot/workspace/HEARTBEAT.md`

```markdown
# Heartbeat — {{PROJECT_NAME}}

> Event-driven health check. Read this file at every trigger event, run all checks, update Pulse, and log to History.
> **Contract**: Follow this checklist strictly. Do not infer tasks from prior sessions.

## Pulse

`HEARTBEAT_OK` — No alerts.

## Event Triggers

Fire a heartbeat when any of these occur:

- **Session start** — always
- **Large change** — modified >5 files in a single task
- **Refactor/migration** — task tagged as refactor, migration, or restructure
- **Dependency update** — any manifest changed (package.json, Cargo.toml, requirements.txt, go.mod, etc.)
- **CI resolution** — after resolving a CI failure
- **Explicit** — user says "Check your heartbeat"
<!-- Add custom triggers below this line -->

## Checks

Run each check; prepend `[!]` to Pulse if any fails:

- [ ] **Dependency audit** — any outdated or security-advisory deps in TOOLS.md / manifests?
- [ ] **Test coverage delta** — did coverage drop since last METRICS.md row?
- [ ] **Waste scan** — any new W1–W16 waste accumulated this session? (§6)
- [ ] **MEMORY.md consolidation** — anything from this session to persist?
- [ ] **METRICS.md freshness** — baseline older than 3 sessions?
- [ ] **Settings drift** — do §10 overrides still match the codebase?
<!-- Add custom checks below this line -->

## Agent Notes

*(Agent-writable. Observations, patterns, and items to flag on next heartbeat.)*

## History

*(Append-only. Keep last 5 entries.)*

| Date | Trigger | Result | Actions taken |
|------|---------|--------|---------------|
```

---

## Step 4 — Capture an initial METRICS baseline

> Apply the decision from Step 0c. If `METRICS.md` already exists and the user chose **skip**, do not append. If they chose **append entries**, add a new row.

Create `METRICS.md` in the repo root if it does not exist, using the stub below.

Then:

1. Count source files and total LOC (`find`/`wc` or `{{LOC_COMMAND}}`).
2. Count tests from the last test run output, or estimate as "N/A".
3. Count runtime dependencies from the manifest.
4. Append a row:

```text
| {{SETUP_DATE}} | Setup baseline | <total_loc> | <file_count> | <test_count> | <assertion_count_or_NA> | 0 | <dep_count> |
```

**METRICS.md stub** (use only if the file does not exist):

```markdown
# Metrics — {{PROJECT_NAME}}

Kaizen baseline snapshots. Append a row after any session that materially changes LOC, test count, or dependency count.

| Date | Phase | LOC (total) | Files | Tests | Assertions | Type errors | Runtime deps |
|------|-------|-------------|-------|-------|------------|-------------|--------------|
| {{SETUP_DATE}} | Setup baseline | — | — | — | — | 0 | — |
```

---

## Step 5 — Create documentation stubs

> Apply the decision from Step 0c (skip / overwrite / append entries / create missing only).

For each file, act according to the Step 0c decision. The content to create or append is shown below.

### `CHANGELOG.md`

```markdown
# Changelog

All notable changes to {{PROJECT_NAME}} will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Copilot instructions scaffolded from [copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template).
```

### `JOURNAL.md`

```markdown
# Development Journal — {{PROJECT_NAME}}

Architectural decisions and context are recorded here in ADR style.

---

## {{SETUP_DATE}} — Project onboarded to copilot-instructions-template

**Context**: This project adopted the generic Lean/Kaizen Copilot instructions template.
**Decision**: Use `.github/copilot-instructions.md` as the primary agent guidance document, with `.copilot/workspace/` for session-persistent identity state.
**Consequences**: Copilot is authorised to update the instructions file when patterns stabilise (see Living Update Protocol).
```

### `BIBLIOGRAPHY.md`

```markdown
# Bibliography — {{PROJECT_NAME}}

Every file in the project is catalogued here. Update this file whenever a file is created, renamed, deleted, or its purpose changes significantly.

| File | Purpose | LOC |
|------|---------|-----|
| `.github/copilot-instructions.md` | AI agent guidance (Lean/Kaizen methodology + project conventions) | — |
| `.github/agents/setup.agent.md` | Model-pinned Setup agent — Claude Sonnet 4.6 (onboarding & template ops) | — |
| `.github/agents/coding.agent.md` | Model-pinned Coding agent — GPT-5.3-Codex (implementation & refactoring) | — |
| `.github/agents/review.agent.md` | Model-pinned Review agent — Claude Opus 4.6 (code review & architecture) | — |
| `.github/agents/fast.agent.md` | Model-pinned Fast agent — Claude Haiku 4.5 (quick tasks & lookups) | — |
| `.copilot/workspace/IDENTITY.md` | Agent self-description | — |
| `.copilot/workspace/SOUL.md` | Agent values & reasoning patterns | — |
| `.copilot/workspace/USER.md` | Observed user profile | — |
| `.copilot/workspace/TOOLS.md` | Effective tool usage patterns | — |
| `.copilot/workspace/MEMORY.md` | Memory system strategy | — |
| `.copilot/workspace/BOOTSTRAP.md` | Permanent setup origin record | — |
| `.github/skills/*/SKILL.md` | Reusable agent skill library (§12) | — |
| `CHANGELOG.md` | Keep-a-Changelog | — |
| `JOURNAL.md` | ADR-style development journal | — |
| `BIBLIOGRAPHY.md` | This file — complete file map | — |
| `METRICS.md` | Kaizen baseline snapshot table | — |

*(Add all project source files below this line.)*
```

### `METRICS.md`

See Step 4 for the stub — do not duplicate it here.

---

## Step 6 — Finalise and self-destruct

1. **Review** everything created or modified and print a structured summary to the user.

   > **Output the template below exactly.** Include the AGENT FILES and SKILLS sections.
   > List all 22 preference dimensions under USER PREFERENCES. Do not omit sections or improvise the layout.

   ```text
   Setup complete. Here is what was done:

   INSTRUCTIONS
     Action taken:        [archived / deleted / merged / created fresh]
     Archive location:    [.github/archive/... or N/A]
     Placeholders filled: <N> of <total>
     Placeholders unresolved: <list or "none">
     Merge conflicts:     <N resolved, N deferred or "none">

   AGENT FILES  (VS Code 1.106+ only)
     Created:  .github/agents/setup.agent.md   (Claude Sonnet 4.6 → fallback chain)
               .github/agents/coding.agent.md  (GPT-5.3-Codex → fallback chain)
               .github/agents/review.agent.md  (Claude Opus 4.6 → fallback chain)
               .github/agents/fast.agent.md    (Claude Haiku 4.5 → fallback chain)
     Skipped:  [list any skipped, or "none"]
     Note:     Model identifiers may need updating if models are retired.
               Run "Update your instructions" periodically to refresh recommendations.

   SKILLS
     Directory: .github/skills/
     Scaffolded: <list of skills created, or "none">
     Search preference: <local-only / official-only / official-and-community>

   MCP CONFIGURATION
     .vscode/mcp.json: [created / skipped (E22=None)]
     Always-on servers: <list or "N/A">
     Stack-specific servers: <list or "none">

   WORKSPACE IDENTITY FILES
     Created: <list>
     Skipped (kept existing): <list>

   DOCUMENTATION STUBS
     Created: <list>
     Appended to: <list>
     Skipped: <list>

   METRICS
     Initial baseline row appended: [yes / skipped]

   USER PREFERENCES
     <table of all 22 dimensions with labels>

   ANOMALIES
     <any decisions made that the user should verify, or "none">
   ```

2. Ask the user: *"Setup is complete. Shall I delete SETUP.md now?"*
3. On confirmation, delete `SETUP.md`.
4. Append to `JOURNAL.md`:

   ```text
   [instructions] Setup complete — SETUP.md removed. See BOOTSTRAP.md for origin record.
   ```

---

> **Note for Copilot**: The `template/` directory in this repo (if present) contains canonical stub files. Read them for reference but use the content in this SETUP.md as the authoritative source, since it has placeholders pre-contextualised for the setup flow.
