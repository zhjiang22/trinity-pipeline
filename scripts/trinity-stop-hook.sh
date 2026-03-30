#!/bin/bash
#
# Trinity Pipeline - Stop Hook
#
# Intercepts Claude's exit, checks pipeline state, advances to next phase.
# Pattern follows Humanize's RLCR stop-hook mechanism.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "$SCRIPT_DIR/trinity-common.sh"

# ─── Find Active Pipeline ──────────────────────────────────

STATE_FILE=$(find_active_pipeline)
[ -z "$STATE_FILE" ] && exit 0  # No active pipeline → allow stop

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TRINITY_DIR="$PROJECT_ROOT/.trinity"

# ─── Parse State ───────────────────────────────────────────

CURRENT_PHASE=$(parse_state "$STATE_FILE" "current_phase")
MAX_PHASE=$(parse_state "$STATE_FILE" "max_phase")
ACTIVE=$(parse_state "$STATE_FILE" "active")
TOPIC=$(parse_state "$STATE_FILE" "topic")
DESIGN_DOC=$(parse_state "$STATE_FILE" "design_doc")
PLAN_FILE=$(parse_state "$STATE_FILE" "plan_file")
SKIP_PHASES=$(parse_state "$STATE_FILE" "skip_phases")
LITE_MODE=$(parse_state "$STATE_FILE" "lite_mode")
DEPLOY_MODE=$(parse_state "$STATE_FILE" "deploy_mode")

[ "$ACTIVE" != "true" ] && exit 0  # Pipeline not active → allow stop

# ─── Check Current Phase Completion ────────────────────────

if ! phase_is_complete "$CURRENT_PHASE"; then
    # Phase 5 special: if RLCR is running, defer to Humanize's hook
    if [ "$CURRENT_PHASE" = "5" ]; then
        local_rlcr=$(find "$PROJECT_ROOT/.humanize/rlcr" -maxdepth 2 -name "state.md" 2>/dev/null | head -1)
        if [ -n "$local_rlcr" ]; then
            exit 0  # Let Humanize's hook handle RLCR
        fi
    fi
    exit 0  # Phase not done, allow stop (don't trap user)
fi

# ─── Advance to Next Phase ─────────────────────────────────

NEXT_PHASE=$((CURRENT_PHASE + 1))

# Skip phases as configured
while [ "$NEXT_PHASE" -le "$MAX_PHASE" ] && should_skip_phase "$NEXT_PHASE" "$SKIP_PHASES" "$LITE_MODE"; do
    # Create skip marker
    echo "Skipped by configuration" > "$TRINITY_DIR/phase-${NEXT_PHASE}-summary.md"
    NEXT_PHASE=$((NEXT_PHASE + 1))
done

# Pipeline complete
if [ "$NEXT_PHASE" -gt "$MAX_PHASE" ]; then
    update_state "$STATE_FILE" "active" "false"
    update_state "$STATE_FILE" "current_phase" "complete"
    mv "$STATE_FILE" "$TRINITY_DIR/complete-state.md"
    exit 0  # Allow stop — pipeline done
fi

# Update state file
update_state "$STATE_FILE" "current_phase" "$NEXT_PHASE"

# ─── Generate Next Phase Prompt ────────────────────────────

PHASE_LABEL="Phase ${NEXT_PHASE}/9: $(phase_name "$NEXT_PHASE")"
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

generate_prompt() {
    local phase="$1"
    case "$phase" in
        0)
cat << 'PROMPT'
## Trinity Pipeline — Phase 0/9: Workspace Isolation

Use `superpowers:using-git-worktrees` to create an isolated workspace.
Branch naming: `feature/<short-kebab-case-name>` based on the topic.

If already on a feature branch, skip worktree creation.

**When done**, write a brief summary to `.trinity/phase-0-summary.md` (branch name, worktree path).
PROMPT
            ;;
        1)
cat << PROMPT
## Trinity Pipeline — Phase 1/9: Product Discovery

Invoke the \`/office-hours\` skill from gstack with this topic: **${TOPIC}**

Follow office-hours exactly:
- Six forcing questions to reframe the product
- Challenge premises and assumptions
- Generate 2-3 implementation approaches
- Save design doc to \`${DESIGN_DOC}\`

**CRITICAL:** Ask the user to confirm the design before proceeding. Only after confirmation, write a summary to \`.trinity/phase-1-summary.md\` with the design doc path.
PROMPT
            ;;
        2)
cat << PROMPT
## Trinity Pipeline — Phase 2/9: Triple Review

Run three gstack reviews sequentially on \`${DESIGN_DOC}\`:

1. \`/plan-ceo-review\` — Rethink scope, find the 10-star product
2. \`/plan-design-review\` — Rate dimensions 0-10, detect AI slop
3. \`/plan-eng-review\` — Architecture diagrams, test matrix, edge cases

After all three, ask user to confirm. Then write summary to \`.trinity/phase-2-summary.md\`.
PROMPT
            ;;
        3)
cat << PROMPT
## Trinity Pipeline — Phase 3/9: Plan Formalization

Run:
\`\`\`
/humanize:gen-plan --input ${DESIGN_DOC} --output ${PLAN_FILE}
\`\`\`

This converts the design doc into Humanize's strict AC format (acceptance criteria, task tags, convergence status).

**When done**, write summary to \`.trinity/phase-3-summary.md\` with the plan file path.
PROMPT
            ;;
        4)
cat << PROMPT
## Trinity Pipeline — Phase 4/9: Plan Refinement

Present the plan at \`${PLAN_FILE}\` to the user. Offer three options:
1. Confirm as-is → proceed
2. Annotate with CMT:...ENDCMT → run \`/humanize:refine-plan --input ${PLAN_FILE}\`
3. Verbal feedback → adjust directly

Repeat refinement until user confirms. Then write summary to \`.trinity/phase-4-summary.md\`.
PROMPT
            ;;
        5)
cat << PROMPT
## Trinity Pipeline — Phase 5/9: RLCR Iterative Execution

Run:
\`\`\`
/humanize:start-rlcr-loop ${PLAN_FILE}
\`\`\`

This starts the Claude+Codex iterative loop. DO NOT interfere — Humanize's own hooks manage the rounds.

When RLCR completes (Codex says COMPLETE), write summary to \`.trinity/phase-5-summary.md\` with rounds completed and issues resolved.
PROMPT
            ;;
        6)
            local qa_section=""
            local cso_section=""
            if [ "$LITE_MODE" != "true" ]; then
                qa_section="
3. **Browser QA** — \`/qa\` on staging URL (skip if no web UI)
4. **Security Audit** — \`/cso\` OWASP Top 10 + STRIDE"
            fi
cat << PROMPT
## Trinity Pipeline — Phase 6/9: Review + QA + Security

Run these quality gates sequentially, fixing issues from each before the next:

1. **Code Review** — \`/review\` (staff-engineer level, auto-fixes obvious issues)
2. **Cross-Model** — \`/codex\` (independent OpenAI second opinion)${qa_section}

Fix all issues found. Then write summary to \`.trinity/phase-6-summary.md\` with counts of issues found/fixed.
PROMPT
            ;;
        7)
cat << PROMPT
## Trinity Pipeline — Phase 7/9: Verification

Invoke \`superpowers:verification-before-completion\`.

The Iron Law: run the command, read the output, THEN claim the result.

Verify:
- Test suite: full run, 0 failures
- Build: exit 0
- Lint: 0 errors
- AC checklist: every AC-X from \`${PLAN_FILE}\` checked

Write verification report to \`.trinity/phase-7-summary.md\` with evidence for each claim.
PROMPT
            ;;
        8)
            local deploy_section=""
            if [ "$DEPLOY_MODE" = "true" ]; then
                deploy_section="

Then run \`/land-and-deploy\` to merge, deploy, and verify production.
Then run \`/canary\` for post-deploy monitoring."
            fi
cat << PROMPT
## Trinity Pipeline — Phase 8/9: Ship

Run \`/ship\` to sync main, run tests, audit coverage, push, create PR.${deploy_section}

Default: stop after PR creation. Write summary to \`.trinity/phase-8-summary.md\` with PR URL.
PROMPT
            ;;
        9)
cat << PROMPT
## Trinity Pipeline — Phase 9/9: Docs + Retro

1. Run \`/document-release\` to update all project docs
2. Run \`/retro\` for engineering retrospective

Write summary to \`.trinity/phase-9-summary.md\`.

Then append a final pipeline log entry:
\`\`\`
## [$(date +%Y-%m-%d)] Trinity Pipeline: ${TOPIC}
- Phases completed: 0-9
- RLCR rounds: (from phase-5-summary)
- Issues found/fixed: (from phase-6-summary)
- Verification: (from phase-7-summary)
- Outcome: (from phase-8-summary)
\`\`\`
PROMPT
            ;;
    esac
}

PROMPT_CONTENT=$(generate_prompt "$NEXT_PHASE")

# ─── Block Exit and Inject Next Phase ──────────────────────

jq -n \
    --arg reason "$PROMPT_CONTENT" \
    --arg msg "Trinity Pipeline: $PHASE_LABEL" \
    '{
        "decision": "block",
        "reason": $reason,
        "systemMessage": $msg
    }'

exit 0
