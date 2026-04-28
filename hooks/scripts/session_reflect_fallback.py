#!/usr/bin/env python3
"""Direct session_reflect fallback runner.

# purpose: Invoke session_reflect directly through the heartbeat server implementation when the extension or deferred-tool path is unavailable.
# when: Use only after direct tool invocation and deferred loading are unavailable; do not use this when session_reflect is already callable as a tool.
# inputs: --root <path> optional workspace root, --script <path> optional heartbeat server path.
# outputs: JSON session_reflect payload on stdout.
# risk: safe
# source: original
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
import sys
import types
from pathlib import Path


class FakeMCP:
    def tool(self):
        def decorator(fn):
            return fn

        return decorator

    def run(self) -> None:
        return None


def install_fake_mcp_modules() -> None:
    mcp_mod = types.ModuleType("mcp")
    server_mod = types.ModuleType("mcp.server")
    fastmcp_mod = types.ModuleType("mcp.server.fastmcp")
    fastmcp_mod.FastMCP = lambda *args, **kwargs: FakeMCP()
    sys.modules["mcp"] = mcp_mod
    sys.modules["mcp.server"] = server_mod
    sys.modules["mcp.server.fastmcp"] = fastmcp_mod


def parse_args() -> argparse.Namespace:
    default_script = Path(__file__).with_name("mcp-heartbeat-server.py")
    parser = argparse.ArgumentParser(
        description="Run session_reflect directly through the heartbeat server implementation."
    )
    parser.add_argument(
        "--root",
        default=str(Path.cwd()),
        help="Workspace root to reflect on. Defaults to the current directory.",
    )
    parser.add_argument(
        "--script",
        default=str(default_script),
        help="Path to mcp-heartbeat-server.py. Defaults to the sibling hook script.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    script = Path(args.script).resolve()

    if not script.exists():
        print(json.dumps({"error": f"heartbeat server not found: {script}"}))
        return 1

    os.chdir(root)
    install_fake_mcp_modules()

    spec = importlib.util.spec_from_file_location("heartbeat_mcp", script)
    if spec is None or spec.loader is None:
        print(json.dumps({"error": f"could not load heartbeat server: {script}"}))
        return 1

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    if not hasattr(module, "session_reflect"):
        print(json.dumps({"error": "heartbeat server does not export session_reflect"}))
        return 1

    payload = module.session_reflect()
    print(json.dumps(payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())