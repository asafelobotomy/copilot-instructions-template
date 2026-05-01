---
name: tech-debt-audit
description: Catalog technical debt in a codebase — TODO/FIXME comments, deprecated API usage, dead code, high-complexity hotspots, and missing tests — then prioritize for action
compatibility: ">=0.7.0"
---

# Tech Debt Audit

> Skill metadata: version "1.0"; license MIT; tags [tech-debt, refactoring, quality, complexity, dead-code]; compatibility ">=0.7.0"; recommended tools [codebase, runCommands, editFiles].

Surface, catalog, and prioritize technical debt in a codebase. Produces an actionable debt register, not just a list of complaints.

## When to use

- User asks to "find tech debt", "audit code quality", "find dead code", or "what needs cleaning up"
- Before a major refactor, to understand scope
- Planning a sprint dedicated to quality improvements

## When not to use

- Security vulnerabilities — use the `security-audit` skill instead
- Dependency updates — use the `dependency-update` skill instead

## Steps

### 1. Scan for annotated debt

Search for common debt markers:

```bash
grep -rn "TODO\|FIXME\|HACK\|XXX\|WORKAROUND\|TEMP\|DEPRECATED\|BUG" \
  --include="*.py" --include="*.ts" --include="*.js" --include="*.go" \
  --include="*.rs" --include="*.java" --include="*.sh" \
  . | grep -v ".git/" | grep -v "node_modules/"
```

Group results by file. Note the author and age if git history is accessible:

```bash
git log --follow -L <line>,<line>:<file> --pretty=format:"%h %ae %ar"
```

Stale TODOs (>6 months old, original author no longer active) are higher priority.

### 2. Find deprecated API usage

| Stack | Command |
|-------|---------|
| Python | `grep -rn "DeprecationWarning\|deprecated"` + run `python -W error::DeprecationWarning` |
| Node.js | `npm ls --depth=0` + check `process.on('deprecation', ...)` warnings |
| Java | Search for `@Deprecated` usages as caller, not declaration |
| Go | `go vet ./...` |
| Any | Search for library APIs marked deprecated in their docs |

### 3. Identify dead code

| Stack | Tool |
|-------|------|
| Python | `vulture .` |
| TypeScript/JS | `ts-prune`, `eslint no-unused-vars` |
| Go | `deadcode ./...` (Go 1.21+) |
| Rust | `cargo check` warns unused (`#[allow(dead_code)]` annotations are a signal) |
| Java | IDE "unused code" inspection or `PMD` `UnusedPrivateMethod` |

Dead code in tests is especially misleading — remove or fix.

### 4. Measure complexity hotspots

High cyclomatic complexity = likely debt:

| Stack | Tool | Threshold |
|-------|------|-----------|
| Python | `radon cc -s . -n C` | ≥10 = high |
| JS/TS | `complexity` ESLint rule | ≥10 = high |
| Go | `gocyclo -over 10 .` | ≥10 = high |
| Java | Checkstyle `CyclomaticComplexity` | ≥10 = high |
| Any | Functions >50 lines are a smell | — |

### 5. Check test coverage gaps

Low-coverage high-complexity code is the most dangerous debt:

```bash
# Python
pytest --cov=src --cov-report=term-missing

# Node.js
npx jest --coverage

# Go
go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out
```

Flag: files with complexity ≥10 AND coverage <50% — these are the riskiest.

### 6. Build the debt register

Produce a prioritized table:

| Priority | Item | File | Type | Age | Effort | Risk |
|----------|------|------|------|-----|--------|------|
| P1 | FIXME: auth bypass workaround | `auth/middleware.py:88` | FIXME | 14 mo | S | High |
| P2 | `parse_legacy()` never called | `utils/parser.ts:142` | Dead code | 8 mo | XS | Low |
| P3 | `OrderService.processAll()` complexity 18 | `services/order.java:203` | Complexity | — | L | Med |

Priority tiers:

- **P1**: Security-adjacent, blocks feature work, or referenced by multiple active TODOs
- **P2**: Dead code or deprecated APIs actively in the call path
- **P3**: Complexity + coverage gaps, stale non-critical TODOs

### 7. Recommend next actions

For each P1 item, propose a specific action (extract, remove, replace). Do not just list problems.

## Verify

- [ ] All four debt categories scanned: annotations, deprecated APIs, dead code, complexity
- [ ] Debt register sorted by priority, not just file order
- [ ] Each P1 item has a proposed action, not just a description
- [ ] Coverage gaps cross-referenced with complexity scores
