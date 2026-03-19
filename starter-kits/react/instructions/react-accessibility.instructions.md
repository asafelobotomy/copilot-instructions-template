---
name: React Accessibility
applyTo: "**/*.tsx,**/*.jsx"
description: "React accessibility conventions — semantic HTML, ARIA, keyboard navigation, and screen reader support"
---

# React Accessibility

- Use semantic HTML elements (`button`, `nav`, `main`, `article`, `header`) instead of styled divs.
- Every interactive element must be keyboard-accessible. Use native elements (button, a, input) which provide this for free.
- Every `img` must have an `alt` attribute. Use `alt=""` for decorative images.
- Every form input must have an associated `label` element or `aria-label`.
- Use `aria-live="polite"` for dynamic content updates (loading states, notifications).
- Use `role="alert"` for error messages that require immediate attention.
- Do not disable focus outlines without providing a visible alternative.
- Use `aria-expanded`, `aria-controls`, and `aria-haspopup` for interactive disclosure widgets.
- Ensure color contrast meets WCAG 2.1 AA minimum (4.5:1 for normal text, 3:1 for large text).
- Test keyboard navigation: Tab, Shift+Tab, Enter, Space, Escape, Arrow keys.
- Use heading levels (`h1`–`h6`) in sequence — do not skip levels.
- Use `prefers-reduced-motion` media query to respect user motion preferences.
