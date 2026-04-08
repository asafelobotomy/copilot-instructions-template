# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Previous minor | Best effort |
| Older | No |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it
responsibly:

1. **Do not** open a public GitHub issue for security vulnerabilities.
2. Email the maintainer or use [GitHub Security Advisories](https://github.com/asafelobotomy/copilot-instructions-template/security/advisories/new) to report privately.
3. Include a clear description, reproduction steps, and impact assessment.
4. Allow up to 72 hours for an initial response.

## Scope

This project is a template repository that generates configuration files for
AI coding assistants. Security concerns include:

- Secret leakage in generated configuration files
- Path traversal in hook scripts
- Supply-chain risks in CI dependencies
- Injection vectors in shell and PowerShell hooks that process JSON input

## Disclosure Timeline

- **Day 0**: Vulnerability reported privately
- **Day 3**: Initial acknowledgement
- **Day 14**: Fix developed and tested
- **Day 21**: Fix released; advisory published
