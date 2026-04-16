---
name: webapp-testing
description: Set up browser testing — dual path with built-in browser tools (interactive) or Playwright (CI); detect framework, scaffold, verify
compatibility: ">=2.0"
---

# Web Application Testing

> Skill metadata: version "2.1"; license MIT; tags [testing, e2e, playwright, browser, ci, browser-tools, mcp]; compatibility ">=2.0"; recommended tools [codebase, editFiles, runCommands].

Three paths — choose by need:

| Factor | A: Browser tools | B: Playwright | C: Playwright MCP |
|--------|-----------------|---------------|-------------------|
| Setup | Zero — built-in | Moderate — install + config | Low — MCP server config |
| CI | No | Yes — headless | No |
| Persistence | Conversational | Test files in repo | On-demand via MCP |
| Browsers | Chromium | Chromium + Firefox + WebKit | Chromium |
| Best for | Dev-time checks, debugging | Regression testing, PR gates | Agent-driven automation |
| Requires | `workbench.browser.enableChatTools: true` | Node.js + Playwright | `@playwright/mcp` |

Use A for interactive verification, B for CI, C for agent-driven browser control. They complement each other.

**Path guidance**: A when the agent only needs to inspect or click a page during a live VS Code session. C when browser navigation should be part of repeatable agent tooling (form automation, structured actions across Copilot/MCP-aware subagents/CLI). C does not replace committed regression tests — add B when CI coverage is needed.

## When to activate

- User says "Set up e2e tests", "Add browser tests", "Add Playwright", "Test my web app", or "Check my web app"
- A web application exists but has no browser-level tests
- The `test-coverage-review` skill identifies missing e2e coverage

---

## Path A — Built-in Browser Tools

VS Code 1.110+ provides agentic browser tools (Preview, opt-in).

### A1. Enable

```json
{ "workbench.browser.enableChatTools": true }
```

### A2. Available tools

`openBrowserPage`, `navigatePage`, `readPage`, `screenshotPage`, `clickElement`, `hoverElement`, `dragElement`, `typeInPage`, `handleDialog`, `runPlaywrightCode`

### A3. Workflow

1. Start the dev server
2. `openBrowserPage` → app URL
3. `readPage` → verify content
4. `screenshotPage` → visual check
5. `clickElement` / `typeInPage` → interact with forms, navigation
6. `readPage` after interactions → verify state changes

### A4. Limitations

- Chromium only, interactive (not persisted), no CI, Preview stability caveats, some dynamic content may be inaccessible

---

## Path B — Playwright (CI-ready)

### B1. Detect the web framework

| Signal | Framework | Dev command |
|--------|-----------|------------|
| `next.config.*`, `"next"` in deps | Next.js | `npx next dev` |
| `vite.config.*`, `"vite"` in deps | Vite | `npx vite` |
| `nuxt.config.*`, `"nuxt"` in deps | Nuxt | `npx nuxt dev` |
| `angular.json`, `"@angular/core"` | Angular | `npx ng serve` |
| `svelte.config.*`, `"@sveltejs/kit"` | SvelteKit | `npx vite dev` |
| `remix.config.*`, `"@remix-run/dev"` | Remix | `npx remix dev` |
| `astro.config.*`, `"astro"` in deps | Astro | `npx astro dev` |

Also check `package.json` scripts for `"dev"`, `"start"`, or `"serve"`. If no framework detected, ask the user.

### B2. Install Playwright

```bash
npm init playwright@latest -- --quiet
```

Creates `playwright.config.ts`, `tests/`, `tests-examples/`. Alternatives: `pnpm create playwright --quiet`, `yarn create playwright --quiet`, `bunx create-playwright --quiet`.

### B3. Configure

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

### B4. Write the first test

Create `tests/e2e/smoke.spec.ts`:

```typescript
import { test, expect } from "@playwright/test";

test("home page loads successfully", async ({ page }) => {
  await page.goto("/");
  await expect(page).toHaveTitle(/.+/);
  await expect(page.locator("body")).not.toContainText("500");
  await expect(page.locator("body")).not.toContainText("Internal Server Error");
});

test("navigation is functional", async ({ page }) => {
  await page.goto("/");
  const links = page.locator("a[href]");
  await expect(links.first()).toBeVisible();
});
```

Add targeted tests for login pages, auth flows, or other critical paths identified during detection.

### B5. Verify tests pass

```bash
npx playwright test
```

All tests should pass on at least one browser with no flaky results (run twice to confirm). Use `npx playwright show-report` for the HTML report. If tests fail, check dev server startup, `baseURL` port, and selector accuracy.

### B6. Add CI workflow

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
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4
        with:
          node-version: lts/*
      - name: Install dependencies
        run: npm ci
      - name: Install Playwright browsers
        run: npx playwright install --with-deps
      - name: Run Playwright tests
        run: npx playwright test
      - uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02 # v4
        if: ${{ !cancelled() }}
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

### B7. Update project files

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

## Path C — Playwright MCP Server

`@playwright/mcp` exposes Playwright browser automation as MCP tools for agent-driven navigation, screenshots, form filling, and JS execution.

### C1. Configure

Add to `.vscode/mcp.json`:

```json
{
  "servers": {
    "playwright": {
      "command": "npx",
      "args": [
        "-y",
        "@playwright/mcp@latest",
        "--headless",
        "--browser=chromium"
      ],
      "disabled": true
    }
  }
}
```

Remove `"disabled": true` to start. If the repo uses agent-level `mcp-servers` allowlists, add `playwright` only to agents that need browser access.

### C2. Available MCP tools

`browser_navigate`, `browser_screenshot`, `browser_click`, `browser_type`, `browser_select_option`, `browser_hover`, `browser_evaluate`, `browser_handle_dialog`, `browser_tab_list`, `browser_tab_create`, `browser_tab_close`, `browser_pdf_save`, `browser_console_messages`

### C3. When to prefer over Path A

- Need Playwright's engine (reliable element targeting, network interception)
- Structured MCP tool calls preferred over ad-hoc browser tools
- Same automation needed across Copilot CLI or external agents via MCP bridge

### C4. Limitations

No CI integration (use Path B), tests not persisted as files, requires Node.js for the MCP server process.

## Verify

- [ ] Path A: `workbench.browser.enableChatTools` enabled; page opens, action works, screenshot captured
- [ ] Path B: `npx playwright test` passes on at least Chromium
- [ ] Path B: CI workflow is valid YAML; `.gitignore` excludes artifacts; `package.json` has `test:e2e`
- [ ] Path C: `@playwright/mcp` entry in `.vscode/mcp.json`; `browser_navigate` available after start
