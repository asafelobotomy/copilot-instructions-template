---
name: create-adr
description: Create an Architectural Decision Record (ADR) to document a significant design or technology choice
compatibility: ">=1.4"
---

# Create Architectural Decision Record

> Skill metadata: version "1.0"; license MIT; tags [documentation, architecture, decision, adr]; compatibility ">=1.4"; recommended tools [editFiles, codebase].

Create a structured ADR document that captures the context, decision, consequences, and alternatives for a significant architectural choice.

## When to use

- User asks to "create an ADR", "document this decision", or "record why we chose X"
- A significant architectural choice was made or a rejected option needs documenting

## When NOT to use

- Trivial details (naming, minor refactors) — use commit messages
- Obvious-from-code decisions
- Full design docs needed (that’s a specification, not an ADR)

## Steps

1. **Gather inputs** — Collect or infer: decision title (verb phrase), context (problem/constraints), decision (what and why), alternatives (rejected and why), stakeholders. Ask if required inputs are missing.

2. **Determine sequence number** — List `docs/adr/` (create if absent). Next 4-digit number.

3. **Write the ADR** — Save to `docs/adr/adr-NNNN-<title-slug>.md` using template below.

4. **Confirm** — Show the created file path.

## ADR Template

```markdown
---
title: "ADR-NNNN: [Decision Title]"
status: "Proposed"
date: "YYYY-MM-DD"
authors: "[Stakeholder Names/Roles]"
tags: ["architecture", "decision"]
supersedes: ""
superseded_by: ""
---

# ADR-NNNN: [Decision Title]

## Status

**Proposed** | Accepted | Rejected | Superseded | Deprecated

## Context

[Problem statement, technical constraints, business requirements, and environmental factors
requiring this decision.]

## Decision

[Chosen solution with clear rationale for selection.]

## Consequences

### Positive

- **POS-001**: [Beneficial outcomes and advantages]
- **POS-002**: [Performance, maintainability, scalability improvements]

### Negative

- **NEG-001**: [Trade-offs, limitations, drawbacks]
- **NEG-002**: [Technical debt or complexity introduced]

## Alternatives Considered

### [Alternative 1 Name]

- **ALT-001**: **Description**: [Brief technical description]
- **ALT-002**: **Rejection Reason**: [Why this option was not selected]

### [Alternative 2 Name]

- **ALT-003**: **Description**: [Brief technical description]
- **ALT-004**: **Rejection Reason**: [Why this option was not selected]

## Implementation Notes

- **IMP-001**: [Key implementation considerations]
- **IMP-002**: [Migration or rollout strategy if applicable]
- **IMP-003**: [Monitoring and success criteria]

## References

- **REF-001**: [Related ADRs]
- **REF-002**: [External documentation]
- **REF-003**: [Standards or frameworks referenced]
```
