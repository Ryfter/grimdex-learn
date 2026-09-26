---
title: "Idempotency: designing tasks safe to run again"
module_id: agentic-automation
capabilities:
  - idempotency-safe-to-rerun
context7_library: /websites/platform_claude_en
context7_queries:
  - How does headless mode re-run an agent task non-interactively?
  - How do I cap a repeated agent loop so it does not run away?
  - What permission prompts apply when an agent task runs unattended?
official_sources:
  - https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2
  - https://code.claude.com/docs/en/hooks
  - https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows
last_checked: 2026-09-20
last_material_update: 2026-09-20
status: current
claim_class: everyday
safety_class: normal
version_stamp: fall-2026-0.1.0
admission:
  course_independent: true
  public_ready: true
  provenance: practice-guidance-with-official-anchors
---

## What it is

Idempotency is the property that running the same operation twice produces the same safe outcome as running it once. It is a general, well-established engineering concept -- not a feature of any one vendor or tool. Most readers have already met it formally: HTTP defines certain request methods as idempotent (RFC 9110 §9.2.2), meaning that repeating a GET or PUT is safe while blindly repeating a POST may not be.

Applied to agentic automation: any task you hand to a loop, a hook, or a schedule should be designed so that a re-run -- whether deliberate, accidental, or caused by an overlapping run -- does no harm.

## When it is useful

Any unattended or repeated agent work:

- A scheduled agent task (e.g. cron or a GitHub Actions `on.schedule` trigger) that may fire again after a partial failure.
- A loop that runs until a condition is met (e.g. "run until tests pass") -- retries are inherent to loops.
- Overlapping runs: two concurrent executions touching the same repository.
- Manual re-runs: someone reruns a `workflow_dispatch` job because the first one "looked stuck".

If a task is idempotent, all of these situations are benign. If it is not, each one is an opportunity for damage.

## Prerequisites

- Basic familiarity with loops, hooks, and schedules as the three trigger types for repeated agent work (see the module's other pages).
- Headless / non-interactive mode: you can only repeat agent tasks that can run without an attended terminal session (e.g. Claude Code's documented `claude -p` programmatic invocation).
- For HTTP terminology: no prerequisites beyond knowing what a request/response is.

## Current syntax

There is no syntax for idempotency itself -- it is a design discipline. The related, documented mechanisms you will combine it with:

- GitHub Actions `concurrency` (with `cancel-in-progress` and concurrency groups) to prevent overlapping runs, and `timeout-minutes` to bound a run that never completes.
- `flock`, the standard Linux utility, for the same purpose on plain cron jobs.
- Claude Code's headless mode iteration cap (`--max-turns`-style) to bound repeated agent turns.
- Claude Code hooks (`PreToolUse`, `PostToolUse`, `Stop`, etc.) that can deny actions via non-zero exit codes -- a guardrail complement, not a substitute, for idempotent design.

## What happens (local and remote)

An idempotent task, re-run:

- Local: the second run detects the desired state already exists and either completes trivially or is a no-op.
- Remote: a second push/PR/issue/comment is either skipped because the artifact already exists or is detected and handled.

A non-idempotent task, re-run, can: apply the same change twice, create duplicate artifacts (branches, PRs, issues, commits), overwrite newer work with stale state, or consume resources (GitHub Actions workflow-run minutes, LLM tokens against real rate limits) with no one watching.

## Practical example

Consider a scheduled agent task: "update dependencies weekly."

- Non-idempotent framing: "upgrade every dependency" -- run twice, it may churn lockfiles, produce conflicting commits, or open duplicate upgrade PRs.
- Idempotent framing: "check for available updates; if none, exit immediately; if some, apply them and open one PR, but first check whether an open upgrade PR already exists and skip if so."

Other examples of idempotent framing for agent tasks:

- "Ensure file X contains Y" (idempotent) vs. "append Y to file X" (not).
- "Create the branch only if it does not exist" vs. "create the branch."
- "Regenerate the report file" vs. "append a new report section every run."

## Explanation guidance

### Essential

- Define idempotency plainly: running it again is safe.
- Anchor it in something learners may already know: HTTP's idempotent methods (RFC 9110 §9.2.2) -- a GET or PUT repeated is safe; a repeated POST may create duplicates. Agent tasks have the same distinction.
- Give the litmus test: "If I ran this twice by accident, would anything break?" If unsure, redesign until the answer is no.
- Note that retries are normal in loops, schedules (which can be delayed or dropped under load on GitHub Actions), and human re-runs -- idempotency is what makes those safe.

### Experienced-user note

- Idempotency is the softest of the safety layers; pair it with hard bounds: `timeout-minutes` / `--max-turns` for runaway loops, `concurrency` (GitHub Actions) or `flock` (cron) for overlap, and a human approval gate (Claude Code's default permission prompts, or GitHub environment protection rules with required reviewers) before trusting an unattended setup.
- Also distinguish the "kill switch" operations: cancelling an active run and disabling its future trigger are separate actions in GitHub Actions; a non-idempotent task that you merely cancel but leave scheduled will fire again.
- Design check: prefer "ensure-state" phrasing ("ensure X exists / is true") over "do-action" phrasing ("add X") in prompts given to scheduled or looped agents.

### Optional deeper context

- Idempotency composes with convergent design: a task that drives state toward a described target ("make it so") is naturally idempotent; a task that performs an action every time ("do the thing") is naturally not.
- HTTP is the formal anchor, but the concept appears across engineering (infrastructure provisioning, database migrations, message processing). It is vendor-neutral by nature; this page applies it to agent automation specifically.
- Cross-tool note: the hooks and scheduling mechanisms cited here are verified for Claude Code, git, and GitHub Actions. Whether other tools (e.g. Cursor, Codex-CLI) offer equivalent hooks/scheduling features is unverified; the idempotency *concept* itself, however, applies to any agent tool you automate.

## Cautions and common failures

- Assuming a schedule means "exactly once": GitHub Actions scheduled runs can be delayed or dropped under platform load, run only on the default branch, and are auto-disabled after 60 days of repository inactivity. A "missed then fired later" run can overlap with a manual run -- idempotency plus `concurrency` is the defense.
- Duplicate side effects: an agent opening an issue, PR, or comment on every run without checking for existing ones will accumulate duplicates.
- Partial failure then retry: a run that fails halfway and is retried can apply the first half's effects twice if the task is not idempotent. Design each step to be safely repeatable.
- Cost of the no-op run: an idempotent task that "checks and exits" still consumes workflow-run minutes and LLM tokens. Idempotency prevents damage, not cost -- watch both.
- Confusing idempotency with immutability: idempotent tasks may still change state; they just converge to the same state regardless of how many times they run.
- Do not rely on guardrails alone: a `Stop`-hook anti-recursion mechanism or a permission prompt prevents certain classes of runaway behavior, but neither makes a destructive task safe to re-run.

## Related capabilities

- Loops, hooks, and schedules as the three trigger types for repeated agent work.
- Headless / non-interactive mode as the prerequisite for any automation.
- Concurrency control for overlapping runs (GitHub Actions `concurrency`; `flock` for cron).
- Bounding unattended runs (`timeout-minutes`, `--max-turns`).
- Kill switch operations: cancelling a run vs. disabling its trigger.

## Official sources

- RFC 9110 §9.2.2 (HTTP idempotent methods): https://www.rfc-editor.org/rfc/rfc9110#section-9.2.2
- Claude Code hooks: https://code.claude.com/docs/en/hooks
- Claude Code headless mode: https://code.claude.com/docs/en/headless
- GitHub Actions events that trigger workflows (schedule, workflow_dispatch): https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows

## Provenance

Idempotency is a general, well-established engineering concept, anchored formally in RFC 9110 §9.2.2. Application of the concept to agent loops/schedules is practice guidance grounded in the module's verified facts about Claude Code headless mode, git/GitHub automation mechanics, and documented caveats of scheduled workflows. Cross-tool comparisons (Cursor, Codex-CLI) are explicitly flagged as unverified. No vendor-specific idempotency features are claimed beyond the documented mechanisms cited above.