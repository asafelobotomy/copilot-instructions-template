---
name: TypeScript Conventions
applyTo: "**/*.ts,**/*.tsx,**/*.mts,**/*.cts"
description: "TypeScript coding conventions — imports, naming, module structure, error handling, and ESLint/Prettier integration"
---

# TypeScript Conventions

- Use named exports for most modules. Reserve default exports for framework convention (Next.js pages, React lazy-loaded components).
- Import types with `import type { ... }` to keep runtime bundles clean.
- Use `const` by default. Use `let` only when reassignment is necessary. Never use `var`.
- Prefer `interface` for object shapes that may be extended. Use `type` for unions, intersections, and mapped types.
- Name interfaces and types in PascalCase. Name constants in SCREAMING_SNAKE_CASE only if they are truly compile-time constants.
- Use early returns to reduce nesting depth.
- Prefer `async`/`await` over raw Promise chains.
- Handle errors explicitly — never silently swallow rejections.
- Use `unknown` instead of `any` for values of uncertain type.
- Configure ESLint with `@typescript-eslint/recommended-type-checked` for maximum safety.
- Use Prettier or the editor's formatter for consistent formatting — do not debate style in reviews.
- Barrel files (`index.ts` re-exports) are acceptable for public API surfaces but should not re-export internal implementation details.
