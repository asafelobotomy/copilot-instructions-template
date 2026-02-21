# Prompt Files Guide

> How `.github/prompts/*.prompt.md` files become reusable slash commands in VS Code Copilot chat.

---

## What are prompt files?

Prompt files are Markdown files that define **reusable instructions** Copilot can execute as slash commands. Each `.prompt.md` file in `.github/prompts/` becomes a command you can invoke in the Copilot chat panel.

For example, `.github/prompts/explain.prompt.md` becomes the `/explain` command.

---

## Where they live

```text
.github/prompts/
├── explain.prompt.md        →  /explain
├── refactor.prompt.md       →  /refactor
├── test-gen.prompt.md       →  /test-gen
├── review-file.prompt.md    →  /review-file
└── commit-msg.prompt.md     →  /commit-msg
```

---

## How to use them

1. Open the **Copilot chat panel** in VS Code.
2. Type `/` followed by the prompt name (e.g., `/explain`).
3. VS Code injects the prompt file content as the system instruction for that interaction.
4. Add any additional context after the command (e.g., `/explain this function handles rate limiting`).

---

## Starter prompts

The setup process scaffolds five starter prompt files:

| Command | File | What it does |
|---------|------|-------------|
| `/explain` | `explain.prompt.md` | Waste-aware code explanation using §6 waste categories |
| `/refactor` | `refactor.prompt.md` | Lean-principled refactoring with full PDCA cycle |
| `/test-gen` | `test-gen.prompt.md` | Generate tests following project conventions and framework |
| `/review-file` | `review-file.prompt.md` | Single-file review using §2 Review Mode protocol |
| `/commit-msg` | `commit-msg.prompt.md` | Conventional Commits message from staged changes |

---

## Anatomy of a prompt file

A prompt file is plain Markdown with a `#` title and numbered instructions:

```markdown
# Explain Code

Explain the selected code. For each significant block:

1. Describe what it does and why.
2. Identify any waste categories from §6 that apply.
3. Flag non-obvious dependencies or side effects.
4. Suggest improvements if the code has clear waste.

Keep the explanation concise. Use bullet points.
```

### Key rules

- **Title**: The `#` heading is the prompt's display name in the command palette.
- **No front matter required**: Unlike instruction files, prompt files don't need YAML front matter.
- **Placeholder tokens**: Use `{{PLACEHOLDER}}` tokens that were resolved during setup (e.g., `{{TEST_FRAMEWORK}}`, `{{TEST_COMMAND}}`).
- **Section references**: Reference `§N` sections from the main instructions file — Copilot will apply them.

---

## Variable substitution

VS Code provides built-in variables you can use in prompt files:

| Variable | Expands to |
|----------|-----------|
| `${file}` | The currently open file path |
| `${selection}` | The currently selected text |
| `${input:varName}` | Prompts the user for input at runtime |

### Example with variables

```markdown
# Fix Bug

Examine the error in ${selection} within ${file}.

1. Identify the root cause.
2. Propose a minimal fix.
3. Write a test covering the fix.
```

---

## Creating your own

1. Create a new file in `.github/prompts/` with the pattern `<name>.prompt.md`.
2. Write a `#` title and the instructions.
3. The filename (minus `.prompt.md`) becomes the slash command.
4. VS Code picks it up automatically.

### Naming conventions

- Use **kebab-case** for filenames: `my-prompt.prompt.md` → `/my-prompt`.
- Keep names short and descriptive — they appear in the command palette.
- Avoid names that conflict with built-in VS Code commands.

### Example: API endpoint generator

```markdown
# Generate API Endpoint

Create a new API endpoint based on the description provided.

1. Follow the project's routing conventions from §4.
2. Include input validation and error handling per §10 preferences.
3. Write a corresponding test file.
4. Update the API documentation if `docs/api/` exists.

Endpoint description: ${input:endpointDescription}
```

---

## Tips

- **Keep prompts focused** — one prompt, one task. Don't create a "do everything" prompt.
- **Reference the instructions** — use `§N` section references so the prompt inherits project conventions.
- **Use placeholders** — `{{TEST_FRAMEWORK}}`, `{{TEST_COMMAND}}`, etc. keep prompts portable across projects.
- **Test with real files** — invoke the command on actual code to verify the output matches your expectations.
- **Update BIBLIOGRAPHY.md** — log new prompt files so they appear in the project catalogue.
