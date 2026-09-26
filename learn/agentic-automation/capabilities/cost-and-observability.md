---
title: Cost and observability of unattended runs
module_id: agentic-automation
capabilities:
  - cost-and-observability
context7_library: /websites/github_en_actions
context7_queries:
  - "How does GitHub Actions bill workflow-run minutes?"
  - "How do I check usage, logs, and artifacts for a workflow run I did not watch live?"
  - "What is the concurrency cancel-in-progress syntax for bounding overlapping runs?"
official_sources:
  - https://docs.github.com
  - https://code.claude.com/docs
  - https://git-scm.com/docs/githooks
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

Unattended agent work — a scheduled workflow, a headless agent loop, a cron job — still consumes real resources even though nobody is watching it run live. Two resource costs matter most:

- **GitHub Actions bills workflow-run minutes.** Every minute a workflow runs is metered, whether or not a human is looking at it (real, documented billing model).
- **LLM-based agents consume real token usage against real rate limits.** A headless agent that loops longer than expected burns tokens (and therefore money and quota) precisely because no one is there to stop it.

Observability is the flip side of cost: because nobody watches an unattended run live, its logs, artifacts, and usage records are usually the *only* evidence of what it did, what it cost, and whether it misbehaved.

## When it is useful

- You have set up a scheduled GitHub Actions workflow (e.g. a recurring agent run) and want to predict and track its cost.
- You run a headless agent (e.g. `claude -p`) on a loop or schedule and need to know how much token usage it accumulates per run.
- A run "finished" while you were away and you need to reconstruct what happened from logs and artifacts.
- You are deciding how long to let an unattended loop run before bounding it with `timeout-minutes` (GitHub Actions) or an iteration cap (Claude Code headless mode supports a `--max-turns`-style limit), because both time and cost scale with run length.

## Prerequisites

- Basic familiarity with the module's trigger types: loops, hooks, and schedules, and the fact that headless/non-interactive mode is the prerequisite for all of them.
- A GitHub repository with Actions enabled if you are observing scheduled workflows.
- For LLM token costs: an account/billing view where your provider reports usage and rate limits (this page does not assert specifics for any particular provider's billing dashboard).

## Current syntax

Nothing new to install — this capability is about reading and bounding existing mechanisms:

- **GitHub Actions concurrency** (real, documented workflow syntax) with `cancel-in-progress` and concurrency groups — bounds overlapping unattended runs, which also bounds their combined cost.
- **GitHub Actions `timeout-minutes`** (real, documented) — caps a runaway job; the documented default is around 360 minutes, so a job with no explicit timeout can bill a lot of minutes before dying on its own.
- **GitHub Actions usage view** — workflow-run minutes consumed are visible in GitHub's usage/billing surfaces (see official docs).
- **Claude Code headless mode** — programmatic invocation (`claude -p`) with an iteration cap (a `--max-turns`-style flag is real and documented for Claude Code) to bound token usage per unattended run.

Note: this page does not claim that Cursor or Codex-CLI have equivalent named billing/timeout/iteration-cap features — that cross-tool comparison is unverified.

## What happens (local and remote)

- A scheduled workflow runs without you: it consumes billed minutes from the moment it starts until it finishes, times out, is cancelled, or is disabled.
- A headless agent run consumes tokens on every turn; a runaway loop keeps consuming tokens until its cap (if any) or until the provider's rate limits intervene.
- Because no one is watching live, the run's **logs** become the primary record of what the agent did, decided, and cost. **Artifacts** are similarly the primary way a workflow can hand you results you were not there to receive.
- Two overlapping unattended runs on the same repository can multiply cost *and* damage; concurrency controls reduce both.
- Cancelling an active run and disabling its future trigger are **two separate operations** in GitHub Actions — stopping the current burn requires cancelling; preventing the next burn requires disabling. A beginner who does only one is surprised when the other keeps happening.

## Practical example

A scheduled agent workflow you left running overnight:

```yaml
on:
  schedule:
    - cron: '0 3 * * *'
concurrency:
  group: nightly-agent
  cancel-in-progress: true
jobs:
  agent-run:
    runs-on: ubuntu-latest
    timeout-minutes: 30
```

What this buys you, cost-wise:

- `timeout-minutes: 30` bounds the worst case: instead of the ~360-minute documented default, a runaway job bills at most 30 minutes.
- The concurrency group with `cancel-in-progress: true` prevents two overlapping runs from both billing minutes at once.
- After each run, check the run's logs (what the agent actually did) and your Actions usage/billing view (how many minutes it consumed).

For the agent side, an equivalent bound on a Claude Code headless run is its documented iteration cap (`--max-turns`-style), which caps token usage the same way `timeout-minutes` caps billed minutes.

## Explanation guidance

### Essential

- Unattended does not mean free: scheduled workflows bill minutes, and LLM agents bill tokens, in both cases whether or not anyone is watching.
- Logs and artifacts matter *more* for unattended runs, not less — they are your only after-the-fact record.
- Bound the blast radius: `timeout-minutes` for GitHub Actions jobs, an iteration cap for headless Claude Code runs.
- Kill switch discipline: cancelling a run and disabling its trigger are separate operations — do both if you want it to stop permanently.

### Experienced-user note

- Add concurrency groups with `cancel-in-progress: true` to scheduled workflows so overlapping runs don't double-bill (and don't double-edit the same repo).
- Check whether your scheduled workflow is even running: GitHub Actions scheduled runs can be delayed or dropped under load, run only on the default branch, and are auto-disabled after 60 days of repository inactivity — so "zero usage this month" may mean the schedule was dropped or disabled, not that the task became free.
- Watch token usage against rate limits too: an agent that hits rate limits mid-run may fail in ways that only show up in logs.

### Optional deeper context

- Idempotency is the design discipline that makes re-running a task safe — relevant here because retries (e.g. re-running a failed scheduled run to inspect it) multiply both billed minutes and token usage. The concept is general and vendor-neutral; HTTP's idempotent-methods definition (RFC 9110 §9.2.2) is the formal anchor most engineers already know.
- GitHub Actions' `on.schedule` uses cron's 5-field format (minute/hour/day/month/weekday, per crontab(5)), so the same cadence that drives the run drives its cost profile.
- `flock` is the Linux equivalent of a concurrency group for plain cron jobs — same bounding idea, same cost rationale.

## Cautions and common failures

- **Assuming a schedule is running.** Scheduled workflows are dropped under load, default-branch-only, and disabled after 60 days of repo inactivity — your cost prediction should include "it might not run at all."
- **Relying on the default timeout.** The documented ~360-minute default means a stuck job can bill for hours before GitHub stops it; set `timeout-minutes` explicitly.
- **Cancelling but not disabling** (or vice versa): the current run stops burning minutes, but the next scheduled run still fires — or the schedule is disabled while a run is still actively consuming.
- **Overlapping runs double-billing (and double-editing).** Without a concurrency group, two scheduled instances can run simultaneously.
- **Unbounded agent loops.** A headless Claude Code run without an iteration cap can consume tokens against rate limits until it never finishes; pair loops with caps.
- **Not checking logs after the fact.** With nobody watching live, unread logs mean unknown behavior *and* unknown cost attribution.
- **Unverified cross-tool claims.** This page's billing, timeout, and concurrency specifics are verified for GitHub Actions and Claude Code; do not assume Cursor or Codex-CLI have equivalent named features.

## Related capabilities

- Scheduling with cron and GitHub Actions (same cadence, same cost surface)
- Concurrency and overlap control for unattended runs
- Bounding runaway loops (`timeout-minutes`, iteration caps, kill-switch discipline)
- Human approval gates and permission modes before enabling unattended runs
- Safety of unattended/autonomous runs (idempotency, environment protection rules)

## Official sources

- https://docs.github.com — GitHub Actions: billing of workflow-run minutes, concurrency, `timeout-minutes`, scheduled-workflow caveats, cancelling vs. disabling runs
- https://code.claude.com/docs — Claude Code headless mode and iteration cap (`--max-turns`-style)
- https://git-scm.com/docs/githooks — git hooks context for unattended automation around git operations

## Provenance

- Grounding facts from this module's earlier Context7/fleet research (2026-09-20), anchored to official documentation: docs.github.com (billing model, concurrency, `timeout-minutes`, scheduling caveats, cancel/disable distinction), code.claude.com/docs (headless mode, iteration cap), crontab(5) (cron format).
- Idempotency framed via RFC 9110 §9.2.2 as a vendor-neutral engineering concept.
- Explicitly unverified, per module caution: Cursor and Codex-CLI feature parity on billing, timeouts, or iteration caps — no such claims are made here.
- No invented commands, flags, or statistics; everything above traces to the grounding facts or is flagged as unverified.