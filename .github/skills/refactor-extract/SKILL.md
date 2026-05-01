---
name: refactor-extract
description: Systematically extract a function, class, module, or service from existing code — identify boundaries, write tests before moving, verify behaviour is unchanged
compatibility: ">=0.7.0"
---

# Refactor Extract

> Skill metadata: version "1.0"; license MIT; tags [refactor, extract, clean-code, testing, modules]; compatibility ">=0.7.0"; recommended tools [codebase, editFiles, runCommands].

Safely extract a function, class, module, or service from existing code. Follows the "test before move" principle: characterise current behaviour first, then extract, then verify the characterisation still passes.

## When to use

- User asks to "extract a function", "pull this into its own module/class/service", "refactor this block"
- A function exceeds ~40 lines or has more than one responsibility
- Code is duplicated in two or more places and needs a shared home
- Preparing to move to a microservice boundary

## When not to use

- The goal is a full architectural redesign — break that into separate tasks
- The code has zero test coverage and the user refuses to add characterisation tests first

## Steps

### 1. Identify extraction boundaries

Before writing anything:

- Read the full source function/class
- Identify the **inputs** (parameters, globals, imports read) and **outputs** (return value, side effects, mutations)
- Check for hidden coupling: closures, shared mutable state, hardcoded paths
- Name the extracted unit: verb-noun for functions (`parse_config`), noun for classes (`ConfigParser`), noun for modules (`config/`)

State the proposed interface in one line before proceeding. If the interface is unclear, ask the user.

### 2. Write characterisation tests (if none exist)

Before moving any code:

```python
# Example — characterise current behaviour
def test_parse_config_returns_dict():
    result = legacy_module.parse_config("key=value")
    assert result == {"key": "value"}
```

Run the tests. They must pass against the original code. These are your safety net.

### 3. Create the extraction target

| Extraction type | Target |
|----------------|--------|
| Function | Same file or new file in same module |
| Class | New file, same package/directory |
| Module | New directory with `__init__.py` / `index.ts` / `mod.rs` |
| Service | New top-level package; expose via interface/trait/protocol |

Write the extracted unit with the identified interface. Do not add new behaviour — extraction only.

### 4. Update the call site

Replace the original code with a call to the extracted unit. Keep the original in place (commented or via alias) until tests pass.

### 5. Run the characterisation tests

Tests must pass unchanged. If they fail:

- The interface did not match — fix the extracted unit
- There was hidden coupling — resolve before proceeding (do not work around it)

### 6. Clean up

- Remove the original inline code
- Remove any temporary aliases
- Run the full test suite
- Update imports across the codebase (`grep` or IDE symbol search)

### 7. Verify no behaviour change

```bash
# Run full test suite
# Confirm no new failures
# Check for any missed call sites
grep -rn "original_function_name" .
```

## Verify

- [ ] Characterisation tests written and passing before extraction
- [ ] Extracted unit has a single clear interface
- [ ] No new behaviour added during extraction
- [ ] All call sites updated
- [ ] Full test suite passes
- [ ] No dead code left behind
