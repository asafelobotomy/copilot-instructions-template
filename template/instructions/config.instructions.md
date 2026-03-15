---
name: Configuration Files
applyTo: "**/*.config.*,**/.*rc,**/.*rc.json,**/.*rc.yml,**/.*rc.js,**/.*rc.ts"
description: "Conventions for configuration and RC files — secrets management, minimal config, and startup validation"
---

# Configuration File Instructions

- Never hardcode secrets, tokens, or credentials in config files — use environment variables.
- Prefer explicit configuration over convention-based defaults when the default is surprising.
- Keep config files minimal — document non-obvious settings with inline comments.
- When adding a new config key, check whether an existing key already covers the intent.
- Validate config at application startup, not at point of use.
