---
description: "Systematic Docker debugging workflow — build errors, runtime failures, networking, fix, verify"
agent: copilot
---

# Docker Debug

Systematic debugging workflow for Docker issues.

## Steps

1. **Reproduce** — get the exact error:
   - Build failures: `docker build --no-cache --progress=plain .`
   - Runtime crashes: `docker logs <container>` or `docker compose logs <service>`
   - Compose failures: `docker compose up` without `-d` to see output

2. **Isolate** — narrow the scope:
   - Build errors: identify which `RUN` step fails — check the step number in output
   - Runtime: `docker exec -it <container> sh` to inspect the running container
   - Networking: `docker network inspect <network>` and `docker compose exec app ping db`
   - Layer issues: `docker image history <image>` to see layer sizes and commands

3. **Inspect** — gather state:
   - Check environment variables: `docker inspect <container> | grep -A 20 Env`
   - Check mounted volumes: `docker inspect <container> | grep -A 10 Mounts`
   - Check health status: `docker inspect --format='{{.State.Health.Status}}' <container>` (if no healthcheck is defined, inspect logs instead)
   - Check DNS resolution: `docker compose exec app nslookup db` (fallback: `getent hosts db`)

4. **Fix** — make the minimal change:
   - Fix the Dockerfile or compose file
   - Rebuild: `docker compose build --no-cache <service>`
   - Use `docker compose up --force-recreate <service>` to apply changes

5. **Verify** — confirm the fix:
   - `docker compose up -d` — services start cleanly
   - `docker compose ps` — all services show healthy status
   - `docker scout cves local://<image>` — no critical vulnerabilities (if Docker Scout is unavailable, use `trivy image <image>`)
   - Test the application endpoint or run integration tests
