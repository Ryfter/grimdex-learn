---
title: Scheduled GitHub Actions (on.schedule)
module_id: agentic-automation
capabilities:
  - scheduled-workflows-github-actions
context7_library: /websites/github_en_actions
context7_queries:
  - How do I trigger a GitHub Actions workflow on a schedule with cron?
  - Why did my scheduled GitHub Actions workflow not run on time?
  - How do I stop or prevent a scheduled workflow from running?
official_sources:
  - https://docs.github.com/actions/using-workflows/events-that-trigger-workflows
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

`on.schedule` is a GitHub Actions event that triggers a workflow automatically at times you define, using cron syntax. It is the accessible "run this nightly" pattern: you describe the cadence in the workflow file, and GitHub runs it for you on that cadence without anyone pressing a button.

The schedule uses cron's standard 5-field time format -- minute, hour, day of month, month, day of week -- the same underlying format used by Unix `crontab` and mimicked by most other scheduling tools. A workflow can contain a `schedule` trigger with one or more cron expressions, alongside other triggers.

## When it is useful

Use a scheduled workflow whenever a task should recur on a cadence rather than in response to an event. Typical cases for people who are not infrastructure specialists:

- A nightly job that checks for outdated dependencies or drift.
- A recurring report or status check that runs once a day.
- A scheduled maintenance task, such as cleaning up artifacts.
- A one-off reminder-like run at a specific future time.

`workflow_dispatch` is the complementary event for a manual, on-demand run -- the middle ground between "I run everything by hand" and "this runs every night no matter what." Many workflows have both triggers: a schedule for the routine case and dispatch for "run it now."

## Prerequisites

- A GitHub repository with a workflow file under `.github/workflows/`.
- Basic familiarity with YAML and with reading cron expressions.
- Understanding that the workflow must live on the repository's **default branch** for the schedule to be active.
- A human approval pass before relying on an unattended job: know what the workflow can touch (secrets, write permissions, deploy targets) and treat the schedule as granting it that power repeatedly.

## Current syntax

```yaml
name: Nightly check
on:
  schedule:
    - cron: "30 3 * * *"   # 03:30 UTC every day
  workflow_dispatch:

jobs:
  nightly:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/nightly-check.sh
```

Cron fields, left to right:

| Field | Meaning | Example |
|---|---|---|
| minute | 0–59 | `30` |
| hour | 0–23 | `3` |
| day of month | 1–31 | `*` |
| month | 1–12 | `*` |
| day of week | 0–6 | `*` |

`*` means "every value" for that field. The example above reads: minute 30, hour 3, every day. All scheduled times are interpreted in UTC, not your local timezone.

## What happens (local and remote)

Everything happens remotely; a scheduled workflow involves no local machine at all. GitHub reads the workflow file on the default branch, and at each scheduled time it queues and runs the workflow on GitHub-hosted or self-hosted runners.

Important documented behavior of scheduled workflows:

- **Runs can be delayed or dropped.** Under periods of high platform load, scheduled runs may start late or not fire at all. Do not assume cron-like precision.
- **Only the default branch is scheduled.** A schedule trigger in a workflow on a feature branch does nothing.
- **Schedules auto-disable after 60 days of repository inactivity.** If the repository is inactive, GitHub disables the scheduled workflow; it must be re-enabled manually.

Because the run is unattended, its cost and behavior are also unattended: workflow-run minutes are billed against your GitHub Actions quota, and the workflow consumes resources precisely because nobody is watching it live.

## Practical example

A nightly dependency drift check that a maintainer can also trigger by hand:

```yaml
name: Nightly drift check
on:
  schedule:
    - cron: "0 4 * * 1-5"   # 04:00 UTC, Monday through Friday
  workflow_dispatch:

concurrency:
  group: nightly-drift
  cancel-in-progress: true

jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/check-drift.sh
```

Two guardrails are worth copying into any scheduled job:

- `concurrency` with a named group ensures two overlapping scheduled runs cannot pile up and edit the repository at the same time; `cancel-in-progress: true` cancels a stale run when a new one starts.
- `timeout-minutes` bounds how long the job can run, so a job that never completes cannot consume minutes indefinitely.

## Explanation guidance

### Essential

For someone new:

- A scheduled workflow is "cron, but GitHub runs it." Same 5-field cron format you will meet everywhere else in scheduling.
- Times are UTC. Pick your hour accordingly.
- The schedule only works from the default branch, and GitHub may delay or skip runs under load -- treat it as "roughly at this time," not "exactly at this time."
- If the repo goes inactive for 60 days, the schedule is automatically disabled. If your nightly job silently stops, check this first.
- Before trusting it unattended, look at what it can do: which secrets it uses, whether it has write access, what it deploys. A schedule is a standing permission.

### Experienced-user note

- Pair `schedule` with `workflow_dispatch` so you can test the workflow by hand instead of waiting for the next scheduled fire.
- Use a `concurrency` group keyed to the schedule's purpose, not just the workflow name, if multiple scheduled workflows touch the same repository or environment. For plain cron jobs outside GitHub (e.g. on a Linux box), `flock` is the equivalent single-run guard.
- For deployments or releases from a schedule, use GitHub environment protection rules with required reviewers so an unattended run cannot reach a protected environment without a human.
- The kill-switch distinction matters in incident response: **cancelling** an active run and **disabling** its future trigger are two separate operations. If a scheduled workflow is misbehaving, do both.

### Optional deeper context

- Cron syntax originates in Unix `crontab(5)`; GitHub's implementation is one of many tools that mimic or use that format directly, so cron knowledge transfers.
- Idempotency is the design discipline that makes scheduled re-runs safe: write the job so running it twice does not cause harm. HTTP's idempotent-methods definition (RFC 9110 §9.2.2) is the formal anchor most engineers already know.
- Where you need cron-precision timing or guarantees a run cannot be dropped, a self-managed scheduler (plain cron plus `flock`, or a dedicated scheduler) gives more control in exchange for more operational burden.
- How other coding-agent tools map their own scheduling or hook features onto these patterns is not verified here; this page's claims are scoped to GitHub Actions specifically.

## Cautions and common failures

- **"My schedule didn't fire."** Most common causes, all documented: the workflow is not on the default branch; the run was delayed or dropped under platform load; or the repository was inactive for 60 days and the schedule was auto-disabled.
- **"It ran at the wrong time."** Cron times are UTC. 03:30 UTC is not 03:30 local.
- **Cron expression mistakes.** Five fields, space-separated. `30 3 * * *` is a daily run at 03:30; writing only four fields, or using `*/` ranges incorrectly, silently produces the wrong cadence or none.
- **Overlapping runs.** Two scheduled runs editing the same repository concurrently can cause real damage. Add a `concurrency` group; `cancel-in-progress` controls whether the older run is cancelled.
- **Runaway job.** A job that hangs consumes billed minutes indefinitely. Set `timeout-minutes` (default is on the order of 360 minutes -- far longer than most nightly jobs need).
- **Unattended cost.** Scheduled runs bill workflow minutes and consume resources whether or not anyone looks. Watch usage; nobody is watching the run live.
- **Stopping it wrong.** Cancelling the in-flight run does not prevent the next scheduled fire; disabling the schedule does not cancel the run currently executing. These are separate actions.
- **Cross-tool assumptions.** Cursor and Codex-CLI's parity with these scheduling features is unverified; do not assume a pattern that works in GitHub Actions has a direct equivalent in those tools.

## Related capabilities

- `git-hooks-shared-via-core-hookspath` -- the other "runs automatically without me" pattern, anchored to git operations rather than time.
- `claude-code-headless-mode` -- the prerequisite building block for looping, hooking, or scheduling an AI agent at all.
- `claude-code-lifecycle-hooks` -- event-triggered automation around agent actions, complementing time-triggered workflows.

## Official sources

- GitHub Docs -- "Events that trigger workflows" (schedule, workflow_dispatch): https://docs.github.com/actions/using-workflows/events-that-trigger-workflows

## Provenance

Grounded in GitHub's documented `on.schedule` event behavior, cron's 5-field `crontab(5)` format, and documented scheduled-workflow caveats (delays/drops under load, default-branch restriction, 60-day inactivity auto-disable), plus documented GitHub Actions mitigations (`concurrency`, `timeout-minutes`, environment protection rules, billing for workflow-run minutes). Claims are scoped to GitHub Actions; feature parity with Cursor or Codex-CLI is explicitly unverified. Compiled 2026-09-20 against fall-2026 grounding research for the agentic-automation module.