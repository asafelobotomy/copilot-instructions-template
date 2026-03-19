---
name: docker-patterns
description: Docker and Docker Compose patterns — multi-stage builds, layer caching, compose orchestration, health checks, and security scanning
---

# Docker Patterns

> Skill metadata: version "1.0"; license MIT; tags [docker, dockerfile, compose, containers, security]; recommended tools [codebase, runCommands, editFiles].

## When to use

- Writing or reviewing Dockerfiles
- Setting up Docker Compose for development or production
- Optimizing image size and build speed
- Implementing container security best practices

## Dockerfile best practices

### Multi-stage builds

```dockerfile
# Build stage
FROM node:22-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build

# Production stage
FROM node:22-slim AS production
WORKDIR /app
RUN addgroup --system app && adduser --system --ingroup app app
COPY --from=build --chown=app:app /app/dist ./dist
COPY --from=build --chown=app:app /app/node_modules ./node_modules
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/main.js"]
```

### Layer caching

- Copy dependency manifests first, install deps, then copy source code.
- Use `.dockerignore` to exclude `node_modules/`, `.git/`, `build/`, test files.
- Pin base image versions (`node:22.12-slim`, not `node:latest`).
- Group related `RUN` commands with `&&` to reduce layer count.

### Security

- Use minimal base images (`-slim`, `-alpine`, `distroless`).
- Run as non-root user (`USER app`).
- Do not copy secrets into the image — use build secrets or runtime environment variables.
- Scan images: `docker scout cves <image>` or `trivy image <image>`.
- Set `HEALTHCHECK` for production containers.
- Pin package versions in `apt-get install`.

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl=7.88.1-10+deb12u8 && \
    rm -rf /var/lib/apt/lists/*
```

## Docker Compose

### Development compose

```yaml
services:
  app:
    build:
      context: .
      target: build
    volumes:
      - .:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: app
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app -d appdb"]
      interval: 5s
      timeout: 3s
      retries: 5
    secrets:
      - db_password

volumes:
  pgdata:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

### Compose conventions

- Use `depends_on` with `condition: service_healthy` for startup ordering.
- Use named volumes for persistent data.
- Use Docker secrets or environment files (`.env`) for credentials — never inline secrets.
- Use `profiles` to separate dev and production services.

## Commands

```bash
docker compose up -d          # Start services
docker compose logs -f app    # Follow logs
docker compose down -v        # Stop and remove volumes
docker compose build --no-cache  # Rebuild without cache
docker scout cves local://app    # Scan for vulnerabilities
```

## Image optimization

- Target < 100MB for application images where possible.
- Use `docker image history <image>` to audit layer sizes.
- Use `--mount=type=cache` for package manager caches in builds (BuildKit).

```dockerfile
RUN --mount=type=cache,target=/root/.npm npm ci --ignore-scripts
```
