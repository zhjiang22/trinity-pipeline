---
description: "Trinity Pipeline: gstack × Humanize × Superpowers. Hook-driven 10-phase pipeline. /full-dev-pipeline [idea]"
---

# Trinity Development Pipeline — Kickoff

> **gstack (产品团队) × Humanize (迭代引擎) × Superpowers (工程纪律)**
>
> **机制：Stop Hook 驱动的阶段自动推进，状态持久化在 `.trinity/state.md`**

## What You Do

Initialize the pipeline state, then start Phase 0. When each phase completes and you stop, the **Trinity Stop Hook** automatically advances to the next phase and injects the prompt. You do NOT need to manually track phases.

## Pipeline Phases

```
Phase 0: Workspace       ← Superpowers (git worktree)
Phase 1: Product Discovery ← gstack (/office-hours)
Phase 2: Triple Review    ← gstack (/plan-ceo-review → /plan-design-review → /plan-eng-review)
Phase 3: Plan Formalize   ← Humanize (gen-plan)
Phase 4: Plan Refinement  ← Humanize (refine-plan)
Phase 5: RLCR Execution   ← Humanize (start-rlcr-loop)
Phase 6: Review + QA      ← gstack (/review + /codex + /qa + /cso)
Phase 7: Verification     ← Superpowers (verification-before-completion)
Phase 8: Ship             ← gstack (/ship)
Phase 9: Docs + Retro     ← gstack (/document-release + /retro)
```

## Invocation Parsing

Parse the user's input for flags:
- `--resume N` → set current_phase to N, skip initialization
- `--skip-phase 0,2,9` → record in skip_phases
- `--lite` → set lite_mode: true (skips Phase 2, QA/security in Phase 6, Phase 9)
- `--deploy` → set deploy_mode: true (enables deploy in Phase 8)

Everything after flags is the **topic** (idea/requirement).

## Initialization

**Step 1:** Create the state directory and file:

```bash
mkdir -p .trinity
```

Write `.trinity/state.md`:
```yaml
---
active: true
current_phase: 0
max_phase: 9
topic: "<user's idea, quoted>"
design_doc: "docs/plans/<YYYY-MM-DD>-<kebab-topic>-design.md"
plan_file: "docs/plans/<YYYY-MM-DD>-<kebab-topic>-plan.md"
skip_phases: "<comma-separated phase numbers, or empty>"
lite_mode: <true|false>
deploy_mode: <false by default>
start_time: "<ISO-8601 timestamp>"
---
```

**Step 2:** Announce:

> "Trinity Pipeline 已初始化。状态文件：`.trinity/state.md`
> 主题：<topic>
> 模式：<normal|lite> | 部署：<on|off>
> 开始 Phase 0..."

**Step 3:** Execute Phase 0 — invoke `superpowers:using-git-worktrees`.

- Branch: `feature/<kebab-topic>`
- If already on feature branch or `--skip-phase 0`, create a skip marker

**Step 4:** When Phase 0 is done, write `.trinity/phase-0-summary.md`:
```
Branch: feature/<name>
Worktree: <path or "skipped">
```

Then stop. The **Trinity Stop Hook** will automatically:
1. Detect phase-0-summary.md exists
2. Advance current_phase to 1 (or next non-skipped phase)
3. Inject the Phase 1 prompt
4. Block your exit so you continue working

## Phase Completion Contract

**Every phase MUST end by writing `.trinity/phase-N-summary.md`.**

This is how the Stop Hook knows a phase is complete. Without the summary file, the hook will not advance and will allow you to stop (preventing infinite loops).

Format: free-form markdown, but include key artifacts (file paths, counts, PR URLs, etc.)

## Phase 5 Special Handling

Phase 5 (RLCR) is managed by Humanize's own hooks. During RLCR:
- Trinity's Stop Hook detects active `.humanize/rlcr/*/state.md` and **defers**
- Humanize's hook manages the round-by-round loop
- When RLCR completes (Humanize writes `complete-state.md`), Trinity's hook resumes
- You then write `.trinity/phase-5-summary.md` and the pipeline advances

## Resume (--resume N)

If resuming from a specific phase:
1. Read existing `.trinity/state.md`
2. Set `current_phase` to N
3. Load context from existing phase summaries (read phase-0 through phase-(N-1))
4. Start executing Phase N directly

## Cancel

To cancel the pipeline:
```bash
# In the project directory:
echo "cancelled" > .trinity/state.md
# Or simply delete .trinity/
```

## Error Handling

- Phase failure → stop, write error to `.trinity/phase-N-error.md` (NOT summary)
- The hook sees no summary → allows stop (no infinite loop)
- User can fix and resume with `--resume N`
