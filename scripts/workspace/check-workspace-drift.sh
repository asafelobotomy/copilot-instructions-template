#!/usr/bin/env bash
# scripts/workspace/check-workspace-drift.sh
# purpose: Detect structural sentinel drift between consumer workspace files
#          and the current template. Reports sections that are missing or
#          outdated compared to the installed template version.
# usage:   bash scripts/workspace/check-workspace-drift.sh [WORKSPACE_DIR]
#          WORKSPACE_DIR defaults to .copilot/workspace relative to CWD.
# output:  Plain-text drift report to stdout.
#          Exit 0 = no drift detected.
#          Exit 1 = one or more structural sections are drifted or missing.
set -euo pipefail

WORKSPACE_DIR="${1:-.copilot/workspace}"

# ── Sentinel registry ──────────────────────────────────────────────────────
# Each entry: "relative-file|section-id|version|human-description"
# section-id and version must match the <!-- template-section: ID VER --> marker
# embedded in template/workspace/<relative-file>.
# Add a new row here whenever a structural section is updated in a release.
REGISTRY=(
    "operations/HEARTBEAT.md|heartbeat-response-contract|v2|Response Contract — three-rule unambiguous form (v5.2.0)"
)

HEARTBEAT_RESPONSE_LINES=(
    '- Always append a History row when the trigger is Session start or Explicit — regardless of check results.'
    '- For all other triggers, append a History row only if a check raised an alert or retrospective output was persisted to SOUL.md / MEMORY.md / USER.md.'
    '- If checks pass and nothing was persisted on a non-explicit trigger, keep Pulse as `HEARTBEAT_OK` and omit the History row.'
)

DRIFT_FOUND=0

for entry in "${REGISTRY[@]}"; do
    IFS='|' read -r rel_file section_id version description <<< "$entry"
    consumer_path="$WORKSPACE_DIR/$rel_file"

    if [[ ! -f "$consumer_path" ]]; then
        echo "MISSING_FILE  $consumer_path  (section: $section_id $version — $description)"
        DRIFT_FOUND=1
        continue
    fi

    sentinel="<!-- template-section: ${section_id} ${version} -->"
    if grep -qF "$sentinel" "$consumer_path"; then
        echo "OK            $consumer_path  [$section_id $version]"
        if [[ "$rel_file" == "operations/HEARTBEAT.md" && "$section_id" == "heartbeat-response-contract" ]]; then
            for required_line in "${HEARTBEAT_RESPONSE_LINES[@]}"; do
                if ! grep -qF -- "$required_line" "$consumer_path"; then
                    echo "DRIFT_CONTENT  $consumer_path  missing response-contract line: $required_line"
                    DRIFT_FOUND=1
                fi
            done
        fi
    else
        echo "DRIFT         $consumer_path  missing sentinel '$section_id $version' — $description"
        DRIFT_FOUND=1
    fi
done

exit "$DRIFT_FOUND"
