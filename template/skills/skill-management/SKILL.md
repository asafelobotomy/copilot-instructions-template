---
name: skill-management
description: Discover, activate, and manage agent skills following the Skill Protocol
version: "1.0"
license: MIT
tags: [skills, workflow, discovery, management]
compatibility: ">=1.4"
allowed-tools: [codebase, editFiles, fetch]
---

# Skill Management

Skills are reusable markdown-based **behavioural instructions** that teach the agent *how* to perform a specific workflow. Unlike tools (§11) which are executable scripts, skills are declarative — they shape the agent's approach rather than running code.

Skills follow the [Agent Skills](https://agentskills.io) open standard. Each skill is a `SKILL.md` file with YAML frontmatter and a markdown body containing step-by-step workflow instructions.

## When to use

- You encounter a task that might match an existing skill
- The user asks to list, search for, or manage skills
- You need to decide where a new skill should be stored

## Discovery and activation

Skills are loaded **on demand** — the agent reads a skill's `SKILL.md` only when the `description` field matches the current task context. Do not pre-load all skills.

```text
Task requires a workflow
 │
 ├─ 1. SCAN — check .github/skills/*/SKILL.md descriptions
 │     ├─ Match found  → READ the full SKILL.md, follow its instructions
 │     └─ No match     → ↓
 │
 ├─ 2. SEARCH (if enabled by skill search preference setting)
 │     ├─ Search official repos (anthropics/skills, github/awesome-copilot) THEN:
 │     │     community sources (GitHub search, awesome-agent-skills)
 │     │     ├─ Found → evaluate fit, quality-check, adapt, save locally
 │     │     └─ Not found → ↓
 │
 └─ 3. CREATE — author a new skill from scratch
       - Save to .github/skills/<kebab-name>/SKILL.md
       - Append to JOURNAL.md: `[skill] <name> created — <one-line reason>`
```

## Scope hierarchy

| Priority | Location | Scope |
|----------|----------|-------|
| 1 (highest) | `.github/skills/<name>/SKILL.md` | Project — checked into version control |
| 2 | `~/.copilot/skills/<name>/SKILL.md` | Personal — shared across all projects for one user |

## Subagent skill use

Subagents inherit this protocol fully. A subagent may read and follow any project or personal skill. To **create** a new skill, the subagent must flag the proposal to the parent agent, which confirms before any write to `.github/skills/`.
