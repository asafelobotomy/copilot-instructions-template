---
name: react-testing
description: Test React components effectively — React Testing Library patterns, user event simulation, hook testing, and snapshot discipline
---

# React Testing

> Skill metadata: version "1.0"; license MIT; tags [react, testing, testing-library, vitest, jest]; recommended tools [codebase, runCommands, editFiles].

## When to use

- Writing or reviewing React component tests
- Setting up React Testing Library
- Testing hooks, context providers, or async components
- Deciding between unit, integration, and E2E tests for UI

## Core principle

Test what the user sees and does — not implementation details. Query by role, label, or text, never by class name or test ID (unless no accessible alternative exists).

## React Testing Library patterns

### Basic component test

```tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { LoginForm } from "./LoginForm";

describe("LoginForm", () => {
  it("submits with entered credentials", async () => {
    const onSubmit = vi.fn();
    const user = userEvent.setup();

    render(<LoginForm onSubmit={onSubmit} />);

    await user.type(screen.getByLabelText("Email"), "user@example.com");
    await user.type(screen.getByLabelText("Password"), "secret123");
    await user.click(screen.getByRole("button", { name: "Log in" }));

    expect(onSubmit).toHaveBeenCalledWith({
      email: "user@example.com",
      password: "secret123",
    });
  });

  it("shows validation error for empty email", async () => {
    const user = userEvent.setup();
    render(<LoginForm onSubmit={vi.fn()} />);

    await user.click(screen.getByRole("button", { name: "Log in" }));

    expect(screen.getByRole("alert")).toHaveTextContent("Email is required");
  });
});
```

### Query priority

Use queries in this order (most to least preferred):

1. `getByRole` — accessible role (button, textbox, heading)
2. `getByLabelText` — form fields with associated labels
3. `getByPlaceholderText` — when no label exists
4. `getByText` — visible text content
5. `getByDisplayValue` — current form input value
6. `getByTestId` — last resort, requires `data-testid` attribute

### Async testing

```tsx
it("loads and displays user data", async () => {
  render(<UserProfile userId="123" />);

  expect(screen.getByText("Loading...")).toBeInTheDocument();

  await waitFor(() => {
    expect(screen.getByRole("heading")).toHaveTextContent("Jane Doe");
  });
});
```

### Testing hooks

```tsx
import { renderHook, act } from "@testing-library/react";
import { useCounter } from "./useCounter";

it("increments the counter", () => {
  const { result } = renderHook(() => useCounter(0));

  act(() => result.current.increment());

  expect(result.current.count).toBe(1);
});
```

### Testing with providers

```tsx
function renderWithProviders(ui: React.ReactElement) {
  return render(
    <QueryClientProvider client={new QueryClient()}>
      <ThemeProvider>{ui}</ThemeProvider>
    </QueryClientProvider>
  );
}
```

## What to test

| Priority | What | How |
|----------|------|-----|
| High | User interactions | `userEvent.click`, `userEvent.type` |
| High | Conditional rendering | Assert presence/absence of elements |
| Medium | Error states | Mock API failures, check error messages |
| Medium | Loading states | Check loading indicators |
| Low | Styling | Visual regression tests (Playwright, Chromatic) |
| Avoid | Implementation details | Don't test state, refs, or internal methods |

## Snapshot discipline

- Use snapshots only for small, stable components (icons, badges).
- Never snapshot entire pages or complex components.
- Review snapshot diffs carefully — do not blindly update.
