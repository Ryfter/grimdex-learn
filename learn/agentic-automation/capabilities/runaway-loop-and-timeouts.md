---
title: Runaway-loop risk and timeouts
module_id: agentic-automation
capabilities:
  - runaway-loop-and-timeouts
context7_library: /websites/github_en_actions
context7_queries:
  - How do I limit how long a GitHub Actions job can run with timeout-minutes?
  - What is the default job timeout in GitHub Actions?
  - How do I cap the number of turns in Claude Code headless mode?
official_sources:
  - https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
  - https://code.claude.com/docs/en/headless
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

An unattended agentic loop — a scheduled job, a hook that re-triggers work, or a headless run nobody is watching — can keep going far past the point where it is doing anything useful. If the loop never naturally completes (a test never passes, an agent keeps "fixing" something it broke, a cron job overlaps with itself), it silently consumes resources until something stops it.

A runaway loop needs an explicit bound. There are two concrete, documented mechanisms covered in this module:

- **GitHub Actions jobs have a `timeout-minutes` setting**, a real, documented workflow syntax option that caps how long a job may run. Its documented default is around 360 minutes — six hours of possibly useless, billable workflow-run minutes if you never set it.
- **Claude Code's headless mode (`claude -p`) has an iteration cap** (`--max-turns`-style), a real, documented way to limit how many turns an unattended agent run can take before it is forced to stop.

Both exist precisely because nobody is watching the run live. An attended terminal session ends when you close it or hit Ctrl-C; an unattended loop has to be bounded in advance.

## When it is useful

- Any scheduled GitHub Actions workflow (cron-style `on.schedule`) that invokes an agent or a build that could hang.
- Any loop-style agent task ("run until tests pass") where the condition may never be met.
- Hook-driven setups where one agent run can trigger another, risking an infinite feedback chain.
- Any headless Claude Code run left to work unattended, especially one with permission prompts skipped.

## Prerequisites

- Understanding of the three trigger types (loop, hook, schedule) and of headless mode as the prerequisite for all of them — you cannot bound an agent that never runs unattended in the first place.
- For GitHub Actions: a workflow file you control.
- For Claude Code: familiarity with programmatic invocation (`claude -p`).
- Awareness that unattended runs consume real resources: GitHub Actions bills workflow-run minutes, and LLM-based agents consume real tokens against real rate limits.

## Current syntax

GitHub Actions, per job:

```yaml
jobs:
  agent-task:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - run: ./run-agent-task.sh
```

Claude Code headless mode uses an iteration cap flag of the `--max-turns` style to bound how many turns the agent may take in a single non-interactive run.

## What happens (local and remote)

- **GitHub Actions:** when a job exceeds its `timeout-minutes` limit, the job is terminated and marked as failed. If you do not set it, the documented default of roughly 360 minutes applies. Minutes consumed before the timeout still count against billing.
- **Claude Code headless:** when the turn cap is reached, the run stops rather than continuing indefinitely. The cap bounds both the damage of a loop that never completes and the token spend of a run nobody is watching.

In both cases the bound fires *unconditionally on time/turns*, not on whether the work was actually finished — so a too-tight cap will cut off legitimate work, and a too-loose cap will allow a long runaway. Choosing the value is a judgment call, not a formality.

## Practical example

A scheduled workflow that runs an agent nightly, bounded on two axes:

```yaml
on:
  schedule:
    - cron: "0 4 * * *"
  workflow_dispatch: {}

concurrency:
  group: nightly-agent
  cancel-in-progress: true

jobs:
  nightly-agent:
    runs-on: ubuntu-latest
    timeout-minutes: 45
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Run bounded agent task
        run: claude -p "triage failing CI tests and open a draft PR" --max-turns 40
```

Here `timeout-minutes: 45` bounds wall-clock time at the workflow level, and the agent's own turn cap bounds it at the agent level. The `concurrency` group prevents overlapping nightly runs from piling up — a related but separate runaway risk.

## Explanation guidance

### Essential

- An unattended loop has no human pressing Ctrl-C, so the bound must be set *before* the run starts.
- `timeout-minutes` is set per job in GitHub Actions; the documented default is around 360 minutes. Setting an explicit, much smaller value is the normal practice.
- Claude Code's headless mode takes an iteration/turn cap so a single unattended run cannot turn forever.
- Timeouts do not make the run "succeed" — they kill it. Treat a timeout hit as a signal that the task or its loop condition needs redesigning.
- The beginner-level framing: a timeout is the seatbelt for the "repeat until done" agent loop, because "done" may never come.

### Experienced-user note

- Combine bounds in layers: a tight `timeout-minutes` on the job, a turn cap on the agent, plus a `concurrency` group with `cancel-in-progress` to stop overlapping runs from multiplying the problem. Each addresses a different failure mode (hang, endless loop, pile-up).
- Pair the timeout with idempotent task design (the well-established engineering concept, formally anchored by HTTP's idempotent methods, RFC 9110 §9.2.2). If a timed-out run is partially complete, the next run should be able to redo it safely rather than compound partial work.
- Remember the kill-switch distinction: a timeout stops one run, but the *schedule* that triggers future runs keeps firing. Cancelling an active run and disabling its future trigger are two separate operations in GitHub Actions — if you diagnose a runaway, do both.

### Optional deeper context

- The `Stop` event and `stop_hook_active` field in Claude Code's hooks system exist for a related reason: to prevent a hook from re-triggering more agent work in an infinite feedback loop. Timeouts bound a single run; that mechanism bounds a chain of runs.
- Scheduled GitHub Actions runs can be delayed or dropped under platform load, so a timeout's clock may start later than your cron time suggests — plan the cap around the work, not around the cron expression.

## Cautions and common failures

- **Assuming the default is fine.** Roughly 360 minutes of billable workflow-run minutes is a real cost for a hung job, and it repeats every time the trigger fires.
- **Setting the cap too tight.** A timeout that kills legitimate long runs teaches you nothing except that the cap was wrong; size it to the expected duration plus margin.
- **Timeout ≠ fix.** A run that repeatedly times out indicates the loop condition, task decomposition, or permissions are wrong — the timeout only limits the blast radius.
- **Only cancelling the visible run.** The scheduled trigger remains active unless separately disabled; the runaway can recur on the next cron tick.
- **Cross-tool assumptions.** This page's timeout and turn-cap mechanisms are verified for GitHub Actions and Claude Code specifically. Whether Cursor or Codex-CLI offer equivalent named iteration caps or timeout settings is **unverified** in this module's research — do not assume parity; check each tool's own documentation.

## Related capabilities

- scheduling-cron-and-github-actions
- concurrency-and-overlap-control
- unattended-run-approval-gates
- kill-switch-cancel-vs-disable
- idempotency-for-repeated-tasks

## Official sources

- GitHub Actions workflow syntax (`timeout-minutes`): https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- GitHub Actions billing of workflow-run minutes: https://docs.github.com/en/billing/managing-billing-for-github-actions
- Claude Code headless mode: https://code.claude.com/docs/en/headless
- Claude Code hooks (`Stop` / `stop_hook_active`): https://code.claude.com/docs/en/hooks

## Provenance

Grounded in this session's research on GitHub Actions' documented workflow syntax (`timeout-minutes`, documented default around 360 minutes), documented billing for workflow-run minutes, documented concurrency and kill-switch semantics, and Claude Code's documented headless mode and iteration cap. The `Stop`/`stop_hook_active` anti-feedback-loop mechanism is documented at code.claude.com. Idempotency is anchored as a general engineering concept via RFC 9110 §9.2.2. Cursor and Codex-CLI parity on these features is explicitly unverified and flagged as such throughout.