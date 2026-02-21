# Path-Specific Instructions Guide

> How `.github/instructions/*.instructions.md` files work and when to use them.

---

## What are path-specific instructions?

Path-specific instruction files let Copilot apply **different rules to different parts of the codebase**. They augment — not replace — the main `.github/copilot-instructions.md` file.

Each file uses an `applyTo:` front matter field with glob patterns. When Copilot edits a file matching a pattern, it loads the corresponding path-specific instructions **in addition to** the main instructions.

---

## Where they live

```text
.github/instructions/
├── tests.instructions.md          # Rules for test files
├── api-routes.instructions.md     # Rules for API route handlers
├── config.instructions.md         # Rules for configuration files
└── docs.instructions.md           # Rules for documentation
```

---

## Anatomy of an instruction file

Every path-specific instruction file has three parts:

### 1. YAML front matter

```yaml
---
applyTo: "**/*.test.*,**/*.spec.*,**/tests/**,**/test/**,**/__tests__/**"
---
```

The `applyTo` field accepts comma-separated glob patterns. Copilot evaluates these against the file path being edited.

### 2. Title

A Markdown `#` heading naming the context (e.g., `# Test file conventions`).

### 3. Instructions

Numbered rules, bullet lists, or prose. These are injected into Copilot's context alongside the main instructions when a matching file is being edited.

---

## Glob pattern reference

| Pattern | Matches |
|---------|---------|
| `**/*.test.*` | Any file with `.test.` in the name at any depth |
| `**/api/**` | Any file under an `api/` directory at any depth |
| `**/*.config.*` | Any config file (e.g., `jest.config.ts`, `vite.config.js`) |
| `**/*.md` | Any Markdown file at any depth |
| `src/**/*.ts` | TypeScript files specifically under `src/` |

Multiple patterns are comma-separated in the `applyTo` field.

---

## Precedence rules

1. **Main instructions always apply** — `.github/copilot-instructions.md` is loaded for every file.
2. **Path instructions augment** — matching instructions are added on top.
3. **Multiple matches stack** — if a file matches more than one instruction file, all matching instructions are loaded.
4. **No overrides** — path instructions cannot contradict or disable rules from the main file. If there is a conflict, the main file takes precedence.

---

## Starter stubs

The setup process scaffolds four instruction files based on your project structure:

| File | Scaffolded when |
|------|----------------|
| `tests.instructions.md` | `*.test.*`, `*.spec.*`, `tests/`, or `__tests__/` directories exist |
| `api-routes.instructions.md` | `api/`, `routes/`, `controllers/`, or `handlers/` directories exist |
| `config.instructions.md` | `*.config.*` or `.*rc` files exist |
| `docs.instructions.md` | `*.md` files or `docs/` directory exists (almost always true) |

Stubs that don't match your project structure are skipped.

---

## Creating your own

1. Create a new file in `.github/instructions/` with the pattern `<name>.instructions.md`.
2. Add the `applyTo:` front matter with your glob patterns.
3. Write the rules you want applied when those files are edited.
4. Copilot picks it up automatically — no registration step needed.

### Example: database migrations

```markdown
---
applyTo: "**/migrations/**,**/migrate/**"
---

# Database migration conventions

1. Every migration must be reversible — include both `up` and `down` operations.
2. Never modify a migration that has been deployed to production.
3. Use descriptive names: `YYYYMMDDHHMMSS_description.sql`.
4. Test migrations against a fresh database before committing.
```

---

## Tips

- **Keep instructions focused** — each file should cover one context (tests, API, config, etc.). If the instructions are long, your globs might be too broad.
- **Don't duplicate the main file** — path instructions should only add context-specific rules. General rules belong in `.github/copilot-instructions.md`.
- **Test your globs** — create a file matching the pattern and verify Copilot applies the instructions.
- **Update BIBLIOGRAPHY.md** — log new instruction files so they appear in the project catalogue.
