# Trinity Pipeline

> **gstack + Humanize + Superpowers = One-Person Software Factory**

A Claude Code skill that orchestrates three best-in-class AI development systems into a single end-to-end pipeline. From a one-sentence idea to a shipped PR in one command.

## What It Does

```
/full-dev-pipeline I want to build a calendar briefing app

Phase 0  Superpowers   → Isolated git worktree
Phase 1  gstack        → /office-hours product discovery (challenges your assumptions)
Phase 2  gstack        → CEO review → Design review → Engineering review
Phase 3  Humanize      → Strict plan with acceptance criteria (AC-X, AC-X.neg)
Phase 4  Humanize      → Human review + refinement
Phase 5  Humanize      → RLCR loop (Claude implements + Codex reviews, up to 42 rounds)
Phase 6  gstack        → /review + /codex cross-model + /qa browser testing + /cso security
Phase 7  Superpowers   → Evidence-based verification (Iron Law: run it, then claim it)
Phase 8  gstack        → /ship → PR created
Phase 9  gstack        → /document-release + /retro
```

## Why Three Systems?

Each system is best-in-class at different things:

| System | Best At |
|--------|---------|
| **gstack** | Product thinking, design review, browser QA, security audit, shipping |
| **Humanize** | Strict planning (AC criteria), iterative Claude+Codex review loops, knowledge capture |
| **Superpowers** | Engineering discipline, TDD, evidence-based verification, git worktree isolation |

No single system covers the full lifecycle. Trinity combines them so each phase uses the strongest tool available.

## Install (30 seconds)

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [Git](https://git-scm.com/)
- [Bun](https://bun.sh/) v1.0+ (for gstack browser automation)
- [Codex CLI](https://github.com/openai/codex) (for Humanize RLCR loop)

### One-liner

```bash
git clone https://github.com/zhjiang22/trinity-pipeline.git /tmp/trinity-pipeline && /tmp/trinity-pipeline/setup
```

### What setup does

1. Copies `/full-dev-pipeline` skill to `~/.claude/commands/`
2. Installs [gstack](https://github.com/garrytan/gstack) to `~/.claude/skills/gstack/`
3. Installs [humanize](https://github.com/humania-org/humanize) plugin via marketplace
4. Installs [superpowers](https://github.com/superpowers-marketplace/superpowers) plugin via marketplace
5. Checks for codex CLI

Everything installs at user scope — works across all your projects.

## Usage

```bash
# Full pipeline
/full-dev-pipeline I want to build a real-time collaborative whiteboard

# Lite mode (skip triple review + QA/security + retro)
/full-dev-pipeline --lite Add dark mode to the settings page

# Resume from a specific phase
/full-dev-pipeline --resume 5

# Skip specific phases
/full-dev-pipeline --skip-phase 0,2

# Enable deploy (default is PR only)
/full-dev-pipeline --deploy
```

## Pipeline Phases

### Phase 0: Workspace Isolation (Superpowers)
Creates an isolated git worktree so your main branch stays clean.

### Phase 1: Product Discovery (gstack `/office-hours`)
Six forcing questions that reframe your product. Challenges premises, extracts capabilities you didn't realize you were describing. Outputs a design document.

### Phase 2: Triple Review (gstack)
Three sequential reviews on the design doc:
- **CEO Review** (`/plan-ceo-review`) — Rethinks scope, finds the 10-star product
- **Design Review** (`/plan-design-review`) — Rates dimensions 0-10, detects AI slop
- **Engineering Review** (`/plan-eng-review`) — Architecture diagrams, edge cases, test matrix

### Phase 3: Plan Formalization (Humanize `gen-plan`)
Converts the free-form design into Humanize's strict format:
- Acceptance Criteria with positive AND negative tests (AC-1, AC-1.neg)
- Task breakdown with `coding` / `analyze` tags
- Claude-Codex convergence status

### Phase 4: Plan Refinement (Humanize `refine-plan`)
Human reviews the plan. Can annotate with `CMT: ... ENDCMT` markers or give verbal feedback.

### Phase 5: RLCR Execution (Humanize `start-rlcr-loop`)
The core engine:
- Claude implements `coding` tasks
- Codex independently reviews each round with `[P0]-[P9]` severity markers
- Issues feed back for resolution
- BitLesson captures knowledge each round
- Loop continues until Codex says "COMPLETE"

### Phase 6: Review + QA + Security (gstack)
Four quality gates:
- `/review` — Staff-engineer code review
- `/codex` — Cross-model second opinion (OpenAI)
- `/qa` — Real Playwright browser testing (if project has UI)
- `/cso` — OWASP Top 10 + STRIDE security audit

### Phase 7: Verification (Superpowers)
Evidence-based verification. The Iron Law: run the command, read the output, THEN claim the result. No "should pass" allowed.

### Phase 8: Ship (gstack `/ship`)
Syncs main, runs tests, audits coverage, pushes, creates PR. Deploy is opt-in with `--deploy`.

### Phase 9: Docs + Retro (gstack)
- `/document-release` — Updates all project docs to match changes
- `/retro` — Engineering retrospective with shipping metrics

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Trinity Pipeline                          │
│                  /full-dev-pipeline                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   gstack     │  │  Humanize    │  │  Superpowers     │  │
│  │              │  │              │  │                  │  │
│  │ /office-hours│  │ gen-plan     │  │ git-worktrees    │  │
│  │ /plan-*      │  │ refine-plan  │  │ brainstorming    │  │
│  │ /review      │  │ start-rlcr   │  │ verification     │  │
│  │ /codex       │  │ BitLesson    │  │ TDD              │  │
│  │ /qa          │  │              │  │ finishing-branch  │  │
│  │ /cso         │  │              │  │                  │  │
│  │ /ship        │  │              │  │                  │  │
│  │ /retro       │  │              │  │                  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Customization

The skill file is at `~/.claude/commands/full-dev-pipeline.md`. It's plain Markdown — edit it to:

- Change default phases
- Add/remove quality gates
- Adjust the plan format
- Customize announcements

## Credits

Trinity Pipeline combines three open-source projects:

- [gstack](https://github.com/garrytan/gstack) by Garry Tan — Product team simulation
- [humanize](https://github.com/humania-org/humanize) by humania-org — RLCR iterative development
- [superpowers](https://github.com/superpowers-marketplace/superpowers) — Engineering discipline framework

## License

MIT
