---
name: typescript-strict
description: Apply strict TypeScript — compiler flags, type narrowing, discriminated unions, branded types, and escape hatch discipline
compatibility: ">=1.4"
---

# TypeScript Strict Mode

> Skill metadata: version "1.0"; license MIT; tags [typescript, strict, types, compiler]; recommended tools [codebase, editFiles].

## When to use

- Enabling or tightening `strict` compiler options
- Resolving strict-mode type errors
- Designing type-safe APIs and data structures
- Reviewing code for type safety gaps

## Compiler configuration

Enable maximum strictness in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "verbatimModuleSyntax": true
  }
}
```

- `strict: true` enables all strict family flags.
- `noUncheckedIndexedAccess` makes array/object index access return `T | undefined`.
- `exactOptionalPropertyTypes` distinguishes between `undefined` and missing.

## Type narrowing

### Discriminated unions

```typescript
type Result<T> =
  | { ok: true; value: T }
  | { ok: false; error: Error };

function handle(result: Result<string>) {
  if (result.ok) {
    console.log(result.value); // narrowed to { ok: true; value: string }
  } else {
    console.error(result.error); // narrowed to { ok: false; error: Error }
  }
}
```

### Type predicates

```typescript
function isUser(value: unknown): value is User {
  return typeof value === "object" && value !== null && "id" in value;
}
```

### Exhaustiveness checking

```typescript
function assertNever(value: never): never {
  throw new Error(`Unexpected value: ${value}`);
}
```

## Escape hatch discipline

- Never use `any` — use `unknown` and narrow.
- Use `as` type assertions only when the type system cannot express the intent (e.g., after runtime validation).
- Annotate assertions with a comment explaining why: `// SAFETY: validated by schema above`.
- Use `satisfies` for validation without widening.

## Common patterns

### Branded types for domain identifiers

```typescript
type UserId = string & { readonly __brand: "UserId" };
function userId(id: string): UserId {
  return id as UserId;
}
```

### Template literal types

```typescript
type EventName = `on${Capitalize<string>}`;
```

### Const assertions

```typescript
const ROLES = ["admin", "editor", "viewer"] as const;
type Role = (typeof ROLES)[number]; // "admin" | "editor" | "viewer"
```

## Verify

- [ ] Strict compiler options are enabled and checked without emit
- [ ] Narrowing strategy avoids unsafe assertions on unknown data
- [ ] Escape hatches (`as`, `any`) are minimized and justified
- [ ] Domain-critical identifiers and unions are modeled with precise types
