#!/bin/bash
# Trinity Pipeline - Shared functions

# ─── State Management ──────────────────────────────────────

find_active_pipeline() {
    local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local state_file="$project_root/.trinity/state.md"
    [ -f "$state_file" ] && echo "$state_file" || echo ""
}

parse_state() {
    local state_file="$1"
    local key="$2"
    grep "^${key}:" "$state_file" 2>/dev/null | sed "s/^${key}:[[:space:]]*//" | tr -d '"'
}

update_state() {
    local state_file="$1"
    local key="$2"
    local value="$3"
    local tmp="${state_file}.tmp.$$"
    sed "s|^${key}:.*|${key}: ${value}|" "$state_file" > "$tmp"
    mv "$tmp" "$state_file"
}

# ─── Phase Completion Detection ────────────────────────────

phase_is_complete() {
    local project_root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local phase="$1"
    local trinity_dir="$project_root/.trinity"

    case "$phase" in
        5)
            # Phase 5 (RLCR): check if humanize RLCR loop completed
            local rlcr_dir="$project_root/.humanize/rlcr"
            if [ -d "$rlcr_dir" ]; then
                # Check for complete/finalize state files
                local complete_file
                complete_file=$(find "$rlcr_dir" -maxdepth 2 -name "complete-state.md" -o -name "finalize-state.md" 2>/dev/null | sort -r | head -1)
                [ -n "$complete_file" ] && return 0

                # Check if any active state.md still exists (RLCR still running)
                local active_state
                active_state=$(find "$rlcr_dir" -maxdepth 2 -name "state.md" 2>/dev/null | head -1)
                [ -n "$active_state" ] && return 1  # Still running
            fi
            # No RLCR dir means it was never started or already cleaned up
            [ -f "$trinity_dir/phase-5-summary.md" ] && return 0
            return 1
            ;;
        *)
            # All other phases: check for summary file
            [ -f "$trinity_dir/phase-${phase}-summary.md" ] && return 0
            return 1
            ;;
    esac
}

should_skip_phase() {
    local phase="$1"
    local skip_phases="$2"
    local lite_mode="$3"

    # Explicit skip
    echo "$skip_phases" | tr ',' '\n' | grep -qx "$phase" && return 0

    # Lite mode skips: Phase 2 (triple review), Phase 6c/6d (QA/security), Phase 9 (retro)
    if [ "$lite_mode" = "true" ]; then
        case "$phase" in
            2|9) return 0 ;;
        esac
    fi

    return 1
}

# ─── Phase Names ───────────────────────────────────────────

phase_name() {
    case "$1" in
        0) echo "Workspace Isolation" ;;
        1) echo "Product Discovery" ;;
        2) echo "Triple Review" ;;
        3) echo "Plan Formalization" ;;
        4) echo "Plan Refinement" ;;
        5) echo "RLCR Execution" ;;
        6) echo "Review + QA + Security" ;;
        7) echo "Verification" ;;
        8) echo "Ship" ;;
        9) echo "Docs + Retro" ;;
    esac
}
