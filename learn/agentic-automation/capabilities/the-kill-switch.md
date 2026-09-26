---
title: "The kill switch: stopping a run vs. disabling its trigger"
module_id: agentic-automation
capabilities:
  - the-kill-switch
context7_library: /websites/github_en_actions
context7_queries:
  - How do I cancel a running GitHub Actions workflow?
  - How do I disable a scheduled GitHub Actions workflow trigger?
  - Why does my workflow still run after I cancelled an active run?
  - How do I stop a GitHub Actions workflow from running again?
official_sources:
  - https://docs.github.com/en/actions
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

When an automated run misbehaves — a scheduled GitHub Actions workflow is producing wrong commits, burning billable workflow-run minutes, or an agent is looping unexpectedly — there are two separate, documented ways to stop it, and they do different things:

- **Cancelling an active run** stops the workflow run that is executing right now.
- **Disabling the trigger** prevents future runs from starting (for example, disabling a scheduled workflow or a workflow entirely).

These are two separate operations in GitHub Actions, each with its own real, documented UI action. A beginner who does only one will be surprised when the other keeps happening: cancel the active run, and tomorrow's scheduled run still fires; disable the schedule, and the currently running job keeps going until it finishes or times out.

## When it is useful

- A scheduled workflow is producing bad output and you need it to stop *now* (cancel the active run) and *never again* (disable the trigger).
- An unattended agent loop is consuming GitHub Actions billable minutes or LLM tokens while nobody is watching it live — unattended runs consume real resources precisely because there is no human at the keyboard watching.
- A runaway loop never naturally completes and you want to intervene before any `timeout-minutes` cap is reached (GitHub Actions jobs have a real, documented timeout setting with a default around 360 minutes — do not wait for it if you can intervene sooner).
- You temporarily want to pause automation (disable the trigger) while keeping the workflow file in place, and re-enable it later.

## Prerequisites

- A GitHub repository with a workflow you (or your team) have write access to.
- Awareness that you need the *base* building block first: headless / non-interactive mode. You cannot loop, hook, or schedule an agent that requires an attended terminal session — and if you have one running, the kill switch is what you reach for when it goes wrong.
- Permission to manage the repository's Actions settings (to cancel runs and disable workflows).

## Current syntax

Kill-switch operations are performed in the GitHub Actions UI and API, not in the workflow file:

- **Cancel an active run:** from the workflow run's page, use the documented *Cancel workflow* action for a run in progress.
- **Disable a scheduled workflow / workflow:** from the workflow's page, use the documented *Disable workflow* action. Scheduled workflows can also be disabled from the Actions settings list.
- Related, documented workflow-file syntax worth knowing alongside the kill switch:
  - `on.schedule` (cron-style, 5-field format) — the trigger you are disabling.
  - `concurrency` with `cancel-in-progress` — a *design-time* mitigation that automatically cancels overlapping runs; it complements but does not replace the manual kill switch.
  - `timeout-minutes` — bounds how long a job can run if a human does not intervene.

Note: cancelling and disabling are separate, real, documented UI actions in GitHub Actions. Do one *or* the other and half the problem remains.

## What happens (local and remote)

- **Cancelling a run:** the active workflow run is stopped remotely on GitHub. Steps that are mid-flight are terminated; anything the run had not yet pushed or committed simply does not happen. This changes nothing about the workflow's definition — the trigger (schedule, `workflow_dispatch`, push, etc.) is untouched.
- **Disabling a workflow/trigger:** future triggers no longer fire, but a run that is already in progress is not affected by the disabling itself — it continues until completion, cancellation, or timeout.
- **Consequence for the beginner:** the "surprise" scenario is real. Cancel only, and the next scheduled run starts anyway. Disable only, and the run in progress keeps consuming billable minutes. A full kill switch is both operations.

## Practical example

A scheduled workflow (`on.schedule` with a cron entry) that runs an agent to auto-fix failing tests has started committing nonsense every night:

1. Go to **Actions** in the repository, select the in-progress run, and **cancel the workflow**. The active run stops; billable minutes stop accruing for that run.
2. Go to the workflow itself and **disable the workflow**. The nightly schedule will not fire again.
3. Later, after fixing the workflow, re-enable it — optionally first triggering it manually with `workflow_dispatch` (the documented on-demand event, a useful middle ground between fully manual and fully scheduled) to test under supervision before trusting the schedule again.

For plain cron jobs running agent loops outside GitHub, the equivalent "disable the trigger" step is removing the crontab entry; the "cancel the run" step is killing the running process. The two-operation distinction applies there too.

## Explanation guidance

### Essential

- Cancelling stops what is happening; disabling stops what will happen. Beginners need both, done in that order when something is actively misbehaving.
- Do not assume cron-like precision from scheduled workflows: GitHub Actions documents that scheduled runs can be delayed or dropped under platform load, only run on the default branch, and are automatically disabled after 60 days of repository inactivity. The 60-day auto-disable is a *platform-imposed* kill switch of sorts — but it is not a substitute for your own.
- Unattended runs consume real resources: GitHub Actions bills workflow-run minutes, and any LLM-based agent burns real token usage against real rate limits. That is exactly why the kill switch matters — nobody is watching live.

### Experienced-user note

- Design-time guardrails reduce the odds you ever need the kill switch: `concurrency` groups with `cancel-in-progress` prevent two overlapping unattended runs from damaging the same repository; `timeout-minutes` bounds a job that never completes; idempotency (the general engineering concept anchored formally in HTTP's idempotent methods, RFC 9110 §9.2.2) makes accidental re-runs harmless instead of harmful.
- Human approval gates before enabling unattended automation also shrink the blast radius: Claude Code asks for permission by default, and explicit flags exist to skip permission prompts — a real but higher-risk mode. On GitHub, environment protection rules with required reviewers are a documented guardrail.

### Optional deeper context

- The same two-operation distinction appears elsewhere in the automation stack: a Claude Code lifecycle hook that misbehaves can be removed or disabled from the hooks configuration (the hooks system on events like PreToolUse, PostToolUse, Stop, SessionStart is real and documented at code.claude.com), while a runaway agent loop itself can be bounded with headless-mode iteration caps (a `--max-turns`-style limit). Git hooks, being machine-local files in `.git/hooks` (unless shared via `core.hooksPath` or pre-commit), are "disabled" simply by removing them — but that is tool-specific detail, not the GitHub kill switch.
- Cross-tool note: whether Cursor or Codex-CLI offer equivalent named kill-switch or hook-disabling mechanisms is unverified — scope any comparison to the tools verified here (GitHub Actions, Claude Code, git) or flag it explicitly as unverified.

## Cautions and common failures

- **Doing only one of the two operations.** The most common beginner failure: cancelling the active run and being surprised when the schedule fires again tomorrow — or disabling the workflow and being surprised the current run keeps running.
- **Assuming cancellation is instant and complete.** A cancelled run stops the workflow; verify no damage was already pushed before it was cancelled.
- **Confusing platform auto-disable with your own kill switch.** The 60-day inactivity auto-disable of scheduled workflows is real and documented, but it is not something to rely on for stopping a misbehaving workflow this week.
- **Relying on timeouts as the only bound.** `timeout-minutes` (default around 360 minutes) is a backstop, not a control — a runaway run can do a lot in hours, and billable minutes accrue until it stops.
- **Skipping the trigger review.** If you disable the schedule but leave a `workflow_dispatch` event, a teammate can still trigger it manually — that may be exactly what you want, but know which triggers remain live.

## Related capabilities

- headless-mode-basics — the prerequisite for any loop, hook, or schedule running unattended
- scheduled-workflows — the trigger you may need to disable
- concurrency-and-overlap — design-time mitigation (`concurrency`, `flock`) for overlapping unattended runs
- permission-modes-and-approval-gates — reducing the odds you need the kill switch at all

## Official sources

- https://docs.github.com/en/actions

## Provenance

Grounded in this session's Context7/fleet research on GitHub Actions scheduling, concurrency, timeouts, billing, and run management (library: /websites/github_en_actions), plus documented facts from git-scm.com and code.claude.com/docs for related-tool context. All claims about cancelling runs, disabling workflows/triggers, scheduled-workflow caveats (default branch, load-based delays, 60-day inactivity auto-disable), `concurrency`, `timeout-minutes`, `workflow_dispatch`, and the billing model are real, documented platform behaviors. Cross-tool comparisons involving Cursor or Codex-CLI are explicitly flagged as unverified. No facts beyond the grounding set have been asserted.