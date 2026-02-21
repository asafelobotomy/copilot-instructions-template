---
applyTo: "**/api/**,**/routes/**,**/controllers/**,**/handlers/**"
---

# API Route Instructions

- Validate all user input at the boundary — never trust request payloads.
- Return appropriate HTTP status codes: 400 for validation failures, 404 for missing resources, 500 only for unexpected errors.
- Keep route handlers thin — delegate business logic to service modules.
- Include pagination for list endpoints; never return unbounded collections.
- Log errors with enough context to debug without reproducing (request ID, user context, input shape).
- Prefer idempotent operations where possible.
- Document expected request/response shapes near the handler or in a shared types file.
