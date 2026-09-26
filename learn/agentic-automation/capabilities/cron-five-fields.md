---
title: Cron syntax in ten minutes
module_id: agentic-automation
capabilities:
  - cron-five-fields
context7_library: /websites/github_en_actions
context7_queries:
  - How do I write a cron schedule expression for a GitHub Actions workflow?
  - What do the five fields of a cron time specification mean?
  - What are the caveats of scheduled workflows in GitHub Actions?
official_sources:
  - https://docs.github.com/en/actions/reference/events-that-trigger-workflows
  - https://man7.org/linux/man-pages/man5/crontab.5.html
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

Cron's time format is the classic five-field specification for *when* a recurring job should run. Each field — minute, hour, day-of-month, month, and weekday — is filled with a number, a wildcard (`*`), a list, a range, or a step expression. It is the underlying standard that most modern scheduling tools, including GitHub Actions' `on.schedule`, mimic or use directly (source: the `crontab(5)` man page and GitHub's "Events that trigger workflows" documentation).

In the context of agentic automation, this is the syntax you use to make a *schedule* happen: one of the three trigger types for repeated agent work, alongside loops (repeat until a condition is met) and hooks (run automatically on a specific event).

## When it is useful

- You want an unattended agent or workflow to run on a recurring cadence — e.g. nightly dependency checks, periodic repo hygiene, or a recurring reminder-style task.
- You are writing a GitHub Actions workflow with `on.schedule` and need to produce a valid cron expression.
- You are reading someone else's schedule config (in cron, GitHub Actions, or most other schedulers) and need to decode it quickly.
- You want a one-off future run rather than a loop-until-condition or an event hook.

## Prerequisites

- A place for the schedule to live: either a plain cron facility (a Linux crontab) or a GitHub Actions workflow file.
- For GitHub Actions scheduled workflows specifically: the workflow must be on the repository's *default branch* — scheduled runs only fire there (documented caveat).
- For any unattended run: a decision about what permission mode the agent or workflow runs in, and a human approval gate, before enabling it (see Cautions).

## Current syntax

Five space-separated fields, left to right:

```
* * * * *
│ │ │ │ │
│ │ │ │ └── day of week (0–7, where both 0 and 7 are Sunday)
│ │ │ └──── month (1–12)
│ │ └────── day of month (1–31)
│ └──────── hour (0–23)
└────────── minute (0–59)
```

Field syntax common to cron and its mimics:

- `*` — every value ("every minute", "every hour", ...)
- `,` — list: `0,15,30,45`
- `-` — range: `9-17`
- `/` — step: `*/10` (every 10th), `9-17/2`
- A concrete number means exactly that value.

A useful way to read an expression: "at minute `<field1>`, at hour `<field2>`, on day-of-month `<field3>`, in month `<field4>`, on weekday `<field5>`." Fields combine with AND (when two day fields are both restricted, the job runs when *either* matches in classic cron — a genuinely surprising behavior worth knowing exists; verify details for your specific scheduler).

In GitHub Actions, the same five-field syntax appears under `on.schedule`:

```yaml
on:
  schedule:
    - cron: "30 14 * * 1-5"
```

GitHub Actions evaluates cron expressions in **UTC**, so a "local time" schedule must be converted from your timezone — a common source of off-by-hours surprises.

## What happens (local and remote)

- **Plain cron (Linux):** the cron daemon wakes, checks each job's five fields against the current time, and runs matching commands locally on that machine. Precision is generally close to the minute.
- **GitHub Actions `on.schedule`:** the same five-field expression schedules a workflow run, but with *documented* differences from cron-like precision:
  - Scheduled runs can be **delayed or dropped** under platform load.
  - They only run on the **default branch**.
  - They are **automatically disabled after 60 days of repository inactivity**.
- A scheduled run itself is a workflow run like any other: it consumes billable workflow-run minutes, can run `workflow_dispatch`-style manual triggers alongside it, and is subject to the workflow's other settings.

Do not assume a GitHub Actions schedule behaves like a strict local cron; the documented caveats above are real platform behavior, not hypotheticals.

## Practical example

A nightly (roughly) unattended maintenance workflow on a GitHub repository:

```yaml
name: nightly-agent-maintenance
on:
  schedule:
    - cron: "17 3 * * *"   # 03:17 UTC every day
  workflow_dispatch: {}     # manual on-demand runs for testing

jobs:
  maintenance:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    concurrency:
      group: nightly-maintenance
      cancel-in-progress: true
    steps:
      - uses: actions/checkout@v4
      # ... agent or script steps here
```

Reading the cron expression `17 3 * * *`: minute 17, hour 3, every day of month, every month, every weekday — i.e., daily at 03:17 UTC.

Notice the deliberately *odd* minute (17). Scheduling tools are load-sensitive; picking an uncommon minute avoids the top-of-hour stampede.

Two practical touches in the example:

- `timeout-minutes` bounds the run if it never completes — important for any unattended job.
- The `concurrency` group with `cancel-in-progress` prevents two overlapping runs from colliding — relevant when the job edits the repository.

Test the schedule by running it manually with `workflow_dispatch` before trusting the cron trigger.

## Explanation guidance

### Essential

- The five fields are minute, hour, day-of-month, month, weekday — memorize the order with "minutes first, days last."
- `*` means "every" in that field; lists, ranges, and steps narrow it down.
- GitHub Actions uses this same five-field syntax and evaluates it in UTC; plain cron uses the machine's local timezone.
- A scheduled run is only one of three trigger types for repeated agent work — distinguish it from a *loop* (repeat until done) and a *hook* (run on an event). A schedule fires on the clock, regardless of whether the previous run finished.
- Scheduled GitHub Actions workflows run only on the default branch and are disabled after 60 days of repo inactivity — schedule-based automation can silently stop, which is exactly why you must watch unattended runs.

### Experienced-user note

- The interaction between the two day fields (day-of-month and weekday) is classic-cron's best-known quirk: if both are restricted, most cron implementations OR them rather than AND them. Verify behavior in your specific scheduler before relying on it.
- When wiring an unattended agent to a schedule, think about idempotency: design the task so running it twice is safe, not harmful — scheduled runs can be delayed or dropped, so "exactly once" is not a promise you get.
- If you need strict timing, plain cron (or a self-hosted scheduler) beats GitHub Actions scheduled runs; if you need GitHub-context automation, accept the documented imprecision.
- For plain cron jobs that touch the same resources, `flock` is the standard Linux utility to prevent overlapping runs; for GitHub Actions, use the `concurrency` syntax.

### Optional deeper context

- Cron's five-field format predates all of today's agent tooling, which is precisely why it became the common vocabulary: GitHub Actions, most CI schedulers, and many agent-scheduling wrappers mimic or use it directly. Learning it once transfers almost everywhere — though the details (timezone handling, 0/7 Sunday, day-field OR-ing) vary by implementation, so always check the specific tool's docs.
- Note that while Claude Code's headless mode (`claude -p`) is the documented prerequisite building block for driving agent work unattended — and Claude Code has its own documented hooks and `--max-turns`-style caps — the scheduling layer itself is typically external: cron or GitHub Actions. Cursor's and Codex-CLI's hook-and-scheduling feature parity with these is **unverified**; do not assume equivalent named features there without checking.
- The `crontab(5)` man page is the formal reference for the field syntax; RFC 9110 §9.2.2 (idempotent HTTP methods) is a useful formal anchor when reasoning about making scheduled tasks safe to re-run.

## Cautions and common failures

- **Assuming cron precision from GitHub Actions.** Scheduled runs can be delayed or dropped under platform load. Do not build anything that requires to-the-minute reliability on top of a scheduled workflow.
- **Timezone mistakes.** GitHub Actions cron is UTC. A schedule that "fires at 9pm" in your head may fire at a completely different local hour — or shift relative to daylight saving time.
- **Silent disablement.** After 60 days of repository inactivity, scheduled workflows are automatically disabled. A schedule that quietly stops running is a classic unattended-automation failure; periodic manual checks or a watchdog are warranted.
- **Default-branch-only.** A schedule defined on a feature branch will not fire.
- **Overlapping runs.** Two overlapping unattended runs editing the same repository can cause real damage. Use GitHub Actions' `concurrency` syntax, or `flock` for plain cron jobs.
- **Runaway runs.** Bound every unattended run: `timeout-minutes` for GitHub Actions jobs (default around 360 minutes), `--max-turns`-style iteration caps for Claude Code headless runs.
- **Unattended cost and risk.** Billable workflow minutes and real token usage continue whether or not anyone is watching. Require a human approval gate — appropriate permission mode for the agent, and GitHub environment protection rules with required reviewers for deployments — before enabling any schedule.
- **Kill-switch confusion.** Cancelling an active run and disabling the schedule's future trigger are two separate operations in GitHub Actions. Doing only one will leave the other still happening — check both when you want a schedule fully off.
- **Cross-tool assumptions.** Feature parity for hooks/scheduling in Cursor or Codex-CLI relative to Claude Code or GitHub Actions is unverified; scope scheduling claims to the tool you actually verified.

## Related capabilities

- Headless / non-interactive agent invocation (the prerequisite for any unattended trigger)
- Git hooks and agent lifecycle hooks (event-triggered, as opposed to clock-triggered)
- Concurrency control (`concurrency` groups, `flock`)
- Bounding unattended runs (`timeout-minutes`, iteration caps)
- Idempotency for repeatable tasks
- Observability and cost for unattended runs

## Official sources

- GitHub Actions — "Events that trigger workflows": https://docs.github.com/en/actions/reference/events-that-trigger-workflows
- `crontab(5)` man page (cron field syntax): https://man7.org/linux/man-pages/man5/crontab.5.html

## Provenance

- Grounded in this module's session research: cron's five-field format as the standard that GitHub Actions' `on.schedule` mimics (crontab(5); docs.github.com), and the documented GitHub Actions scheduling caveats (delays/drops under load, default-branch-only, 60-day inactivity disablement).
- Practical hardening guidance (concurrency, timeout-minutes, workflow_dispatch, environment protection rules, kill-switch distinction, billing model) drawn from the same verified grounding facts.
- Cross-tool claims about Cursor and Codex-CLI hooks/scheduling are explicitly flagged unverified, consistent with this module's earlier research caution.
- Last checked 2026-09-20; no material changes since.