---
name: Docker Conventions
applyTo: "**/Dockerfile,**/Dockerfile.*,**/docker-compose.yml,**/docker-compose.yaml,**/compose.yml,**/compose.yaml,**/*.dockerfile"
description: "Dockerfile and Docker Compose conventions — layer ordering, security, health checks, and .dockerignore"
---

# Docker Conventions

- Pin base image versions to specific tags (not `latest`). Use digest pinning for production-critical images.
- Use multi-stage builds to separate build dependencies from runtime.
- Copy dependency manifests and install before copying source code (layer caching).
- Combine related `RUN` commands with `&&` and clean up in the same layer.
- Run containers as non-root. Create a dedicated user and group.
- Never `COPY` or `ADD` secrets, private keys, or credentials into the image.
- Use `HEALTHCHECK` in production Dockerfiles.
- Use `.dockerignore` to exclude `.git/`, `node_modules/`, build artifacts, and test files.
- Use `EXPOSE` to document ports — it does not publish them.
- Prefer `COPY` over `ADD` unless extracting archives or fetching URLs.
- Use `ENTRYPOINT` for the main process and `CMD` for default arguments.
- In Compose files, use `depends_on` with health check conditions for service ordering.
