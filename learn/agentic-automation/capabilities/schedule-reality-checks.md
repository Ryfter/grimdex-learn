---
title: Scheduled does not mean exactly on time
module_id: agentic-automation
capabilities:
  - schedule-reality-checks
context7_library: /websites/github_en_actions
context7_queries:
  - "Why is my scheduled GitHub Actions workflow not running at the exact cron time?"
  - "Are GitHub Actions scheduled workflows affected by repository inactivity?"
  - "Do GitHub Actions cron schedules run on non-default branches?"
official_sources:
  - https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows
  - https://crontab.guru
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

GitHub Actions supports running a workflow on a time-based trigger, using `on.schedule` with a cron expression — the same 5-field time format (minute, hour, day of month, month, day of week) that underlies classic cron. This lets you run an AI coding agent's task on a recurring cadence without anyone typing a command.

The purpose of this capability page is not the scheduling syntax itself — it is the documented gap between *when you schedule* and *when it actually runs*. Beginners often assume a scheduled workflow behaves like a precise cron job. It does not, and the specific, documented reasons are covered below.

## When it is useful

This page matters whenever you set up recurring agent work, for example:

- A nightly workflow that opens a maintenance PR or runs a long refactor.
- A scheduled dependency-audit run by an agent, meant to keep a repository current.
- Any recurring task where someone will eventually ask, "why didn't this run last night?"

If you are about to write `on.schedule:` for the first time, read this page before relying on the schedule for anything time-sensitive.

## Prerequisites

- A GitHub repository where you can edit workflow files.
- Basic familiarity with a workflow YAML file and the `on:` trigger syntax.
- Awareness of the distinction between a **schedule** (time-based recurring trigger) and a **hook** or an ad-hoc **loop** — schedules repeat by the clock, not by an event or a completion condition.
- Basic cron syntax literacy: five fields, minute / hour / day-of-month / month / day-of-week. (`0 3 * * *` = 03:00 every day.)

## Current syntax

The schedule trigger is a key under `on:`:

```yaml
on:
  schedule:
    - cron: "0 3 * * *"   # intended: every day at 03:00 UTC
```

Notes on the syntax itself:

- The cron expression uses the standard 5-field format, evaluated in **UTC**, not the repository owner's local time.
- `workflow_dispatch` is a separate, real GitHub Actions event for a manual/on-demand run — the useful middle ground between fully manual and fully scheduled. Adding it alongside `schedule` gives you a button to test the workflow immediately.

```yaml
on:
  schedule:
    - cron: "0 3 * * *"
  workflow_dispatch:
```

## What happens (local and remote)

Scheduled workflows run on GitHub's infrastructure, on GitHub's terms. The following behaviors are documented, real platform behaviors — not folklore:

1. **Runs can be delayed or dropped under platform load.** GitHub Actions scheduled runs are best-effort during periods of high load: a run may start later than the scheduled time, or in some cases not start at all. The schedule is an approximation, not a guarantee of cron-like precision.
2. **Only the default branch is scheduled.** A scheduled workflow trigger only fires for the workflow file on the repository's default branch. A schedule written in a branch or a pull request's version of the workflow file will not fire.
3. **Automatic disabling after inactivity.** If a repository has no activity for 60 days, its scheduled workflows are automatically disabled. If your agent's only effect on the repo is... nothing (it found no changes, opened no PRs), the schedule can quietly turn itself off. You will need to re-enable it manually (or use `workflow_dispatch` to notice).

For comparison: plain cron on your own machine, or `flock`-guarded cron jobs, run under your control and fire on the clock you set. GitHub Actions' `on.schedule` mimics the cron format but adds the platform-level caveats above.

## Practical example

Suppose an agent is scheduled to run nightly maintenance on a repository:

```yaml
name: Nightly agent maintenance
on:
  schedule:
    - cron: "30 2 * * *"    # intended: 02:30 UTC daily
  workflow_dispatch:         # manual test button
jobs:
  maintenance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./run-agent-maintenance.sh
```

What a first-time user should expect:

- The run may start at 02:30, or a bit later, or occasionally not at all if GitHub is under heavy load. Build the automation so a missed run is not a catastrophe (for example, have it catch up on missed work rather than assume exactly one run happened since last time).
- If the maintenance script only *reports* and never writes anything to the repository, and no human activity occurs for 60 days, the schedule will be disabled by GitHub. A human should periodically check that scheduled workflows are still enabled.
- If someone forks or works on a feature branch and edits the cron there, that change has no effect on scheduling until it lands on the default branch.

## Explanation guidance

### Essential

- **Cron format is real; cron precision is not.** The 5-field format works as documented, but the *firing time* is best-effort on a shared platform.
- **Default branch only.** This is the most common beginner surprise: "I changed the schedule, why is the old one still running?" — because the default branch's version is the one that fires.
- **60-day inactivity auto-disable.** Scheduled workflows are not "set and forget." If nothing else touches the repo, GitHub turns them off.
- **Always pair `schedule` with `workflow_dispatch`** so you can trigger the run manually to verify it works at all — otherwise you wait a day (or longer, if the run is delayed or dropped) to find out it was broken.

### Experienced-user note

- Times are in UTC — set cron expressions accordingly if you mean a specific local time.
- Design scheduled agent tasks to be **idempotent** — safe to re-run — since a delayed or doubled-up run is a real possibility on a best-effort platform.
- If a schedule has been auto-disabled by the 60-day rule, re-enabling it is a manual operation; some teams add a very occasional manual commit or use `workflow_dispatch` as a reminder/check.
- If precision actually matters, plain cron on infrastructure you control (with `flock` to prevent overlapping runs) gives you clock-firing guarantees that GitHub's scheduler does not.

### Optional deeper context

- The cron format itself is a long-standing standard (see `crontab(5)`), and GitHub's `on.schedule` follows the same field order and semantics. Most scheduling tools you will encounter use or mimic this format.
- The 60-day rule and the default-branch rule are documented GitHub behaviors, not undocumented quirks — pointing a skeptical colleague at the docs resolves most confusion quickly.

## Cautions and common failures

- **Do not assume cron-like precision.** Documented platform behavior: scheduled runs can be delayed or dropped under load. If your automation breaks when a run is late or skipped, the design is too fragile.
- **Editing the workflow on a branch does nothing** until it reaches the default branch — a frequent source of "my change didn't take effect."
- **Silent auto-disable after 60 days of no repository activity.** Nobody is notified; the schedule just stops. Check periodically, or pair with `workflow_dispatch` so a human can trigger and notice.
- **Missed run ≠ zero work needed.** If a scheduled run is dropped, the underlying task (e.g., dependency updates) still needs doing eventually. Design the agent task to tolerate and catch up on missed runs rather than assume exactly one run occurred.
- **Cost and unattended-run safety still apply.** Even best-effort schedules cause real runs, consuming workflow-run minutes and, for an LLM agent, real tokens against real rate limits — nobody is watching the run live, so observability and a plan for cancelling a runaway run matter. (Cancelling an active run and disabling future triggers are two separate operations in GitHub Actions.)
- **Concurrency:** if a delayed run overlaps the next scheduled run, two unattended agents could edit the repository simultaneously. GitHub Actions' `concurrency` setting (`cancel-in-progress`, concurrency groups) is the documented mitigation.

## Related capabilities

- `headless-mode` — the prerequisite building block: you cannot schedule an agent that requires an attended terminal.
- `git-hooks-guardrails` — hooks as the event-based counterpart to schedules.
- `concurrency-and-timeouts` — bounding overlapping and runaway runs.
- `unattended-run-safety` — approval gates, idempotency, cost/observability.

## Official sources

- <https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows> -- GitHub's own documentation of the `schedule` event and its documented delay/inactivity caveats.
- <https://crontab.guru> -- a well-known third-party cron-expression reference/builder tool, not vendor documentation, useful for checking a schedule expression before shipping it.

## Provenance

Grounded in the module's session research: GitHub Actions `on.schedule` documented caveats (delayed/dropped runs under load, default-branch-only firing, 60-day inactivity auto-disable), sourced from docs.github.com "Events that trigger workflows"; cron 5-field format per crontab(5). No claims made about Cursor or Codex-CLI scheduling behavior — cross-tool scheduling parity is unverified and intentionally not asserted.