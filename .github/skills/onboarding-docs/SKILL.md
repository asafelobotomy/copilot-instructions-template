---
name: onboarding-docs
description: Generate or update onboarding documentation — README, CONTRIBUTING guide, dev environment setup script, and new-developer validation checklist
compatibility: ">=0.7.0"
---

# Onboarding Docs

> Skill metadata: version "1.0"; license MIT; tags [docs, onboarding, readme, contributing, setup]; compatibility ">=0.7.0"; recommended tools [codebase, editFiles, runCommands].

Generate clear, actionable onboarding documentation so a new developer can go from zero to a working dev environment in under 30 minutes.

## When to use

- User asks to "write a README", "add a CONTRIBUTING guide", "document setup steps", or "write onboarding docs"
- A new team member struggles to get the project running from the README alone
- README is stale, missing, or omits key setup steps

## When not to use

- API reference documentation (Swagger, JSDoc, Rustdoc) — those are code-generated; document the *process*, not the API surface

## Steps

### 1. Audit what exists

Check for and read:

- `README.md` — overview, setup, usage, links
- `CONTRIBUTING.md` — contribution workflow, conventions, PR process
- `docs/` directory
- Inline setup scripts (`setup.sh`, `Makefile`, `justfile`)

Note what is missing, outdated, or unclear.

### 2. Write (or update) README.md

Sections in order:

```markdown
# Project Name

One-sentence description.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Node.js | ≥22 | https://nodejs.org |
| Docker | ≥25 | https://docker.com |

## Quick Start

\`\`\`bash
git clone https://github.com/org/repo
cd repo
cp .env.example .env      # fill in required values
npm install
npm run dev               # starts at http://localhost:3000
\`\`\`

## Project Structure

\`\`\`
src/
  api/       — HTTP handlers
  services/  — Business logic
  models/    — Data access
tests/       — Test suites
docs/        — Extended documentation
\`\`\`

## Available Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server with hot reload |
| `npm test` | Run test suite |
| `npm run lint` | Run linter |
| `npm run build` | Build for production |

## Environment Variables

See `.env.example` for all required variables and descriptions.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
```

Rules:
- Every command in the README must work when copy-pasted
- Version requirements must be specific (not "latest")
- No setup steps that require tribal knowledge or Slack messages

### 3. Write CONTRIBUTING.md

```markdown
# Contributing

## Development workflow

1. Fork and clone the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make changes, write tests
4. Commit with conventional commits: `feat(scope): description`
5. Push and open a PR against `main`

## Commit style

Follow [Conventional Commits](https://conventionalcommits.org):
- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `refactor:` — no behaviour change
- `test:` — test additions or fixes
- `chore:` — tooling, CI, dependencies

## Code style

- Run `npm run lint` before committing
- All new code must have tests
- PRs require at least one review before merging

## Branching

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code |
| `feat/*` | New features |
| `fix/*` | Bug fixes |
| `docs/*` | Documentation |

## Running tests

\`\`\`bash
npm test              # run all tests
npm test -- --watch  # watch mode
\`\`\`

## PR checklist

- [ ] Tests pass locally
- [ ] Linter passes
- [ ] CHANGELOG updated (if user-facing change)
- [ ] PR description explains *why*, not just *what*
```

### 4. Create a setup validation script

Provide a script that confirms the environment is ready:

```bash
#!/usr/bin/env bash
set -euo pipefail

# scripts/check-dev-env.sh — run after first setup to validate everything works

OK=true

check() {
  local name="$1" cmd="$2" expected="$3"
  if version=$(eval "$cmd" 2>&1); then
    echo "✓ $name: $version"
  else
    echo "✗ $name not found — install from $expected"
    OK=false
  fi
}

check "Node.js" "node --version" "https://nodejs.org"
check "npm"     "npm --version"  "bundled with Node.js"
check "Docker"  "docker --version" "https://docker.com"

if [[ "$OK" == "false" ]]; then
  echo ""
  echo "Some requirements are missing. See README Prerequisites."
  exit 1
fi

echo ""
echo "✓ All prerequisites met. Run: npm install && npm run dev"
```

### 5. New-developer checklist

Add a checklist to README or CONTRIBUTING:

```markdown
## New developer checklist

- [ ] Prerequisites installed and verified (`bash scripts/check-dev-env.sh`)
- [ ] `.env` created from `.env.example` with real values
- [ ] Dependencies installed (`npm install`)
- [ ] Dev server starts without errors (`npm run dev`)
- [ ] Test suite passes (`npm test`)
- [ ] Linter passes (`npm run lint`)
- [ ] Read CONTRIBUTING.md
- [ ] Made one small change and opened a draft PR (optional but recommended)
```

### 6. Validate the docs

Test the README literally — follow every step from a clean environment. Fix anything that does not work exactly as written.

```bash
# Smoke test — does the quick start actually work?
# In a fresh directory, follow the README step by step
```

## Verify

- [ ] Quick Start section works copy-paste without tribal knowledge
- [ ] All commands in README are tested and produce the expected output
- [ ] CONTRIBUTING covers commit style, branch naming, and PR requirements
- [ ] Environment variable requirements link to `.env.example`
- [ ] Setup validation script exits 0 in a clean environment
