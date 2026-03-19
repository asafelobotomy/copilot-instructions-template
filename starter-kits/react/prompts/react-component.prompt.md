---
description: "Generate a new React component with tests, types, and accessibility built in"
agent: copilot
---

# React Component

Generate a new React component following project conventions.

## Inputs

- **Component name**: PascalCase name for the component
- **Purpose**: What the component does and where it will be used
- **Props**: Key props the component accepts

## Output structure

Create these files:

1. `ComponentName.tsx` — the component implementation
   - Functional component with TypeScript props interface
   - Semantic HTML with proper ARIA attributes
   - Loading, error, and empty states handled
   - Named export

2. `ComponentName.test.tsx` — component tests
   - Render test with React Testing Library
   - User interaction test with userEvent
   - Accessibility: query by role and label, not test IDs
   - Edge cases: empty data, error state, loading state

3. `ComponentName.module.css` (if CSS Modules) or styled component — only if styling is needed

## Checklist

- [ ] Props interface defined with TypeScript types
- [ ] All interactive elements are keyboard-accessible
- [ ] Images have alt text
- [ ] Form inputs have labels
- [ ] Tests cover render, interaction, and edge cases
- [ ] No `any` types used
