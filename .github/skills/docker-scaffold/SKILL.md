---
name: docker-scaffold
description: Scaffold a production-ready Dockerfile and docker-compose.yml for a project — multi-stage builds, non-root user, health checks, and .dockerignore
compatibility: ">=0.7.0"
---

# Docker Scaffold

> Skill metadata: version "1.0"; license MIT; tags [docker, containers, compose, devops, scaffold]; compatibility ">=0.7.0"; recommended tools [codebase, editFiles, runCommands].

Generate a production-quality Dockerfile and `docker-compose.yml` for any project stack. Includes multi-stage builds, non-root execution, health checks, and a `.dockerignore` to keep images lean.

## When to use

- User asks to "add Docker support", "containerize this app", "write a Dockerfile"
- Preparing an app for deployment or CI
- Standardising local development environments across a team

## When not to use

- Kubernetes manifests or Helm charts — those need dedicated tooling beyond this skill
- Serverless container platforms (Cloud Run, Lambda) — container shape differs

## Steps

### 1. Detect the stack

Read `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, `pom.xml`, or `build.gradle` to determine:

- **Runtime**: Node.js, Python, Rust, Go, Java, Ruby, etc.
- **Build tool**: npm, pip, cargo, Maven, Gradle
- **Exposed port**: from existing config or ask the user
- **Start command**: `npm start`, `gunicorn`, `./myapp`, `java -jar app.jar`

### 2. Choose a base image

| Runtime | Build stage | Run stage |
|---------|------------|-----------|
| Node.js | `node:22-alpine` | `node:22-alpine` |
| Python | `python:3.13-slim` | `python:3.13-slim` |
| Go | `golang:1.23-alpine` | `gcr.io/distroless/static` |
| Rust | `rust:1.80-alpine` | `gcr.io/distroless/cc` |
| Java | `eclipse-temurin:21-jdk-alpine` | `eclipse-temurin:21-jre-alpine` |

Always prefer Alpine or distroless for the run stage.

### 3. Write the Dockerfile

Use a multi-stage build. Template:

```dockerfile
# syntax=docker/dockerfile:1

### Stage 1: build dependencies
FROM <build-image> AS deps
WORKDIR /app
COPY <manifest files> ./
RUN <install command>

### Stage 2: build application
FROM deps AS builder
COPY . .
RUN <build command>

### Stage 3: production runtime
FROM <runtime-image> AS runtime

# Non-root user
RUN addgroup --system app && adduser --system --ingroup app app

WORKDIR /app

# Copy only built artefacts
COPY --from=builder --chown=app:app /app/<dist> ./

USER app

EXPOSE <port>

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD <health check command>

CMD [<entrypoint>]
```

Fill in the template with values from step 1. Never use `latest` tags.

### 4. Write `.dockerignore`

```dockerignore
# Version control
.git
.gitignore

# Dependencies (rebuilt in container)
node_modules/
__pycache__/
.venv/
target/
vendor/

# Test and dev artefacts
*.test
coverage/
.pytest_cache/
dist/
build/

# Local config
.env
.env.*
*.local

# IDE
.vscode/
.idea/
*.swp

# Docker
Dockerfile*
docker-compose*
.dockerignore
```

### 5. Write `docker-compose.yml`

For local development:

```yaml
services:
  app:
    build:
      context: .
      target: runtime
    ports:
      - "127.0.0.1:<port>:<port>"
    environment:
      - NODE_ENV=development   # or equivalent
    env_file:
      - .env
    volumes:
      - .:/app:cached          # remove for production
    restart: unless-stopped
    healthcheck:
      test: [<health check>]
      interval: 30s
      timeout: 5s
      retries: 3

  # Add database/cache services as needed
  # db:
  #   image: postgres:17-alpine
  #   ...
```

### 6. Security hardening checklist

- [ ] Non-root user set in Dockerfile
- [ ] No secrets or credentials in any layer (`ARG`/`ENV` for build-time values, `.env` for runtime)
- [ ] `--no-cache` or `--no-install-recommends` flags used for package managers
- [ ] Distroless or Alpine runtime stage
- [ ] `.dockerignore` excludes `.env`, `node_modules`, `.git`
- [ ] Port binding uses `127.0.0.1` in compose (not `0.0.0.0` unless intentional)

### 7. Verify

```bash
docker build -t myapp .
docker run --rm -p <port>:<port> myapp
# Confirm health check passes
docker inspect --format='{{.State.Health.Status}}' <container>
```

## Verify

- [ ] Dockerfile uses multi-stage build with minimal runtime image
- [ ] Non-root user created and used
- [ ] `HEALTHCHECK` instruction present
- [ ] `.dockerignore` prevents `.env` and dependency directories from entering the image
- [ ] Image builds and container starts cleanly
- [ ] No hardcoded secrets in any layer
