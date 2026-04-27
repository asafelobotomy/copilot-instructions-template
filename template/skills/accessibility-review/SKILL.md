---
name: accessibility-review
description: Review a UI for accessibility — WCAG 2.1 AA compliance, semantic HTML, ARIA usage, keyboard navigation, focus management, colour contrast, and screen reader compatibility
compatibility: ">=0.7.0"
---

# Accessibility Review

> Skill metadata: version "1.0"; license MIT; tags [accessibility, a11y, wcag, aria, keyboard, screen-reader]; compatibility ">=0.7.0"; recommended tools [codebase, editFiles, runCommands].

Audit a UI for WCAG 2.1 AA compliance. Fixes accessibility issues so the product works for keyboard-only users, screen reader users, and people with low vision.

## When to use

- User asks to "check accessibility", "fix a11y issues", "make this WCAG compliant", or "audit for screen readers"
- Before a release or compliance review
- A11y CI check is failing

## When not to use

- Native mobile apps (iOS/Android) — platform-specific guidelines apply
- PDF or document accessibility — separate toolchain required

## Steps

### 1. Automated scan

Run an automated scanner first to catch the easy wins:

```bash
# Lighthouse CLI (Chrome-based)
npx lighthouse http://localhost:3000 --only-categories=accessibility --output=json

# axe-core (framework-agnostic)
npx axe http://localhost:3000

# pa11y
npx pa11y http://localhost:3000
```

Automated tools catch ~30-40% of issues. Manual review is required for the rest.

### 2. Semantic HTML audit

Review the markup for correct element semantics:

| Issue | Fix |
|-------|-----|
| `<div>` used as a button | Replace with `<button>` |
| `<div>` used as a heading | Replace with `<h1>`–`<h6>` in correct order |
| `<span>` used as a link | Replace with `<a href="...">` |
| Images without `alt` | Add `alt=""` for decorative; descriptive text for informative |
| Form inputs without `<label>` | Add `<label for="...">` or `aria-label` |
| Tables without headers | Add `<th scope="col">` or `<th scope="row">` |
| Lists rendered with divs | Use `<ul>/<li>` or `<ol>/<li>` |

### 3. Keyboard navigation

Test full keyboard traversal without a mouse:

1. Tab through all interactive elements — each must receive visible focus
2. All actions achievable by mouse must also be achievable by keyboard
3. Modal dialogs: focus must be trapped inside while open; Escape must close
4. Focus must return to the trigger element when a modal or popover closes
5. Custom widgets (date pickers, carousels, tabs) must follow [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)

Common keyboard interaction patterns:

| Widget | Expected keyboard behaviour |
|--------|----------------------------|
| Button | Enter or Space activates |
| Link | Enter activates |
| Checkbox | Space toggles |
| Radio group | Arrow keys move between options |
| Tab panel | Arrow keys switch tabs; Tab enters the panel |
| Menu | Arrow keys navigate; Enter/Space selects; Escape closes |
| Dialog | Tab cycles within; Escape closes; focus returns on close |

### 4. ARIA usage review

ARIA rules:
- Use native HTML elements before ARIA — `<button>` is better than `<div role="button">`
- `aria-label` / `aria-labelledby` required on all elements with `role=` that lack visible text
- `aria-expanded` on toggles (menu buttons, accordions)
- `aria-live` regions for dynamic content that updates without page reload
- `aria-invalid` + `aria-describedby` pointing to error message on form errors

Common ARIA mistakes to fix:

```html
<!-- Bad: redundant role -->
<button role="button">Submit</button>

<!-- Bad: interactive element inside interactive element -->
<a href="/"><button>Home</button></a>

<!-- Bad: aria-label overrides visible text unexpectedly -->
<button aria-label="close dialog">✕ Cancel</button>

<!-- Good -->
<button aria-label="Close dialog">✕</button>
```

### 5. Colour contrast

WCAG 2.1 AA minimum ratios:
- **Normal text** (< 18pt / 14pt bold): **4.5:1**
- **Large text** (≥ 18pt / 14pt bold): **3:1**
- **UI components and graphical objects**: **3:1**
- Exception: decorative elements and disabled controls are exempt

Check contrast:

```bash
# Using the browser DevTools Accessibility panel
# Or online: https://webaim.org/resources/contrastchecker/

# In code — flag hardcoded colors for review
grep -rn "color:\|background:" src/ --include="*.css" --include="*.scss"
```

Fix by adjusting foreground or background colour values to meet the ratio.

### 6. Focus visibility

Every focusable element must have a visible focus indicator:

```css
/* Never do this globally */
*:focus { outline: none; }

/* Do this instead */
:focus-visible {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}
```

### 7. Screen reader testing

Test with at least one screen reader:

| OS | Screen reader | Browser |
|----|--------------|---------|
| macOS/iOS | VoiceOver | Safari |
| Windows | NVDA (free) | Firefox or Chrome |
| Linux | Orca | Firefox |
| Android | TalkBack | Chrome |

Key checks:
- Page has a descriptive `<title>`
- `<main>`, `<nav>`, `<header>`, `<footer>` landmarks present
- Headings create a logical document outline (`h1 → h2 → h3`, no skips)
- Images have meaningful `alt` text
- Dynamic content announced via `aria-live` regions
- Error messages are announced when forms are submitted

### 8. Document findings

Group issues by WCAG criterion:

| Issue | WCAG Criterion | Element | Severity | Fix |
|-------|---------------|---------|----------|-----|
| Missing alt text | 1.1.1 Non-text Content | `<img src="logo.png">` | High | Add `alt="Company logo"` |
| Low contrast | 1.4.3 Contrast (Minimum) | `.btn-secondary` | High | Change `#aaa` → `#767676` |
| No focus ring | 2.4.7 Focus Visible | All buttons | High | Remove `outline: none` |

## Verify

- [ ] Automated scan (Lighthouse/axe) passes with zero critical issues
- [ ] Full keyboard tab traversal works without mouse
- [ ] All modals trap focus correctly and restore on close
- [ ] All interactive elements meet WCAG 2.1 AA contrast ratio
- [ ] Page has `<main>`, `<nav>`, and heading hierarchy
- [ ] Screen reader test confirms landmarks and dynamic content announce correctly
