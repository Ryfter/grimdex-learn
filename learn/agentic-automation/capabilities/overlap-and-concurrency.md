---
title: What happens when the next run starts before the last ends
module_id: agentic-automation
capabilities:
  - overlap-and-concurrency
context7_library: /websites/github_en_actions
context7_queries:
  - How do I prevent two scheduled workflow runs from overlapping in GitHub Actions?
  - How does the concurrency keyword and cancel-in-progress work in GitHub Actions?
  - How do I stop two cron jobs from running the same script at the same time on Linux?
official_sources:
  - https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs
  - https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/canceling-a-workflow
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

Overlap and concurrency is what happens when an unattended run (a loop, a scheduled job, or a hook-triggered run) starts a second time while the previous run is still going. For an agent that edits the same repository, two overlapping runs are not just wasteful -- they can cause real damage: one run can commit while the other is mid-change, files can be written at the same time, or the second run can act on a half-finished state the first run left behind. Mitigating overlap means ensuring, by design, that only one instance of a task touches the same repo at a time.

## When it is useful

Any time an unattended task could take longer than its own trigger interval -- for example, a scheduled GitHub Actions run that takes 20 minutes but fires every 10, or a cron job that might still be running when the next cron tick arrives. It is also relevant when multiple triggers can fire the same task (a schedule plus a manual `workflow_dispatch` run), and when an agent-driven job might hang and never finish, making overlap increasingly likely over time.

## Prerequisites

- An unattended run already set up: a scheduled GitHub Actions workflow, a `workflow_dispatch` trigger, or a plain cron job on a Linux machine.
- Headless / non-interactive execution of the agent -- you cannot have an overlap problem (or fix one) with an agent that needs an attended terminal session.
- For cron jobs, a Linux machine where you can install or use the `flock` utility.

## Current syntax

GitHub Actions (at the workflow level):

```yaml
concurrency:
  group: my-task
  cancel-in-progress: true
```

Runs with the same `concurrency.group` share a slot: while one is active, others queue or (with `cancel-in-progress: true`) replace the pending/active run. `cancel-in-progress` can also be set conditionally (for example, on a branch expression) in current GitHub Actions syntax.

Plain cron jobs on Linux, wrapped with `flock`:

```cron
*/10 * * * * flock -n /tmp/my-task.lock /path/to/agent-task.sh
```

`flock` takes an exclusive lock on a lockfile; with `-n`, if the lock is already held, the new invocation exits immediately instead of running. (`flock` also accepts a wait timeout instead of failing immediately, depending on your needs.)

## What happens (local and remote)

With no mitigation, overlap is silent: the platform happily starts the second run, both edit the repo concurrently, and you find out from a corrupted commit, a merge conflict spiral, or duplicated side effects. There is no warning by default.

With `concurrency` groups, a second run either queues behind the first or cancels the in-progress one, so the repo is only ever touched by one run at a time. With `flock -n`, the overlapping cron invocation simply fails fast and exits -- you may want the script to log when that happens so a persistent lock (a stuck job holding the lock forever) is visible rather than invisible.

## Practical example

A nightly agent task that rewrites generated documentation. Two overlapping runs would each commit generated files, producing interleaved, conflicting commits. In GitHub Actions:

```yaml
on:
  schedule:
    - cron: "0 3 * * *"
  workflow_dispatch:

concurrency:
  group: doc-regen
  cancel-in-progress: true

jobs:
  regen:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - run: claude -p "regenerate docs from the spec and commit if changed"
```

The same task as a plain cron job on a Linux box:

```cron
0 3 * * * flock -n /tmp/doc-regen.lock /home/user/bin/doc-regen.sh
```

If a run is still going at the next tick (or a manual `workflow_dispatch` run overlaps a scheduled one), the new run either cancels the old one (Actions) or exits without running (`flock -n`) -- either way, one writer at a time.

## Explanation guidance

### Essential

- Two unattended runs editing the same repo at once can cause real damage: conflicting commits, half-finished state, duplicated effects.
- GitHub Actions' `concurrency` key with `cancel-in-progress` is the documented, built-in mitigation for Actions runs.
- `flock` is the standard Linux tool that gives plain cron jobs the same protection via a lockfile.
- Both mitigations enforce "one writer at a time"; pick queueing vs. cancel behavior deliberately.

### Experienced-user note

- `cancel-in-progress: true` means an interrupted long run leaves partial state behind; design the task so a cancelled run is safe to abandon (this pairs with idempotency, below).
- Note that `cancel-in-progress` can be gated on a condition so, for instance, main-branch runs are never cancelled mid-flight while PR runs are.
- `timeout-minutes` (GitHub Actions, documented default around 360) bounds how long a hung job can hold the concurrency slot -- a hung run without a timeout effectively blocks all future runs in the group.

### Optional deeper context

- Overlap protection is a sibling of idempotency: concurrency control prevents two runs at once, idempotency (a general, well-established engineering concept, formally anchored in HTTP's idempotent-methods definition, RFC 9110 §9.2.2) makes it harmless if one runs twice anyway. Do both for unattended agent work.
- For distributed systems, `flock` locks only one machine; GitHub Actions' concurrency is enforced platform-side across all runners. Match the tool to where the runs actually execute.
- Feature parity for hooks/scheduling/concurrency controls in tools like Cursor or Codex-CLI is unverified in this material -- don't claim equivalent named features exist there; scope claims to GitHub Actions, git, and Claude Code, which are the verified anchors here.

## Cautions and common failures

- Forgetting the mitigation entirely: with no `concurrency` group (or no `flock`), overlap happens silently and damage is discovered after the fact.
- Using the wrong lock path with `flock`: two different lockfile paths protect nothing; make the path specific and consistent for the task.
- No timeout on a run that holds a concurrency slot or lock: a hung run can block all future runs indefinitely. Set `timeout-minutes` in Actions (default is around 360 minutes, which may be far too generous) and cap agent iterations in headless mode (Claude Code has a `--max-turns`-style cap).
- Cancellation leaves partial state: cancelled runs may have already committed or pushed; check what actually happened after a cancel rather than assuming clean state.
- Distinguish killing an active run from disabling its trigger in GitHub Actions -- these are two separate documented operations; doing only one means the other keeps firing.
- Scheduled workflow runs can be delayed or dropped under platform load (documented GitHub caveat), so tight overlap assumptions don't hold at the edges; this makes explicit concurrency control more important, not less.
- Unattended runs consume real billable Actions minutes and real LLM tokens; overlapping duplicate runs double that cost with nobody watching.

## Related capabilities

- `scheduling-cron-and-github-actions`
- `git-hooks-client-and-server`
- `agent-lifecycle-hooks`
- `unattended-run-safety`
- `headless-mode`

## Official sources

- https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/control-the-concurrency-of-workflows-and-jobs
- https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-workflow-runs/canceling-a-workflow
- https://man7.org/linux/man-pages/man1/flock.1.html

## Provenance

Grounded in documented GitHub Actions workflow syntax (concurrency, `cancel-in-progress`, `timeout-minutes`, documented scheduled-run caveats) and the standard Linux `flock` utility; idempotency anchored to RFC 9110 §9.2.2 as a general engineering concept. Cursor and Codex-CLI feature parity is explicitly unverified and flagged as such. Last checked 2026-09-20.