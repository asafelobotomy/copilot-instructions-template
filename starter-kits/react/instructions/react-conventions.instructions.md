---
name: React Conventions
applyTo: "**/*.tsx,**/*.jsx"
description: "React component conventions — composition, hooks, state management, performance, and Next.js patterns"
---

# React Conventions

- Use functional components with hooks. Do not use class components.
- Keep components small and focused — extract when a component exceeds ~100 lines or handles multiple responsibilities.
- Use named exports for components. Reserve default exports for page components (Next.js convention).
- Colocate component files: `Button.tsx`, `Button.test.tsx`, `Button.module.css` in the same directory.
- Use TypeScript interfaces for component props. Define props inline for simple components, extract for complex ones.
- Avoid `any` in props — use `React.ComponentPropsWithoutRef<"button">` for extending HTML element props.
- Use `useMemo` and `useCallback` only when profiling shows a performance issue — not by default.
- Avoid prop drilling deeper than 2 levels. Use React Context or a state management library.
- Use `key` props that are stable and unique — never array indices for lists that can reorder.
- Handle loading, error, and empty states explicitly in every data-fetching component.
- Use React.Suspense and error boundaries for async component loading.
- Prefer controlled components for forms. Use a form library (react-hook-form, formik) for complex forms.
