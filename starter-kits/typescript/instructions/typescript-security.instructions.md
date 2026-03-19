---
name: TypeScript Security
applyTo: "**/*.ts,**/*.tsx,**/*.mts,**/*.cts"
description: "TypeScript and Node.js security practices — input validation, dependency auditing, XSS prevention, and secrets management"
---

# TypeScript Security

- Validate all external input at system boundaries using a schema library (zod, valibot, joi). Never trust `req.body`, URL params, or environment variables without validation.
- Use parameterized queries for databases — never concatenate user input into SQL or query strings.
- Escape output before inserting into HTML. Use framework-provided sanitization (React's JSX escaping, DOMPurify for raw HTML).
- Never store secrets in source code or environment variable defaults. Use a secret manager or `.env` files excluded from version control.
- Run `npm audit` or `pnpm audit` in CI to catch vulnerable dependencies.
- Set Content Security Policy headers to mitigate XSS.
- Use `crypto.randomUUID()` or `crypto.getRandomValues()` for security-sensitive random values — never `Math.random()`.
- Avoid `eval()`, `new Function()`, and dynamic `import()` with user-controlled paths.
- Set appropriate `httpOnly`, `secure`, and `sameSite` flags on cookies.
- Use `URL` constructor to parse and validate URLs — never string concatenation.
- Limit request body size and set timeouts on all HTTP requests.
