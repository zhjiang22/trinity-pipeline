---
description: "Trinity Pipeline: gstack (产品构思+设计+QA+安全+发布) × Humanize (严格计划+RLCR循环审查) × Superpowers (工程纪律+TDD+验证). 从一句话想法到生产部署的完整闭环. /full-dev-pipeline [idea]"
---

# Trinity Development Pipeline

> **gstack (产品团队) × Humanize (迭代引擎) × Superpowers (工程纪律) = 一人软件工厂**

You are a pipeline orchestrator combining three systems. Each phase selects the **best tool from the best system** for that job. Follow phases strictly in order. Each phase has entry/exit gates.

## Pipeline Overview

```
Phase 0: Workspace       ← Superpowers (git worktree 隔离)
Phase 1: Product Discovery ← gstack (/office-hours 产品构思)
Phase 2: Triple Review    ← gstack (/plan-ceo-review → /plan-design-review → /plan-eng-review)
Phase 3: Plan Formalize   ← Humanize (gen-plan 严格AC格式化)
Phase 4: Plan Refinement  ← Humanize (refine-plan 人工精炼)
Phase 5: RLCR Execution   ← Humanize (start-rlcr-loop 迭代开发)
Phase 6: Review + QA      ← gstack (/review + /codex 双模型审查 + /qa 浏览器测试 + /cso 安全审计)
Phase 7: Verification     ← Superpowers (verification-before-completion 证据验证)
Phase 8: Ship + Deploy    ← gstack (/ship → /land-and-deploy → /canary)
Phase 9: Docs + Retro     ← gstack (/document-release + /retro)
```

## Invocation

```
/full-dev-pipeline [idea or requirement]
/full-dev-pipeline --resume <phase>         # Resume from specific phase
/full-dev-pipeline --skip-phase 0,1         # Skip phases (comma-separated)
/full-dev-pipeline --lite                   # Skip Phase 2 triple review + Phase 6 QA/security + Phase 9 retro
/full-dev-pipeline --deploy                 # Enable Phase 8b/8c (deploy + canary), default is OFF
```

---

## Phase 0: Workspace Isolation

**Source:** Superpowers
**Gate IN:** User provided an idea.
**Gate OUT:** Isolated git worktree active.

**Action:** Invoke `superpowers:using-git-worktrees`.

- Branch: `feature/<short-kebab-case-name>`
- Skip if already on a feature branch or user says no worktree needed.

**Announce:** "Phase 0/9: 创建隔离工作区..."

---

## Phase 1: Product Discovery

**Source:** gstack
**Gate IN:** Workspace ready.
**Gate OUT:** Design doc saved to `docs/plans/YYYY-MM-DD-<topic>-design.md`.

**Action:** Invoke `/office-hours` with the user's idea.

This is gstack's strongest skill — it doesn't just gather requirements, it **challenges your framing**:
- Six forcing questions that reframe the product before writing code
- Pushes back on premises, challenges assumptions
- Extracts capabilities you didn't realize you were describing
- Generates 2-3 implementation approaches with effort estimates
- Outputs a design doc that feeds into all downstream phases

**CRITICAL gate:** Ask the user:
> "设计文档已保存。确认进入 Phase 2 (三重审查) 吗？输入 `skip` 可跳过审查直接进入计划生成。"

**Announce:** "Phase 1/9: 产品构思 (gstack /office-hours)..."

---

## Phase 2: Triple Review

**Source:** gstack
**Gate IN:** Design doc confirmed.
**Gate OUT:** Design doc reviewed and refined from CEO / Design / Engineering perspectives.

Run three reviews **sequentially** on the design doc. Each review reads the output of the previous one:

### 2a. CEO Review
**Action:** Invoke `/plan-ceo-review`
- Rethinks the problem from first principles
- Four modes: Expansion, Selective Expansion, Hold Scope, Reduction
- Finds the "10-star product" hiding inside the request

### 2b. Design Review
**Action:** Invoke `/plan-design-review`
- Rates each design dimension 0-10
- Explains what a 10 looks like for each
- Detects "AI slop" — generic, uninspired design choices
- Interactive: one question per design choice

### 2c. Engineering Review
**Action:** Invoke `/plan-eng-review`
- ASCII diagrams for data flow, state machines, error paths
- Test matrix, failure modes, security concerns
- Forces hidden architectural assumptions into the open

After all three reviews, ask:
> "三重审查完成。确认进入 Phase 3 (计划格式化) 吗？"

**Announce:** "Phase 2/9: 三重审查 (CEO → 设计 → 工程)..."

---

## Phase 3: Plan Formalization

**Source:** Humanize
**Gate IN:** Design doc reviewed (or Phase 2 skipped).
**Gate OUT:** Humanize-format plan with AC criteria, task tags, convergence status.

**Action:** Invoke `/humanize:gen-plan`:

```
/humanize:gen-plan --input docs/plans/YYYY-MM-DD-<topic>-design.md --output docs/plans/YYYY-MM-DD-<topic>-plan.md
```

Transforms the free-form design into Humanize's strict format:
- Acceptance Criteria (AC-X, AC-X.neg — both positive AND negative tests)
- Path Boundaries (upper bound / lower bound)
- Task Breakdown with `coding` / `analyze` tags
- Claude-Codex Deliberation + Convergence Status
- Original design preserved at bottom

**Announce:** "Phase 3/9: 生成结构化执行计划 (Humanize AC 格式)..."

---

## Phase 4: Plan Refinement

**Source:** Humanize
**Gate IN:** Plan file in Humanize format.
**Gate OUT:** User confirms, convergence_status = fully_converged.

**Action:** Present plan to user:

> "计划已生成。你可以：
> 1. 直接确认 → 进入 RLCR 执行
> 2. 用 `CMT: ... ENDCMT` 标注修改意见 → 执行 refine-plan
> 3. 口头反馈 → 我来调整"

If feedback provided:
```
/humanize:refine-plan --input docs/plans/YYYY-MM-DD-<topic>-plan.md
```

Repeat until user confirms.

**Announce:** "Phase 4/9: 计划审阅与精炼..."

---

## Phase 5: RLCR Iterative Execution

**Source:** Humanize
**Gate IN:** Plan confirmed, fully_converged.
**Gate OUT:** Codex says "COMPLETE" or all AC criteria met.

**Action:**

```
/humanize:start-rlcr-loop docs/plans/YYYY-MM-DD-<topic>-plan.md
```

The core engine:
1. Claude implements `coding` tasks
2. Codex performs `analyze` tasks
3. Codex reviews each round with `[P0]-[P9]` severity markers
4. Issues feed back for resolution
5. BitLesson captures knowledge each round
6. Loop continues until COMPLETE or max 42 rounds

**DO NOT interfere.** The loop has its own hooks, validators, stop gates.

**Announce:** "Phase 5/9: RLCR 迭代执行 (Claude 写 + Codex 审)..."

---

## Phase 6: Review + QA + Security

**Source:** gstack
**Gate IN:** RLCR loop completed.
**Gate OUT:** All review/QA/security issues resolved.

Run four checks. Fix issues found by each before proceeding to the next:

### 6a. Code Review
**Action:** Invoke `/review`
- Staff-engineer level review
- Auto-fixes obvious issues
- Flags completeness gaps

### 6b. Cross-Model Second Opinion
**Action:** Invoke `/codex`
- Independent OpenAI Codex review (different AI, different blind spots)
- Cross-model analysis if both `/review` and `/codex` have run

### 6c. Browser QA (if project has UI)
**Action:** Invoke `/qa` on staging/dev URL
- Opens real Playwright browser
- Clicks through flows, finds bugs
- Auto-generates regression tests for every fix
- **Skip if:** project is a library/CLI with no web UI

### 6d. Security Audit
**Action:** Invoke `/cso`
- OWASP Top 10 + STRIDE threat model
- 17 false positive exclusions, 8/10+ confidence gate
- Each finding includes a concrete exploit scenario
- **Skip if:** `--lite` flag or user says unnecessary

After all checks pass, proceed.

**Announce:** "Phase 6/9: 四重质量关卡 (代码审查 → 跨模型验证 → 浏览器QA → 安全审计)..."

---

## Phase 7: Verification

**Source:** Superpowers
**Gate IN:** All Phase 6 checks passed.
**Gate OUT:** All verification evidence collected. No false claims.

**Action:** Invoke `superpowers:verification-before-completion`. The Iron Law:

1. **IDENTIFY** what commands prove completion
2. **RUN** each verification fresh
3. **READ** full output, exit codes, failure counts
4. **VERIFY** output confirms claim
5. **REPORT** with evidence:

```
## Verification Report
- Tests: X/X pass (command: ..., exit 0)
- Build: success (command: ..., exit 0)
- Lint: 0 errors
- AC Checklist:
  - [x] AC-1: verified by test_xxx
  - [x] AC-1.neg: verified by test_xxx_invalid
  - [x] AC-2: verified by ...
- Security: /cso passed (N findings, all resolved)
- QA: /qa passed (N bugs found, all fixed with regression tests)
```

**Announce:** "Phase 7/9: 证据验证 (Iron Law: 先跑命令，再下结论)..."

---

## Phase 8: Ship + Deploy

**Source:** gstack
**Gate IN:** All verifications pass.
**Gate OUT:** PR created/merged, deployed, production verified.

### 8a. Ship
**Action:** Invoke `/ship`
- Syncs main, runs tests, audits coverage
- Pushes branch, opens PR
- Bootstraps test framework if missing

### 8b. Land and Deploy (only with `--deploy` flag)
**Default: SKIP.** Deploy is opt-in, not opt-out.

If `--deploy` flag is set, invoke `/land-and-deploy`:
- Merges PR, waits for CI
- Deploys to production
- Verifies production health

Then invoke `/canary` for post-deploy monitoring.

**Default behavior (no flag):** Stop after `/ship`, present PR URL.

**Announce:** "Phase 8/9: 发布部署 (ship → deploy → canary)..."

---

## Phase 9: Docs + Retro

**Source:** gstack
**Gate IN:** Shipped (or PR created).
**Gate OUT:** Docs updated, retro recorded.

### 9a. Documentation
**Action:** Invoke `/document-release`
- Updates all project docs to match shipped changes
- Catches stale READMEs, ARCHITECTURE, CONTRIBUTING

### 9b. Retrospective
**Action:** Invoke `/retro`
- Per-feature breakdown
- Test health trends
- Shipping metrics
- Lessons learned (complements Humanize's BitLesson)

**Announce:** "Phase 9/9: 文档更新 + 复盘..."

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Phase failure | Stop, report which phase/sub-step failed. Ask retry or abort. |
| RLCR timeout (42 rounds) | Report progress, ask user to continue with `--max N` or stop. |
| Codex unavailable | Fall back to `superpowers:requesting-code-review` for Phase 5; skip `/codex` in Phase 6. |
| No web UI for QA | Skip Phase 6c automatically. |
| Test failures in Phase 7 | Fix → re-verify. Do NOT proceed to Phase 8. |
| Deploy failure | Invoke `/investigate` for root-cause debugging. |

## Phase Resume

```
/full-dev-pipeline --resume 5    # Resume from RLCR execution
```

On resume:
- Check existing artifacts: design doc, plan file, RLCR state, PR status
- Report current state
- Continue from specified phase

## Logging

After pipeline completion (or abort), append to project experiment log:

```markdown
## [YYYY-MM-DD] Trinity Pipeline: <feature-name>
- **Phases completed:** 0-9 (or partial)
- **Product reviews:** CEO/Design/Eng scores
- **RLCR rounds:** N
- **Codex issues (RLCR):** N (P0: X, P1: Y, ...)
- **Code review issues:** N auto-fixed, N manual
- **Cross-model findings:** N overlapping, N unique
- **QA bugs:** N found, N fixed with regression tests
- **Security findings:** N (severity breakdown)
- **BitLessons captured:** N
- **Final verification:** PASS/FAIL
- **Test coverage:** X%
- **Outcome:** PR #N / merged / deployed / kept
```
