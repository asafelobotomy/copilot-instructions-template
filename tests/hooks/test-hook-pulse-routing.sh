echo "25. user_prompt captures high-confidence Commit route candidate"
TMPDIR_ROUTE_COMMIT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_ROUTE_COMMIT")
mkdir -p "$TMPDIR_ROUTE_COMMIT/.copilot/workspace/identity" "$TMPDIR_ROUTE_COMMIT/.copilot/workspace/knowledge/diaries" "$TMPDIR_ROUTE_COMMIT/.copilot/workspace/operations" "$TMPDIR_ROUTE_COMMIT/.copilot/workspace/runtime"
run_pulse "$TMPDIR_ROUTE_COMMIT" session_start '{"sessionId":"sess-route-commit"}' >/dev/null
run_pulse "$TMPDIR_ROUTE_COMMIT" user_prompt '{"prompt":"Please stage and commit my changes"}' >/dev/null
assert_python_in_root "commit route candidate captured from prompt" "$TMPDIR_ROUTE_COMMIT" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["route_candidate"] == "Commit"
assert state["route_source"] == "prompt"
assert state["route_confidence"] >= 0.74
'
echo ""

echo "26. pre_tool emits sparse Commit routing hint once"
output=$(run_pulse "$TMPDIR_ROUTE_COMMIT" pre_tool '{"tool_name":"run_in_terminal","tool_input":{"command":"git commit -m \"wip\""}}')
assert_matches "commit pre_tool emits routing hint" "$output" 'Routing hint: Commit specialist'
output=$(run_pulse "$TMPDIR_ROUTE_COMMIT" pre_tool '{"tool_name":"run_in_terminal","tool_input":{"command":"git push"}}')
if echo "$output" | grep -q 'Routing hint:'; then
  fail_note "commit hint is not repeated" "     unexpected repeated hint: $output"
else
  pass_note "commit hint is not repeated"
fi
assert_python_in_root "commit hint marks emitted state" "$TMPDIR_ROUTE_COMMIT" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["route_emitted"] is True
assert "Commit" in state["route_emitted_agents"]
'
echo ""

echo "27. guarded Setup does not auto-route from behavior without strict prompt candidate"
TMPDIR_ROUTE_SETUP=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_ROUTE_SETUP")
mkdir -p "$TMPDIR_ROUTE_SETUP/.copilot/workspace/identity" "$TMPDIR_ROUTE_SETUP/.copilot/workspace/knowledge/diaries" "$TMPDIR_ROUTE_SETUP/.copilot/workspace/operations" "$TMPDIR_ROUTE_SETUP/.copilot/workspace/runtime"
run_pulse "$TMPDIR_ROUTE_SETUP" session_start '{"sessionId":"sess-route-setup"}' >/dev/null
output=$(run_pulse "$TMPDIR_ROUTE_SETUP" pre_tool '{"tool_name":"run_in_terminal","tool_input":{"command":"bash SETUP.md"}}')
assert_valid_json "setup behavior-only output is valid JSON" "$output"
if echo "$output" | grep -q 'Routing hint:'; then
  fail_note "setup behavior-only does not emit hint" "     unexpected hint: $output"
else
  pass_note "setup behavior-only does not emit hint"
fi
assert_python_in_root "setup behavior-only leaves candidate empty" "$TMPDIR_ROUTE_SETUP" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["route_candidate"] == ""
'
echo ""

echo "28. guarded Setup is blocked when running in template repo"
TMPDIR_ROUTE_TEMPLATE=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_ROUTE_TEMPLATE")
mkdir -p "$TMPDIR_ROUTE_TEMPLATE/.copilot/workspace/identity" "$TMPDIR_ROUTE_TEMPLATE/.copilot/workspace/knowledge/diaries" "$TMPDIR_ROUTE_TEMPLATE/.copilot/workspace/operations" "$TMPDIR_ROUTE_TEMPLATE/.copilot/workspace/runtime" "$TMPDIR_ROUTE_TEMPLATE/.github" "$TMPDIR_ROUTE_TEMPLATE/template"
printf '# test\n' > "$TMPDIR_ROUTE_TEMPLATE/.github/copilot-instructions.md"
printf '# test\n' > "$TMPDIR_ROUTE_TEMPLATE/template/copilot-instructions.md"
run_pulse "$TMPDIR_ROUTE_TEMPLATE" session_start '{"sessionId":"sess-route-template"}' >/dev/null
run_pulse "$TMPDIR_ROUTE_TEMPLATE" user_prompt '{"prompt":"Update your instructions"}' >/dev/null
output=$(run_pulse "$TMPDIR_ROUTE_TEMPLATE" pre_tool '{"tool_name":"run_in_terminal","tool_input":{"command":"bash UPDATE.md"}}')
if echo "$output" | grep -q 'Routing hint: Setup'; then
  fail_note "setup hint is blocked in template repo" "     unexpected setup hint: $output"
else
  pass_note "setup hint is blocked in template repo"
fi

echo ""

echo "29. Stage 3 prompt+behavior routes are deterministic for newly active specialists"
for agent in Planner Docs Debugger Review Audit Extensions Organise; do
  tmpdir_agent=$(mktemp -d); CLEANUP_DIRS+=("$tmpdir_agent")
  mkdir -p "$tmpdir_agent/.copilot/workspace/identity" "$tmpdir_agent/.copilot/workspace/knowledge/diaries" "$tmpdir_agent/.copilot/workspace/operations" "$tmpdir_agent/.copilot/workspace/runtime"
  run_pulse "$tmpdir_agent" session_start '{"sessionId":"sess-route-stage3"}' >/dev/null
  case "$agent" in
    Planner)
      prompt='Please break this down into an execution plan'
      pre_payload='{"tool_name":"read_file"}'
      ;;
    Docs)
      prompt='Please document this in the README'
      pre_payload='{"tool_name":"create_file","tool_input":{"path":"README.md"}}'
      ;;
    Debugger)
      prompt='Please debug this failing test regression and find the root cause'
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"pytest tests/hooks/test-hook-pulse.sh"}}'
      ;;
    Review)
      prompt='Please run a formal code review and provide findings'
      pre_payload='{"tool_name":"get_changed_files"}'
      ;;
    Audit)
      prompt='Run a security audit and check for residual risk'
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"python scripts/copilot_audit.py --help"}}'
      ;;
    Extensions)
      prompt='Review my VS Code extensions profile and sync recommendations'
      pre_payload='{"tool_name":"get_active_profile"}'
      ;;
    Organise)
      prompt='Reorganize this repo and move files to fix paths'
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"git mv old.md new.md"}}'
      ;;
  esac

  run_pulse "$tmpdir_agent" user_prompt "{\"prompt\":\"$prompt\"}" >/dev/null
  assert_python_in_root "$agent prompt candidate captured" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/runtime/state.json').read_text(encoding='utf-8'))
assert state['route_candidate'] == '$agent'
assert state['route_source'] == 'prompt'
"

  output=$(run_pulse "$tmpdir_agent" pre_tool "$pre_payload")
  assert_matches "$agent pre_tool emits routing hint" "$output" "Routing hint: $agent specialist"
  assert_python_in_root "$agent hint records emitted state" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/runtime/state.json').read_text(encoding='utf-8'))
assert state['route_emitted'] is True
assert '$agent' in state['route_emitted_agents']
"
done

echo ""

echo "30. overlap-sensitive Fast and Code do not auto-route from behavior alone"
for agent in Fast Code; do
  tmpdir_agent=$(mktemp -d); CLEANUP_DIRS+=("$tmpdir_agent")
  mkdir -p "$tmpdir_agent/.copilot/workspace/identity" "$tmpdir_agent/.copilot/workspace/knowledge/diaries" "$tmpdir_agent/.copilot/workspace/operations" "$tmpdir_agent/.copilot/workspace/runtime"
  run_pulse "$tmpdir_agent" session_start '{"sessionId":"sess-route-stage4-behavior-only"}' >/dev/null
  case "$agent" in
    Fast)
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"wc -l CHANGELOG.md"}}'
      ;;
    Code)
      pre_payload='{"tool_name":"create_file","tool_input":{"path":"feature.py"}}'
      ;;
  esac

  output=$(run_pulse "$tmpdir_agent" pre_tool "$pre_payload")
  assert_valid_json "$agent behavior-only output is valid JSON" "$output"
  if echo "$output" | grep -q 'Routing hint:'; then
    fail_note "$agent behavior-only does not emit hint" "     unexpected hint: $output"
  else
    pass_note "$agent behavior-only does not emit hint"
  fi
  assert_python_in_root "$agent behavior-only leaves candidate empty" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/runtime/state.json').read_text(encoding='utf-8'))
assert state['route_candidate'] == ''
"
done

echo ""

echo "31. Stage 4 prompt+behavior routes are deterministic for overlap-sensitive specialists"
for agent in Fast Code; do
  tmpdir_agent=$(mktemp -d); CLEANUP_DIRS+=("$tmpdir_agent")
  mkdir -p "$tmpdir_agent/.copilot/workspace/identity" "$tmpdir_agent/.copilot/workspace/knowledge/diaries" "$tmpdir_agent/.copilot/workspace/operations" "$tmpdir_agent/.copilot/workspace/runtime"
  run_pulse "$tmpdir_agent" session_start '{"sessionId":"sess-route-stage4"}' >/dev/null
  case "$agent" in
    Fast)
      prompt='This is a quick question: what does this regex match?'
      pre_payload='{"tool_name":"run_in_terminal","tool_input":{"command":"wc -l CHANGELOG.md"}}'
      ;;
    Code)
      prompt='Implement this feature and write tests for it'
      pre_payload='{"tool_name":"create_file","tool_input":{"path":"feature.py"}}'
      ;;
  esac

  run_pulse "$tmpdir_agent" user_prompt "{\"prompt\":\"$prompt\"}" >/dev/null
  assert_python_in_root "$agent prompt candidate captured" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/runtime/state.json').read_text(encoding='utf-8'))
assert state['route_candidate'] == '$agent'
assert state['route_source'] == 'prompt'
"

  output=$(run_pulse "$tmpdir_agent" pre_tool "$pre_payload")
  assert_matches "$agent pre_tool emits routing hint" "$output" "Routing hint: $agent specialist"
  assert_python_in_root "$agent hint records emitted state" "$tmpdir_agent" "
state = json.loads((root / '.copilot/workspace/runtime/state.json').read_text(encoding='utf-8'))
assert state['route_emitted'] is True
assert '$agent' in state['route_emitted_agents']
assert state['route_source'] == 'prompt+behavior'
"
done

echo ""
echo "32. PostToolUse emits reflect instruction once when signal_reflection_likely is set"
TMPDIR_REFLECT=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_REFLECT")
mkdir -p "$TMPDIR_REFLECT/.copilot/workspace/identity" "$TMPDIR_REFLECT/.copilot/workspace/knowledge/diaries" "$TMPDIR_REFLECT/.copilot/workspace/operations" "$TMPDIR_REFLECT/.copilot/workspace/runtime"
run_pulse "$TMPDIR_REFLECT" session_start '{"sessionId":"sess-32"}' >/dev/null
python3 - <<PY
import json
from pathlib import Path
p = Path("$TMPDIR_REFLECT/.copilot/workspace/runtime/state.json")
state = json.loads(p.read_text(encoding="utf-8"))
# Set copilot_edit_count high enough to trigger strong signal (threshold=8)
# since sandbox has no real git changes, recommend_retrospective falls back to edit count
state["copilot_edit_count"] = 10
state["reflect_instruction_emitted"] = False
state["retrospective_state"] = "idle"
state["last_soft_trigger_epoch"] = 0
p.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
PY
output=$(run_pulse "$TMPDIR_REFLECT" soft_post_tool '{"tool_name":"run_in_terminal"}')
assert_valid_json "reflect instruction output is valid JSON" "$output"
assert_matches "reflect instruction appears in additionalContext" "$output" 'session_reflect'
assert_python_in_root "reflect_instruction_emitted is persisted" "$TMPDIR_REFLECT" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["reflect_instruction_emitted"] is True, "expected True got %s" % state["reflect_instruction_emitted"]
assert state["retrospective_state"] == "suggested", "expected suggested got %s" % state["retrospective_state"]
'
echo ""

echo "33. PostToolUse does not re-emit reflect instruction after first emission"
output2=$(run_pulse "$TMPDIR_REFLECT" soft_post_tool '{"tool_name":"run_in_terminal"}')
assert_valid_json "second soft_post_tool output is valid JSON" "$output2"
if echo "$output2" | grep -q 'session_reflect'; then
  fail_note "second call must not re-emit reflect instruction" "     unexpected session_reflect in output: $output2"
else
  pass_note "second call must not re-emit reflect instruction"
fi

echo ""
echo "34. session_start writes state to fallback path when workspace is read-only"
TMPDIR_RDONLY=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_RDONLY")
mkdir -p "$TMPDIR_RDONLY/.copilot/workspace/identity" "$TMPDIR_RDONLY/.copilot/workspace/knowledge/diaries" "$TMPDIR_RDONLY/.copilot/workspace/operations" "$TMPDIR_RDONLY/.copilot/workspace/runtime"
chmod 0555 "$TMPDIR_RDONLY/.copilot/workspace/runtime"
output=$(CLAUDE_TMPDIR="$TMPDIR_RDONLY/.hb-tmp" TMPDIR="$TMPDIR_RDONLY/.hb-tmp" run_pulse "$TMPDIR_RDONLY" session_start '{"sessionId":"sess-34"}')
chmod 0755 "$TMPDIR_RDONLY/.copilot/workspace/runtime"  # restore so cleanup works
assert_valid_json "read-only workspace session_start returns valid JSON" "$output"
assert_matches "read-only workspace session_start continues" "$output" '"continue": true'
# Primary state.json must NOT have been written (dir was 0555)
if [ -f "$TMPDIR_RDONLY/.copilot/workspace/runtime/state.json" ]; then
  fail_note "state.json was NOT written to read-only primary path" "     file exists at primary path"
else
  pass_note "state.json was NOT written to read-only primary path"
fi
# Fallback state.json MUST have been written somewhere under CLAUDE_TMPDIR
hb_tmp="$TMPDIR_RDONLY/.hb-tmp"
fallback_count=$(find "$hb_tmp" -name 'state.json' 2>/dev/null | wc -l)
if [ "$fallback_count" -ge 1 ]; then
  pass_note "state.json written to fallback path"
else
  fail_note "state.json written to fallback path" "     no state.json found under $hb_tmp"
fi

echo ""
echo "35. routing manifest absent: session_start succeeds and routing is disabled"
TMPDIR_NOROUTE=$(mktemp -d); CLEANUP_DIRS+=("$TMPDIR_NOROUTE")
mkdir -p "$TMPDIR_NOROUTE/.copilot/workspace/identity" "$TMPDIR_NOROUTE/.copilot/workspace/knowledge/diaries" "$TMPDIR_NOROUTE/.copilot/workspace/operations" "$TMPDIR_NOROUTE/.copilot/workspace/runtime"
# Create an empty routing manifest (zero agents) in the workspace so the CWD-relative
# lookup wins over the walk-up fallback.  This is the canonical "no routing configured"
# state that consumers can ship during early setup.
mkdir -p "$TMPDIR_NOROUTE/agents"
echo '{"version":1,"agents":[]}' > "$TMPDIR_NOROUTE/agents/routing-manifest.json"
# No agents/routing-manifest.json — should fail-closed (no routing)
output=$(run_pulse "$TMPDIR_NOROUTE" session_start '{"sessionId":"sess-35"}')
assert_valid_json "no-manifest session_start returns valid JSON" "$output"
assert_matches "no-manifest session_start continues" "$output" '"continue": true'
output=$(run_pulse "$TMPDIR_NOROUTE" user_prompt '{"prompt":"Please stage and commit my changes"}')
assert_valid_json "no-manifest user_prompt returns valid JSON" "$output"
assert_python_in_root "no-manifest: routing candidate is empty (fail-closed)" "$TMPDIR_NOROUTE" '
state = json.loads((root / ".copilot/workspace/runtime/state.json").read_text(encoding="utf-8"))
assert state["route_candidate"] == "", "expected empty candidate, got %s" % state["route_candidate"]
'

