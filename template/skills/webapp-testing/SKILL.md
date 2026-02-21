---
name: webapp-testing
description: Set up end-to-end browser testing with Playwright — detect framework, install, scaffold tests, write first test, verify, add to CI
version: "1.0"
license: MIT
tags: [testing, e2e, playwright, browser, ci]
compatibility: ">=2.0"
allowed-tools: [codebase, editFiles, terminal, runCommands]
---

# Web Application Testing with Playwright

Set up end-to-end (e2e) browser testing for a web application using Playwright. This skill covers the full lifecycle: detecting the web framework, installing Playwright, scaffolding the test directory, writing the first meaningful test, verifying it passes, and adding a CI workflow.

## When to activate

- User says "Set up e2e tests", "Add browser tests", "Add Playwright", or "Test my web app"
- A web application exists but has no browser-level tests
- The §2 Test Coverage Review identifies missing e2e coverage

## Workflow

### 1. Detect the web framework

Scan the project for framework signals:

| Signal | Framework | Dev server command |
|--------|-----------|-------------------|
| `next.config.*`, `"next"` in deps | Next.js | `npx next dev` |
| `vite.config.*`, `"vite"` in deps | Vite (React/Vue/Svelte) | `npx vite` |
| `nuxt.config.*`, `"nuxt"` in deps | Nuxt | `npx nuxt dev` |
| `angular.json`, `"@angular/core"` in deps | Angular | `npx ng serve` |
| `svelte.config.*`, `"@sveltejs/kit"` in deps | SvelteKit | `npx vite dev` |
| `remix.config.*`, `"@remix-run/dev"` in deps | Remix | `npx remix dev` |
| `astro.config.*`, `"astro"` in deps | Astro | `npx astro dev` |

Also check `package.json` scripts for `"dev"`, `"start"`, or `"serve"` commands.

If no framework is detected, ask the user how to start the development server.

### 2. Install Playwright

```bash
npm init playwright@latest -- --quiet
```

This creates:
- `playwright.config.ts` — configuration file
- `tests/` — test directory
- `tests-examples/` — example tests (can be deleted)

If the user prefers a different package manager:

```bash
# pnpm
pnpm create playwright --quiet

# yarn
yarn create playwright --quiet

# bun
bunx create-playwright --quiet
```

### 3. Configure Playwright

Update `playwright.config.ts` for the detected framework:

```typescript
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? "github" : "html",
  use: {
    baseURL: "http://localhost:<PORT>",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
  webServer: {
    command: "<DEV_SERVER_COMMAND>",
    url: "http://localhost:<PORT>",
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```

Replace `<PORT>` and `<DEV_SERVER_COMMAND>` with the detected values.

### 4. Write the first test

Create `tests/e2e/smoke.spec.ts` — a smoke test that verifies the app loads:

```typescript
import { test, expect } from "@playwright/test";

test("home page loads successfully", async ({ page }) => {
  await page.goto("/");
  await expect(page).toHaveTitle(/.+/);
  // Verify the page is not an error page
  await expect(page.locator("body")).not.toContainText("500");
  await expect(page.locator("body")).not.toContainText("Internal Server Error");
});

test("navigation is functional", async ({ page }) => {
  await page.goto("/");
  // Verify at least one link or navigation element exists
  const links = page.locator("a[href]");
  await expect(links.first()).toBeVisible();
});
```

If the project has a login page, authentication flow, or other critical paths identified in Step 1, write targeted tests for those too.

### 5. Verify tests pass

```bash
npx playwright test
```

Expected output:
- All tests pass on at least one browser
- No flaky tests (run twice to confirm)
- HTML report is generated (`npx playwright show-report`)

If tests fail:
- Check that the dev server starts correctly
- Verify the `baseURL` matches the actual dev server port
- Ensure selectors match actual page elements

### 6. Add CI workflow

Create `.github/workflows/playwright.yml`:

```yaml
name: Playwright Tests
on:
  push:
    branches: [main]
  pull_request:
jobs:
  test:
    timeout-minutes: 60
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: lts/*
      - name: Install dependencies
        run: npm ci
      - name: Install Playwright browsers
        run: npx playwright install --with-deps
      - name: Run Playwright tests
        run: npx playwright test
      - uses: actions/upload-artifact@v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

### 7. Update project files

- Add to `.gitignore`:

  ```text
  # Playwright
  /test-results/
  /playwright-report/
  /blob-report/
  /playwright/.cache/
  ```

- Add convenience scripts to `package.json`:

  ```json
  {
    "scripts": {
      "test:e2e": "playwright test",
      "test:e2e:ui": "playwright test --ui",
      "test:e2e:report": "playwright show-report"
    }
  }
  ```

- Log in JOURNAL.md: `[testing] Playwright e2e tests scaffolded — smoke test + CI workflow`
- Update BIBLIOGRAPHY.md with new test files

## Verify

- [ ] `npx playwright test` passes on at least Chromium
- [ ] CI workflow file is valid YAML (`actionlint .github/workflows/playwright.yml`)
- [ ] `.gitignore` excludes Playwright artifacts
- [ ] `package.json` has `test:e2e` script
- [ ] JOURNAL.md has an entry
