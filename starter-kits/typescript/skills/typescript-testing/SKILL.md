---
name: typescript-testing
description: Write and organize TypeScript tests using Jest or Vitest — mocking patterns, async testing, snapshot discipline, and coverage
---

# TypeScript Testing

> Skill metadata: version "1.0"; license MIT; tags [typescript, testing, jest, vitest]; recommended tools [codebase, runCommands, editFiles].

## When to use

- Writing or reviewing TypeScript/JavaScript tests
- Setting up Jest or Vitest configuration
- Debugging test failures in a TS/JS project
- Choosing between Jest and Vitest

## Test structure

Mirror the source tree with `.test.ts` or `.spec.ts` files:

```text
src/
  services/
    auth.ts
    auth.test.ts
  utils/
    format.ts
    format.test.ts
```

- Co-locate test files with source when using Vitest or projects with flat structure.
- Use a `__tests__/` directory when project convention requires it (older Jest projects).

## Framework selection

| Signal | Choose |
|--------|--------|
| Vite-based project | Vitest |
| Existing Jest setup | Jest (unless migrating) |
| New project | Vitest (faster, native ESM, compatible API) |

## Patterns

### Arrange / Act / Assert

```typescript
describe("UserService", () => {
  it("returns null for non-existent user", async () => {
    // Arrange
    const service = new UserService(mockDb);

    // Act
    const result = await service.findById("nonexistent");

    // Assert
    expect(result).toBeNull();
  });
});
```

### Mocking

- Mock at module boundaries (API clients, database, file system).
- Use `vi.mock()` (Vitest) or `jest.mock()` (Jest) for module-level mocks.
- Use `vi.spyOn()` / `jest.spyOn()` for partial mocks.
- Always restore mocks: `afterEach(() => vi.restoreAllMocks())`.

```typescript
vi.mock("./api-client", () => ({
  fetchUser: vi.fn().mockResolvedValue({ id: "1", name: "Test" }),
}));
```

### Async testing

- Always `await` async operations — never rely on callback-based done().
- Test both success and error paths for async functions.
- Use `vi.useFakeTimers()` for timer-dependent code.

### Snapshot discipline

- Use snapshots sparingly — only for stable, human-reviewable output (rendered UI, serialized data).
- Never snapshot large objects or entire API responses.
- Review snapshot diffs carefully — do not blindly update.

## Configuration

### Vitest (vite.config.ts)

```typescript
export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    coverage: {
      provider: "v8",
      reporter: ["text", "lcov"],
    },
  },
});
```

### Jest (jest.config.ts)

```typescript
export default {
  preset: "ts-jest",
  testEnvironment: "node",
  collectCoverageFrom: ["src/**/*.ts", "!src/**/*.d.ts"],
};
```

## Coverage

- Focus coverage on business logic and edge cases.
- Use `/* v8 ignore next */` or `/* istanbul ignore next */` sparingly and with justification.
