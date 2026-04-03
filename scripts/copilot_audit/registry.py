"""Central registry of Copilot Audit checks."""
from __future__ import annotations

from .checks_agents import (
    check_a1_agent_frontmatter,
    check_a2_agent_handoffs,
    check_a3_agent_no_placeholders,
    check_a4_agent_delegation_matrix,
)
from .checks_hooks import (
    check_h1_hooks_valid_json,
    check_h2_hooks_scripts_exist,
    check_ps1_basic_sanity,
    check_sh1_shebang,
    check_sh2_pipefail,
    check_sh3_bash_syntax,
)
from .checks_instructions import (
    check_i1_instructions_placeholders,
    check_i2_instructions_length,
    check_i3_instruction_stubs,
    check_i4_delegation_policy,
)
from .checks_kits import (
    check_k1_starter_kit_plugins,
    check_k2_starter_registry,
)
from .checks_mcp import (
    check_m1_mcp_valid_json,
    check_m2_mcp_no_npm_antipatterns,
    check_m3_mcp_no_secrets,
)
from .checks_prompts import check_p1_prompt_mode
from .checks_skills import (
    check_s1_skill_name_matches_dir,
    check_s2_skill_size,
)
from .checks_vscode import check_vs1_settings_plugins

DEVELOPER_CHECKS = (
    check_a1_agent_frontmatter,
    check_a2_agent_handoffs,
    check_a3_agent_no_placeholders,
    check_a4_agent_delegation_matrix,
    check_i1_instructions_placeholders,
    check_i2_instructions_length,
    check_i3_instruction_stubs,
    check_i4_delegation_policy,
    check_p1_prompt_mode,
    check_s1_skill_name_matches_dir,
    check_s2_skill_size,
    check_k1_starter_kit_plugins,
    check_k2_starter_registry,
    check_m1_mcp_valid_json,
    check_m2_mcp_no_npm_antipatterns,
    check_m3_mcp_no_secrets,
    check_h1_hooks_valid_json,
    check_h2_hooks_scripts_exist,
    check_sh1_shebang,
    check_sh2_pipefail,
    check_sh3_bash_syntax,
    check_ps1_basic_sanity,
    check_vs1_settings_plugins,
)

CONSUMER_CHECKS = (
    check_a1_agent_frontmatter,
    check_a2_agent_handoffs,
    check_a3_agent_no_placeholders,
    check_i1_instructions_placeholders,
    check_i3_instruction_stubs,
    check_p1_prompt_mode,
    check_s1_skill_name_matches_dir,
    check_s2_skill_size,
    check_m1_mcp_valid_json,
    check_m2_mcp_no_npm_antipatterns,
    check_m3_mcp_no_secrets,
    check_h1_hooks_valid_json,
    check_h2_hooks_scripts_exist,
    check_sh1_shebang,
    check_sh2_pipefail,
    check_sh3_bash_syntax,
    check_ps1_basic_sanity,
    check_vs1_settings_plugins,
)

DEFAULT_PROFILE = "developer"
ALL_CHECKS = DEVELOPER_CHECKS
CHECK_PROFILES = {
    DEFAULT_PROFILE: DEVELOPER_CHECKS,
    "consumer": CONSUMER_CHECKS,
}
PROFILES = tuple(CHECK_PROFILES)


def checks_for_profile(profile: str):
    """Return the ordered check tuple for the requested audit profile."""
    try:
        return CHECK_PROFILES[profile]
    except KeyError as exc:
        raise ValueError(f"Unknown audit profile: {profile}") from exc


__all__ = [
    "ALL_CHECKS",
    "CHECK_PROFILES",
    "DEFAULT_PROFILE",
    "PROFILES",
    "checks_for_profile",
]