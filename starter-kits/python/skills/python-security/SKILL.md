---
name: python-security
description: "Common Python security pitfalls — injection, deserialization, path traversal, and dependency management"
compatibility: ">=1.4"
---

# Python Security

> Skill metadata: version "1.0"; license MIT; tags [python, security, injection, owasp]; recommended tools [codebase, editFiles].

## When to use

- Reviewing Python code for security vulnerabilities
- Writing security-sensitive Python code (auth, file handling, database access)

## File scope

Applies to: `**/*.py`

## Conventions

- Never use `eval()`, `exec()`, or `compile()` on untrusted input.
- Never use `pickle` or `marshal` to deserialize untrusted data. Use `json` or validated schemas.
- Use parameterized queries for all database operations — never format SQL strings with f-strings or `%`.
- Validate and sanitize file paths to prevent path traversal. Use `pathlib.Path.resolve()` and check the result is within the expected directory.
- Use `secrets` module for tokens and random values — never `random` for security-sensitive operations.
- Set `httponly`, `secure`, and `samesite` flags on cookies.
- Use `subprocess` with a list of arguments — never `shell=True` with user-controlled input.
- Pin dependencies and audit with `pip-audit` or `safety` regularly.
- Use `hashlib` with a named algorithm — never roll your own cryptography.
- Set appropriate timeouts on all network requests to prevent hanging.
- Use `defusedxml` instead of `xml.etree` when parsing untrusted XML.
