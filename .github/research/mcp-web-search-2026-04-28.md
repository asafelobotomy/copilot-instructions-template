# Research: MCP Servers for Web Access and Web Search (VS Code Copilot)

> Date: 2026-04-28 | Agent: Researcher | Status: final

## Summary

As of April 2026, the landscape has two distinct problems: **reading a page from a known URL** (already solved by `mcp-server-fetch`) and **discovering URLs from natural language queries** (requires a search MCP or the `vscode-websearchforcopilot` extension). Playwright MCP is a full browser automation suite inappropriate for a Markdown/Shell coding-agent repo — its own README directs coding agents to the CLI+SKILLS alternative. The best zero-cost search addition is `duckduckgo-mcp-server` (no API key, uvx launch); the best quality option is Exa (API key, remote HTTP, neural search). The `vscode-websearchforcopilot` extension covers search within VS Code but does not eliminate the need for an MCP if cross-client portability matters.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://github.com/microsoft/playwright-mcp | Full tool list, resource requirements, explicit coding-agent guidance |
| https://github.com/modelcontextprotocol/servers/blob/main/src/fetch/README.md | Canonical mcp-server-fetch tool schema |
| https://github.com/exa-labs/exa-mcp-server | Exa tool list, remote server config, API key details |
| https://github.com/brave/brave-search-mcp-server | Official Brave Search MCP (v2); replaces archived MCP reference server |
| https://github.com/nickclyde/duckduckgo-mcp-server | DuckDuckGo MCP — tools, rate limits, fetch backends |
| https://github.com/tavily-ai/tavily-mcp | Tavily tools, remote server, free tier |
| https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-websearchforcopilot | Extension description, tool name, Tavily backend |

---

## Findings

### 1. `@playwright/mcp` — What it provides

**Tool count:** ~20+ tools across four capability tiers

**Core tools (always available):**
- `browser_navigate` — load a URL
- `browser_snapshot` — return accessibility tree of current page (large structured output)
- `browser_click`, `browser_hover`, `browser_drag`, `browser_drop` — interaction tools
- `browser_type`, `browser_fill_form`, `browser_select_option`, `browser_press_key` — input tools
- `browser_handle_dialog`, `browser_file_upload` — dialog/file tools
- `browser_evaluate` — execute arbitrary JavaScript on a page
- `browser_console_messages` — retrieve browser console output
- `browser_network_requests` — captured network traffic
- `browser_new_tab`, `browser_close_tab`, `browser_tab_list`, `browser_tab_select` — tab management
- `browser_close` — close the browser

**Optional capability flags:**
- `--caps vision` — adds coordinate-based screenshot tools
- `--caps pdf` — adds PDF generation
- `--caps devtools` — adds DevTools-level introspection

**Resource requirements:**
- Node.js 18+ required
- Downloads and caches a Chromium binary at first run (~300 MB to `~/.cache/ms-playwright/`)
- Browser launch adds ~2–5 seconds of startup latency per session
- Accessibility tree snapshots can produce hundreds of tokens for even simple pages

**Coding-agent assessment:**
The Playwright MCP README contains this direct statement:

> "If you are using a **coding agent**, you might benefit from using the CLI+SKILLS instead."

The README goes on to explain that CLI+SKILLS is preferred because it avoids loading large tool schemas and verbose accessibility trees into the model context. Playwright MCP is better suited for "exploratory automation, self-healing tests, or long-running autonomous workflows."

**Verdict for a Markdown/Shell repo:** Playwright MCP is already in `.vscode/mcp.json` (headless, sandboxed, optional) and retains one genuine use case: fetching JavaScript-rendered pages that `mcp-server-fetch` cannot handle (e.g. SPAs, GitHub pages with client-side routing). For the primary need of reading static documentation and discovering URLs, it is overweight. It adds zero search capability.

---

### 2. `mcp-server-fetch` — Tools and gaps

**Tools:** Single tool: `fetch`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `url` | string | required | URL to retrieve |
| `max_length` | integer | 5000 | Max chars to return |
| `start_index` | integer | 0 | Pagination offset |
| `raw` | boolean | false | Skip Markdown conversion |

**What it does well:**
- Fast (Python, no browser launch, ~50–200 ms per call)
- Clean HTML→Markdown conversion
- Pagination support via `start_index`
- Already in use in this repo's `.vscode/mcp.json`

**Gaps:**
- No search: requires a known URL — there is no `search(query)` tool
- No JavaScript execution: fails on SPAs and dynamic content
- No content relevance scoring
- No URL discovery from natural language queries

**The core gap** for this repo is the missing search step: when the Researcher agent needs to find "current documentation for context7 MCP server configuration," it must guess or construct URLs manually rather than issuing a search query.

---

### 3. Web Search Alternatives

#### 3a. `exa-mcp-server` (Exa)

**Tools (default enabled):**
- `web_search_exa` — natural language web search, returns cleaned content
- `web_fetch_exa` — fetch full content of a specific URL

**Tool (off by default):**
- `web_search_advanced_exa` — advanced search with domain filters, date ranges, category selectors (`company`, `news`, `people`, `auto`)

**API key:** Required (`EXA_API_KEY`). Sign up at `dashboard.exa.ai/api-keys`.

**Free tier:** Available (rate-limited; check current limits at dashboard.exa.ai).

**Installation options:**
- Remote HTTP (preferred): `https://mcp.exa.ai/mcp` — no local install, no Node.js dependency
- npm local: `npx -y exa-mcp-server` with `EXA_API_KEY` env var

**VS Code config (remote):**
```json
{
  "servers": {
    "exa": {
      "type": "http",
      "url": "https://mcp.exa.ai/mcp"
    }
  }
}
```

**Quality assessment:** Exa uses neural (embedding-based) search rather than keyword matching. It is particularly strong on technical documentation queries, API references, and GitHub-hosted content. Arguably the highest quality option for a coding-agent research workload.

**Tradeoff:** API key required; cost is incurred per search on paid tiers. The remote server model means no local install overhead, making it the lightest footprint among paid options.

---

#### 3b. `brave/brave-search-mcp-server` (Brave, official)

**Status note:** `@modelcontextprotocol/server-brave-search` is **archived** and superseded. The current official server is at `https://github.com/brave/brave-search-mcp-server`.

**Tools:**
- `brave_web_search` — full web search with freshness, goggles, result type filtering
- `brave_news_search` — news search (default freshness: last 24h)
- `brave_image_search` — image search
- `brave_video_search` — video search
- `brave_local_search` — local business search (Pro plan required for full results)
- `brave_summarizer` — AI summary of search results (requires `summary: true` in web search call first)

**API key:** Required (`BRAVE_API_KEY`). Register at api.search.brave.com.

**Free tier:** "Data for AI" plan — 2,000 queries/month free; paid at $5 per 1,000 queries.

**Quality:** Good general-purpose web search from an independent index. Less neural than Exa; better than DuckDuckGo for broad queries. The `brave_summarizer` tool is distinctive — provides AI-generated synthesis across multiple results.

**Tradeoff:** API key required; local install via npm; more tools than needed for documentation research (image/video search is noise for a coding agent).

---

#### 3c. DuckDuckGo MCP (`duckduckgo-mcp-server`)

**Tools:**
- `search` — DuckDuckGo web search; params: `query`, `max_results` (default 10), `region`
- `fetch_content` — fetch and parse a webpage; params: `url`, `start_index`, `max_length` (default 8000), `backend` (`httpx`/`curl`/`auto`)

**API key:** NOT required. Completely free, no registration.

**Installation:** `uvx duckduckgo-mcp-server` (Python, via uv — consistent with existing `mcp-server-fetch` pattern in this repo)

**Rate limits:** 30 search requests/minute, 20 fetch requests/minute (built-in)

**Fetch backends:**
- `httpx` (default) — lightweight, works on most sites
- `curl` — Chrome TLS impersonation via `curl_cffi`, passes Cloudflare/bot checks
- `auto` — tries httpx first, falls back to curl on 403

**Quality:** Adequate for documentation discovery. DuckDuckGo is keyword-based and can miss technical nuance that Exa handles better. For "find the MCP server configuration docs for context7" queries, results are generally on-target.

**Note:** This server also provides `fetch_content`, which overlaps with `mcp-server-fetch`. Running both is harmless but slightly redundant.

**Tradeoff:** Free, fast to add, no API key management. Lower search quality than Exa or Brave for precise technical queries. Rate limits can occasionally interrupt research-heavy sessions.

---

#### 3d. Tavily MCP (`tavily-mcp` / `@tavily/mcp`)

**Tools:**
- `tavily-search` — real-time web search
- `tavily-extract` — extract structured data from a specific URL
- `tavily-map` — generate a structured map of a website
- `crawl` — systematic website crawl

**API key:** Required (`TAVILY_API_KEY`). Sign up at `app.tavily.com`.

**Free tier:** 1,000 API credits/month on the free plan.

**Remote server:** `https://mcp.tavily.com/mcp/?tavilyApiKey=<key>` or OAuth flow

**Quality:** Research-oriented. Good for factual and technical queries. The `tavily-map` and `crawl` tools have no equivalent in other search MCPs and are useful for systematic documentation site exploration.

**Relevance note:** Tavily is also the backend powering `vscode-websearchforcopilot` (see §4). Using both is redundant and doubles API key exposure.

---

### 4. `vscode-websearchforcopilot` Extension

**Extension ID:** `ms-vscode.vscode-websearchforcopilot`

**What it provides:**
- Chat participant `@websearch` — handles questions that need live internet information; auto-triggered by intent detection
- Chat tool `#websearch` — can be used as context within any other chat participant (e.g. `@workspace /new #websearch create a Python app using the most popular web framework`)
- Backend: Tavily search API (requires a Tavily API key stored in VS Code secret storage)
- One setting: `websearch.useSearchResultsDirectly` — skip post-processing and return raw results

**Does it provide an LM tool that Copilot agents can call?** Yes — `#websearch` is a VS Code LM Tool available in agent mode. Any agent that has tool access can invoke `#websearch` directly.

**Does it overlap with a search MCP?** Significantly — for VS Code-only use, it provides equivalent search capability to Tavily MCP and requires the same API key.

**Does it eliminate the need for a search MCP?** Partially:

| Scenario | `#websearch` extension | Search MCP |
|----------|----------------------|-----------|
| VS Code agent mode | ✅ Available | ✅ Available |
| Claude Code (CLI) | ❌ Not available | ✅ Available |
| Cursor | ❌ Not available | ✅ Available |
| Cross-client portability | ❌ | ✅ |
| No API key option | ❌ (Tavily required) | ✅ (DuckDuckGo) |

**Verdict:** `vscode-websearchforcopilot` is a clean, first-party solution for web search within VS Code. If portability across clients is not a requirement, it provides a simpler setup path than a search MCP (install from Marketplace, enter Tavily key once). It does NOT eliminate the need for a search MCP if you also use Claude Code or other clients.

---

## Recommendations

### For this repo (Markdown/Shell, VS Code Copilot, no web app)

**Current state:** `mcp-server-fetch` (uvx) already handles known-URL reading. Playwright MCP is already installed as an optional fallback for JS-rendered pages.

**The gap:** URL discovery from natural language queries.

**Recommended addition — Tier 1 (no API key):**

Add `duckduckgo-mcp-server` to `.vscode/mcp.json`:

```json
"duckduckgo": {
  "type": "stdio",
  "command": "uvx",
  "args": ["duckduckgo-mcp-server"]
}
```

This fills the search gap immediately, is consistent with the existing `uvx` pattern, and costs nothing. Quality is adequate for documentation-finding tasks. Rate limits (30 req/min) are non-binding for normal research workloads.

**Recommended addition — Tier 2 (API key, best quality):**

Replace `duckduckgo` with Exa remote HTTP if neural search quality becomes a bottleneck:

```json
"exa": {
  "type": "http",
  "url": "https://mcp.exa.ai/mcp"
}
```

Exa's remote server requires authentication via the `exaApiKey` query parameter or per-session configuration. API key stored in `.vscode/mcp.json` env vars or VS Code secrets.

**Playwright MCP assessment:**

Keep as-is (headless, optional, sandboxed). Its genuine use case — JavaScript-rendered documentation — is real but infrequent. The token overhead from accessibility tree snapshots is the primary cost. Consider disabling it (set `"disabled": true`) and enabling on-demand when `mcp-server-fetch` returns empty or JavaScript-gated content.

**`vscode-websearchforcopilot` assessment:**

A valid alternative to DuckDuckGo MCP if the developer is willing to manage a Tavily API key and VS Code-only portability is acceptable. It avoids an extra MCP server entirely, which reduces startup overhead. Not recommended over DuckDuckGo MCP for a repo that aims to work across Claude Code and Cursor as well.

---

## Gaps / Further research needed

- Exa free tier current quota and rate limits (check `dashboard.exa.ai` — not publicly documented in stable form)
- Context7 MCP (`https://mcp.context7.com/mcp`) already in `.vscode/mcp.json` — confirm whether it provides any web search capability or is documentation-only
- Whether VS Code's `sandboxEnabled` setting applies to remote HTTP MCP servers (relevant for Exa/Tavily remote configs)
