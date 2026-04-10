# Research: VS Code MCP Sandbox — `/tmp/claude` Write Failures and `socks5h://` Proxy Errors

> Date: 2026-04-10 | Agent: Researcher | Status: complete

## Summary

Two distinct bugs affect stdio MCP servers running under the VS Code Insiders
Anthropic sandbox runtime (`@anthropic-ai/sandbox-runtime@0.0.42`). First, the
sandbox sets `TMPDIR=/tmp/claude` inside every bwrap container, but the directory
does not exist on this host, so bwrap silently skips the bind-mount and all writes
to that path fail. Server code that falls back from the workspace path to
`tempfile.gettempdir()` therefore falls back to an unwritable, non-existent path.
Second, `ALL_PROXY=socks5h://localhost:1080` is injected as a `--setenv` argument
into every sandboxed process; `mcp-server-fetch@2025.4.7` uses `httpx<0.28`, which
raises `ValueError: Unknown scheme for proxy URL URL('socks5h://localhost:1080')` at
client construction time because it does not recognise that scheme. Both failures are
rooted in the sandbox runtime, not in user-space code.

---

## Sources

| URL | Relevance |
|-----|-----------|
| `/opt/visual-studio-code-insiders/resources/app/node_modules/@anthropic-ai/sandbox-runtime/dist/sandbox/sandbox-utils.js` | `getDefaultWritePaths`, `generateProxyEnvVars`, confirms TMPDIR default |
| `/opt/visual-studio-code-insiders/resources/app/node_modules/@anthropic-ai/sandbox-runtime/dist/sandbox/linux-sandbox-utils.js` | `generateFilesystemArgs` — `!fs.existsSync(normalizedPath)` guard |
| `/opt/visual-studio-code-insiders/resources/app/node_modules/@anthropic-ai/sandbox-runtime/dist/sandbox/sandbox-manager.js` | `wrapWithSandbox` merges `getDefaultWritePaths()` into `allowOnly` |
| `~/.cache/uv/archive-v0/e69PtoFU3_LyN99J0jBF9/httpx/_config.py` | `httpx 0.27.2` — `Proxy.__init__` only accepts `http`, `https`, `socks5` |
| `~/.cache/uv/archive-v0/CTC1-HivFdy4UVtKcUEhy/httpx/_config.py` | `httpx 0.28.1` — same gate now includes `socks5h` |
| `~/.cache/uv/archive-v0/pO-kgK6IlruyghP-SK_wY/mcp_server_fetch/server.py` | `mcp-server-fetch` reads env proxies implicitly via `AsyncClient(proxies=None)` |

---

## Findings

### 1 — Anthropic sandbox runtime version and scope

`@anthropic-ai/sandbox-runtime@0.0.42` is installed at:

```
/opt/visual-studio-code-insiders/resources/app/node_modules/@anthropic-ai/sandbox-runtime/
```

It is the sandbox engine used by both the VS Code Insiders agent terminal (for `run_in_terminal`) and MCP stdio servers when `sandboxEnabled: true` is set in `mcp.json`. On Linux it wraps each command in `bwrap` (Bubblewrap) with:

- `--unshare-net` (network namespace isolation)
- `--unshare-pid` + `--proc /proc` (PID namespace)
- `--ro-bind / /` (read-only root), then `--bind <path> <path>` for every writable path
- seccomp BPF filter (optional; blocks Unix socket creation)
- `--dev /dev`

Two local proxy servers are spawned by the runtime:

| Role | Transport | Listen address |
|------|-----------|----------------|
| HTTP proxy (`http-proxy.js`) | TCP | `127.0.0.1:<random>`, exposed in sandbox via socat → `/tmp/claude-http-*.sock` |
| SOCKS5 proxy (`socks-proxy.js`) | TCP | `127.0.0.1:<random>`, exposed in sandbox via Unix socket `/tmp/claude-socks-*.sock` |

These implement the `allowedDomains` allowlist. Network requests that do not match any allowed domain are blocked.

---

### 2 — `TMPDIR=/tmp/claude` write failures: full causal chain

**`sandbox-utils.js` — `generateProxyEnvVars(httpProxyPort, socksProxyPort)`:**

```javascript
const tmpdir = process.env.CLAUDE_TMPDIR || '/tmp/claude';
const envVars = [`SANDBOX_RUNTIME=1`, `TMPDIR=${tmpdir}`];
```

This is called with `httpProxyPort=3128` and `socksProxyPort=1080` (internal sandbox values)
and the resulting key=value pairs are injected via `--setenv` into bwrap.

**`sandbox-manager.js` — `wrapWithSandbox()`:**

```javascript
// Always include default system write paths (like /dev/null, /tmp/claude)
const userAllowWrite = stripWriteGlobs(customConfig?.filesystem?.allowWrite ?? ...);
const writeConfig = {
    allowOnly: [...getDefaultWritePaths(), ...userAllowWrite],
    ...
};
```

`getDefaultWritePaths()` explicitly includes `/tmp/claude` and `/private/tmp/claude`.
So the intent is for `/tmp/claude` to be writable inside bwrap.

**`linux-sandbox-utils.js` — `generateFilesystemArgs()`:**

```javascript
if (!fs.existsSync(normalizedPath)) {
    logForDebugging(`[Sandbox Linux] Skipping non-existent write path: ${normalizedPath}`);
    continue;
}
...
args.push('--bind', normalizedPath, normalizedPath);
```

**This is the silent failure point.** If `/tmp/claude` does not exist on the host
at the time bwrap is launched, `generateFilesystemArgs` skips the `--bind` for it and
logs only a debug message (not surfaced to users). Inside bwrap:

- `TMPDIR` is set to `/tmp/claude`
- `/tmp/claude` does not exist (nothing was bound)
- Any call to `tempfile.gettempdir()`, `tempfile.mkdtemp()`, `os.getenv("TMPDIR")`,
  or `Path(os.environ["TMPDIR"])` resolves to `/tmp/claude`
- Writes fail with `FileNotFoundError` or `EROFS` depending on the code path

**Verification:** `ls /tmp/claude` → `No such file or directory` (confirmed on this host).

**Effect on the heartbeat server (`mcp-heartbeat-server.py`):**

The fallback hierarchy in `_fallback_artifact_roots()` is:

1. `os.environ.get("TMPDIR")` → `/tmp/claude` inside sandbox → **non-existent, fails**
2. `tempfile.gettempdir()` → also `/tmp/claude` (reads TMPDIR) → **non-existent, fails**
3. `XDG_CACHE_HOME/uv` → unset inside sandbox
4. `passwd_home/.cache/uv` → may be readable but depends on bwrap bind config
5. `Path.home()/.cache/uv` → same

If the workspace write (the primary path) also fails (e.g. running in a context without
workspace bind), every fallback that touches TMPDIR fails silently.

---

### 3 — `socks5h://` proxy error: full causal chain

**Sandbox injected environment (confirmed from `env | grep -i proxy`):**

```
HTTP_PROXY=http://localhost:3128
HTTPS_PROXY=http://localhost:3128
http_proxy=http://localhost:3128
https_proxy=http://localhost:3128
ALL_PROXY=socks5h://localhost:1080
all_proxy=socks5h://localhost:1080
FTP_PROXY=socks5h://localhost:1080
ftp_proxy=socks5h://localhost:1080
GRPC_PROXY=socks5h://localhost:1080
grpc_proxy=socks5h://localhost:1080
RSYNC_PROXY=localhost:1080
NO_PROXY=localhost,127.0.0.1,::1,...
GIT_SSH_COMMAND=ssh -o ProxyCommand='socat - PROXY:localhost:%h:%p,proxyport=3128'
SANDBOX_RUNTIME=1
CLAUDE_CODE_HOST_HTTP_PROXY_PORT=34545
CLAUDE_CODE_HOST_SOCKS_PROXY_PORT=39553
```

The `socks5h://` scheme means SOCKS5 with remote DNS—the sandbox deliberately uses this to
prevent DNS leaks, because name resolution happens at the proxy server rather than inside
the isolated network namespace.

**`mcp-server-fetch@2025.4.7` dependency:**

```
Requires-Dist: httpx<0.28
```

Installed: `httpx==0.27.2`.

**`httpx 0.27.2` `Proxy.__init__` (`httpx/_config.py:337`):**

```python
if url.scheme not in ("http", "https", "socks5"):
    raise ValueError(f"Unknown scheme for proxy URL {url!r}")
```

When `httpx.AsyncClient()` is constructed without explicit `proxies=`, httpx reads
environment variables including `ALL_PROXY`. It creates a `Proxy` object for each
env var, and when it encounters `ALL_PROXY=socks5h://localhost:1080`, the scheme
check triggers `ValueError: Unknown scheme for proxy URL URL('socks5h://localhost:1080')`.

**`httpx 0.28.1` fix** (confirmed in `httpx/_config.py:213` of installed 0.28.1):

```python
if url.scheme not in ("http", "https", "socks5", "socks5h"):
    raise ValueError(f"Unknown scheme for proxy URL {url!r}")
```

`socks5h` was added to the accepted set. `mcp-server-fetch`'s `httpx<0.28` pin is the
version constraint blocking the fix.

---

### 4 — Environment rewriting layers (two separate systems)

| Context | Who rewrites | What changes |
|---------|-------------|--------------|
| VS Code extension terminal/shell | VS Code Insiders extension host | `TMPDIR → /home/solon/.vscode-insiders/tmp/tmp_vscode_1` |
| Inside bwrap (MCP sandboxed commands) | `@anthropic-ai/sandbox-runtime` via `--setenv` | `TMPDIR → /tmp/claude`, `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY`, `NO_PROXY`, `GIT_SSH_COMMAND`, `SANDBOX_RUNTIME=1` |

These are independent. The terminal's `TMPDIR` override is visible outside bwrap; the
bwrap `--setenv` values replace those inside bwrap.

The runtime also respects `CLAUDE_TMPDIR` on the parent process (the outer shell or
VS Code extension process) to override the `/tmp/claude` default:

```javascript
const tmpdir = process.env.CLAUDE_TMPDIR || '/tmp/claude';
```

Setting `CLAUDE_TMPDIR` in the VS Code extension environment (e.g. via a `.env` file or
launch profile) would propagate into the bwrap `--setenv TMPDIR <value>` call, but only
if the **sandbox runtime process** inherits it—not just the inner terminal session.

---

### 5 — Why `mcp_fetch_fetch` in this session also fails

Every call to `fetch_webpage` or `mcp_fetch_fetch` goes through the sandboxed
`mcp-server-fetch` process. With `httpx<0.28` and `ALL_PROXY=socks5h://localhost:1080`
in the environment, every `httpx.AsyncClient()` construction raises `ValueError`. No
URL can be fetched. This is why all three initial parallel fetches in this research
session returned the proxy error immediately.

---

## Recommendations

### Fix A — Create `/tmp/claude` on the host (immediate, low friction)

```bash
mkdir -p /tmp/claude
```

This unblocks all TMPDIR-based writes inside bwrap immediately. The sandbox will
bind-mount it as writable. Add this to session startup scripts or
`.vscode/settings.json` `terminal.integrated.env.linux` profile if needed persistently.
Note: `/tmp` is typically cleared on reboot, so this must be re-created or placed in a
more persistent location via `CLAUDE_TMPDIR`.

### Fix B — Pin `mcp-server-fetch` to `httpx>=0.28` (correct long-term fix)

In `.vscode/mcp.json`, override with a local `uvx` invocation or wait for an upstream
`mcp-server-fetch` release that drops the `httpx<0.28` constraint. Until then:

```json
"fetch": {
    "type": "stdio",
    "command": "uvx",
    "args": ["--with", "httpx>=0.28", "mcp-server-fetch"]
}
```

`httpx 0.28.1` accepts `socks5h://` natively.

### Fix C — Unset `ALL_PROXY` in the fetch server's env block (immediate workaround)

VS Code `mcp.json` supports per-server `env` overrides:

```json
"fetch": {
    "type": "stdio",
    "command": "uvx",
    "args": ["mcp-server-fetch"],
    "env": {
        "ALL_PROXY": "",
        "all_proxy": "",
        "GRPC_PROXY": "",
        "grpc_proxy": ""
    },
    ...
}
```

This clears `ALL_PROXY` before the server process starts (before httpx reads env).
The schema-specific `HTTP_PROXY`/`HTTPS_PROXY` vars remain, so the sandbox's HTTP
proxy filtering still operates normally.

**Caution:** this is documented in the VS Code MCP config spec as the `env` map, but
the sandbox runtime injects its own `--setenv` values *after* the parent env. If the
sandbox runtime overrides with `--setenv ALL_PROXY ...` inside bwrap, the parent-level
`env` block may not be honoured for the bwrap-internal value. Testing is required.

### Fix D — Set `CLAUDE_TMPDIR` in the VS Code extension host environment

Set `CLAUDE_TMPDIR` to an existing, writable path (e.g. `${userHome}/.cache/uv`) in
the environment that VS Code Insiders runs under (login profile, systemd service).
The sandbox runtime reads this before launching bwrap and uses it as the value for
`--setenv TMPDIR`.

Example (add to `~/.profile` or the VS Code launch `.env`):

```bash
export CLAUDE_TMPDIR="${HOME}/.cache/vscode-sandbox-tmp"
mkdir -p "${HOME}/.cache/vscode-sandbox-tmp"
```

Then add it to `mcp.json`'s top-level `sandbox.filesystem.allowWrite`.

---

## Diagnostic Steps

Run these locally to confirm the diagnoses:

```bash
# 1. Confirm /tmp/claude does not exist
ls /tmp/claude 2>&1

# 2. Confirm sandbox runtime TMPDIR default
grep -n "CLAUDE_TMPDIR\|/tmp/claude" \
  /opt/visual-studio-code-insiders/resources/app/node_modules/@anthropic-ai/sandbox-runtime/dist/sandbox/sandbox-utils.js

# 3. Confirm the silent skip guard
grep -n "Skipping non-existent write path" \
  /opt/visual-studio-code-insiders/resources/app/node_modules/@anthropic-ai/sandbox-runtime/dist/sandbox/linux-sandbox-utils.js

# 4. Confirm current installed httpx version in uv cache
find ~/.cache/uv/archive-v0 -name "*.dist-info" -path "*httpx*" -exec basename {} \; | sort -u

# 5. Confirm httpx 0.27.x Proxy scheme gate
grep -n "socks5h\|unknown scheme\|Unknown scheme" \
  ~/.cache/uv/archive-v0/e69PtoFU3_LyN99J0jBF9/httpx/_config.py

# 6. Confirm httpx 0.28.x adds socks5h
grep -n "socks5h\|unknown scheme\|Unknown scheme" \
  ~/.cache/uv/archive-v0/CTC1-HivFdy4UVtKcUEhy/httpx/_config.py

# 7. Confirm mcp-server-fetch httpx constraint
grep "httpx" ~/.cache/uv/archive-v0/pO-kgK6IlruyghP-SK_wY/mcp_server_fetch-2025.4.7.dist-info/METADATA

# 8. Check current proxy environment inside a sandbox command (VS Code terminal must have SANDBOX_RUNTIME=1 set)
echo $SANDBOX_RUNTIME; echo $ALL_PROXY; echo $TMPDIR

# 9. Apply Fix A and retest fetch
mkdir -p /tmp/claude && uvx --with "httpx>=0.28" mcp-server-fetch --version 2>/dev/null
```

---

## Gaps / Further Research Needed

- **VS Code MCP `env` override vs bwrap `--setenv`**: does a per-server `env` block in
  `mcp.json` run before or after the sandbox runtime injects its env vars? If `--setenv`
  always wins, Fix C (env block) is not viable for the bwrap-internal environment.
  Testing needed by starting a sandboxed MCP server and reading its env from a tool.

- **`CLAUDE_TMPDIR` propagation path**: confirm whether setting it in the VS Code
  extension host environment (rather than just the terminal shell) is sufficient for the
  sandbox runtime to pick it up. The runtime JS process needs to inherit it, not just
  any child bash session.

- **`mcp-server-fetch` upgrade timeline**: a newer release that drops `httpx<0.28` would
  be the cleanest fix. No upstream GitHub issue could be fetched (network blocked by the
  very bug we're investigating). Worth checking
  `https://github.com/modelcontextprotocol/servers/releases` once the proxy is fixed.

- **Sandbox debug logging**: `CLAUDE_CODE_DEBUG=1` or `ANTHROPIC_SANDBOX_DEBUG=1` may
  expose runtime log messages such as `[Sandbox Linux] Skipping non-existent write
  path: /tmp/claude`. Confirm the exact env var name.
