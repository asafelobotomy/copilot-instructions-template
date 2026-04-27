---
name: env-config
description: Set up and audit environment variable management — create .env.example, add startup validation, separate secrets from config, and document every variable
compatibility: ">=0.7.0"
---

# Environment Config

> Skill metadata: version "1.0"; license MIT; tags [env, config, secrets, validation, dotenv]; compatibility ">=0.7.0"; recommended tools [codebase, editFiles, runCommands].

Establish a safe, documented environment variable system. Creates `.env.example`, adds startup validation, and ensures secrets never leak into version control.

## When to use

- User asks to "set up .env", "add env validation", "document config variables", or "separate secrets from config"
- A project uses bare `os.getenv()` / `process.env.X` calls without validation
- `.env` is committed or at risk of being committed to version control

## When not to use

- Full secrets management platforms (HashiCorp Vault, AWS Secrets Manager) — this skill covers local + CI .env patterns only

## Steps

### 1. Audit existing variable usage

Scan the codebase for all environment variable reads:

```bash
# Python
grep -rn "os\.getenv\|os\.environ" . --include="*.py" | grep -v ".git/"

# Node.js / TypeScript
grep -rn "process\.env\." . --include="*.ts" --include="*.js" | grep -v "node_modules/"

# Go
grep -rn "os\.Getenv" . --include="*.go"

# Shell
grep -rn "\$[A-Z_]\{3,\}" . --include="*.sh"
```

Collect every variable name. De-duplicate.

### 2. Classify each variable

| Class | Description | Example | Secret? |
|-------|-------------|---------|---------|
| **Secret** | Must never be logged or committed | `DATABASE_PASSWORD`, `API_KEY` | Yes |
| **Config** | Environment-specific, not sensitive | `DATABASE_HOST`, `PORT`, `LOG_LEVEL` | No |
| **Feature flag** | Boolean toggles | `FEATURE_NEW_CHECKOUT=true` | No |
| **Build-time** | Set during CI/CD, not runtime | `BUILD_VERSION`, `COMMIT_SHA` | No |

### 3. Create `.env.example`

Document every variable. Secrets get placeholder values only:

```bash
# .env.example — copy to .env and fill in values
# Required

## Database
DATABASE_URL=postgres://user:password@localhost:5432/mydb
DATABASE_MAX_CONNECTIONS=10

## Auth
JWT_SECRET=<generate with: openssl rand -hex 32>
JWT_EXPIRY_HOURS=24

## External APIs
STRIPE_SECRET_KEY=sk_test_<replace>
STRIPE_WEBHOOK_SECRET=whsec_<replace>

# Optional — defaults shown
LOG_LEVEL=info
PORT=3000
FEATURE_NEW_CHECKOUT=false
```

Rules:

- Every variable must have a comment explaining its purpose
- Secrets use `<replace>` or `<generate with: ...>` as their value — never real values
- Group by concern (database, auth, external APIs, feature flags)

### 4. Update `.gitignore`

Ensure `.env` and its variants are excluded:

```gitignore
# Environment files — never commit
.env
.env.local
.env.*.local
.env.development
.env.production
.env.staging
# Allow example file
!.env.example
```

### 5. Add startup validation

Fail fast if required variables are missing. Add a validation module:

**Python (with pydantic-settings):**

```python
# config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    jwt_secret: str
    port: int = 3000
    log_level: str = "info"

    class Config:
        env_file = ".env"

settings = Settings()  # raises ValidationError on startup if required vars missing
```

**Node.js (with zod):**

```typescript
// config.ts
import { z } from "zod";

const schema = z.object({
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  PORT: z.coerce.number().default(3000),
});

export const config = schema.parse(process.env);
```

**Go:**

```go
// config.go
func Load() (*Config, error) {
    cfg := &Config{
        DatabaseURL: os.Getenv("DATABASE_URL"),
        Port:        os.Getenv("PORT"),
    }
    if cfg.DatabaseURL == "" {
        return nil, fmt.Errorf("DATABASE_URL is required")
    }
    return cfg, nil
}
```

### 6. Replace raw `os.getenv` / `process.env` calls

Replace scattered reads with centralized config access:

```python
# Before
db_url = os.getenv("DATABASE_URL")
if not db_url:
    raise ValueError("DATABASE_URL required")

# After
from config import settings
db_url = settings.database_url
```

### 7. CI/CD integration

Ensure CI never has `.env` present. Use platform secrets:

- GitHub Actions: `${{ secrets.JWT_SECRET }}` → `JWT_SECRET` env var
- GitLab CI: `$JWT_SECRET` via CI/CD variables
- Docker: `--env-file` flag or Compose `env_file:` key (never bake into image)

## Verify

- [ ] `.env.example` documents every variable with a comment and safe placeholder
- [ ] `.gitignore` excludes `.env` and variants, allows `.env.example`
- [ ] Startup validation fails fast on missing required variables
- [ ] No raw `os.getenv()`/`process.env` calls remain in application code (all routed through config module)
- [ ] No real secrets present in `.env.example` or any committed file
- [ ] `git log --all -- .env` returns no commits
