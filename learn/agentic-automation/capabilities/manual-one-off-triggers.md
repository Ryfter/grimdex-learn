---
title: Manual and one-off triggers (workflow_dispatch)
module_id: agentic-automation
capabilities:
  - manual-one-off-triggers
context7_library: /websites/github_en_actions
context7_queries:
  - How do I trigger a GitHub Actions workflow manually with workflow_dispatch?
  - What is the difference between a scheduled workflow and a manually dispatched one?
  - How do I pass inputs to a workflow_dispatch event?
official_sources:
  - https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows
  - https://docs.github.com/en/actions/using-workflows/manually-running-a-workflow
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

`workflow_dispatch` is a real, documented GitHub Actions event that lets you trigger a workflow manually, on demand — either from the GitHub web UI, the CLI, or the API. It occupies the middle ground between fully manual work (you running commands on your own machine) and fully scheduled work (a cron-style `on.schedule` trigger running the workflow automatically).

Instead of waiting for a push, a pull request, or a cron schedule, you decide when the run happens. The workflow defines `on: workflow_dispatch`, and then a "Run workflow" button appears on the Actions tab, letting you start it whenever you choose.

## When it is useful

Manual dispatch is the right tool when:

- **You want a run only when you say so.** A cleanup task, a one-off migration, or a report you generate on demand rather than on a cadence.
- **You are testing an automation before scheduling it.** Dispatching the same workflow by hand is a safe way to validate behavior before attaching it to a recurring `schedule` trigger.
- **The task is irregular.** Some jobs do not fit a cron pattern; the need arises when it arises, and a human is the best judge of when.
- **You want a human approval gate built into the trigger itself.** Because a person must explicitly click "Run workflow" (or invoke the API/CLI), nothing runs unattended until someone decides it should.

## Prerequisites

- A GitHub repository with a `.github/workflows/` directory and at least one workflow file.
- Familiarity with basic workflow syntax (`on:`, `jobs:`, `steps:`).
- Understanding that, like scheduled workflows, a `workflow_dispatch` workflow runs in the cloud on GitHub-hosted or self-hosted runners — this is a step toward unattended execution, so the safety concepts from this module (permission modes, concurrency, timeouts) apply here too.

## Current syntax

The event is declared in the workflow's `on:` block:

```yaml
on:
  workflow_dispatch:
```

That minimal form is enough to make the workflow manually runnable. The grounding for this is the same scheduling family as cron: `workflow_dispatch` lives alongside `on.schedule` in the same events-that-trigger-workflows model, where the schedule trigger mimics cron's 5-field format (minute/hour/day/month/weekday). Dispatch and schedule can also coexist in one workflow:

```yaml
on:
  workflow_dispatch:
  schedule:
    - cron: "0 3 * * *"
```

This combination is a common pattern: the same job can be fired by hand today and put on a recurring cadence later, without rewriting it.

## What happens (local and remote)

`workflow_dispatch` is entirely a remote-side mechanism. Unlike git hooks (which run on your machine, in `.git/hooks`, around local git operations) or Claude Code lifecycle hooks (scripts fired by a local agent session), a dispatched workflow executes on GitHub's runners against your repository's remote state.

Because the run happens remotely:

- Nobody is watching it live. The cost/observability concern from this module applies: workflow runs bill against workflow-run minutes, and if the workflow invokes an LLM-based agent, it consumes real tokens against real rate limits.
- It runs on a branch you select at dispatch time (by default, the repository's default branch). The workflow file must exist on that branch for the dispatch option to appear.
- The run appears in the Actions tab with full logs, so you can inspect it after the fact even though you weren't attached to it during execution.

## Practical example

A team has a repository-maintenance script — say, triaging stale issues with an AI agent — that they are not ready to put on a nightly schedule. They wire it as a manually dispatched workflow first:

```yaml
name: Agent maintenance run
on:
  workflow_dispatch:

jobs:
  maintain:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/agent-triage.sh
```

For the first few weeks, a team member clicks "Run workflow" in the Actions tab whenever they want a pass done. This gives them a human approval gate on every single run — each execution is a deliberate decision. Once they trust the script's behavior, they add a `schedule:` trigger alongside the existing `workflow_dispatch:` and the job moves onto a cadence without any other changes. The manual trigger stays in place, useful for an on-demand run between scheduled ones.

If the agent writes to the repository, this is also the moment to think about idempotency — designing the task so that running it twice in a row is safe, not harmful — since a double-click on "Run workflow" (or two people dispatching near-simultaneously) can produce overlapping runs. GitHub Actions' `concurrency` setting with `cancel-in-progress` is the documented mitigation for that overlap risk.

## Explanation guidance

### Essential

- Frame `workflow_dispatch` as the third trigger type in this module's trio: a **loop** repeats until a condition is met, a **hook** fires on an event, and a **schedule** fires on a clock. Manual dispatch is the deliberate, human-in-the-loop member of that family — the trigger *is* a person pressing a button.
- Emphasize the middle-ground framing: fully manual (you run everything yourself, nothing is reproducible) on one end, fully scheduled (cron fires whether or not anyone is ready) on the other. Dispatch gives you automation's reproducibility with a human's timing judgment.
- Show that the trigger is declared in the workflow file itself (`on: workflow_dispatch`), not configured in a separate settings panel — the workflow must exist on the branch you dispatch against.
- Point out the natural upgrade path: dispatch first, schedule later. This is the safest on-ramp to unattended runs because every early iteration has a human gate on it.

### Experienced-user note

- Dispatch and schedule can share one workflow file, which makes A/B comparison easy: run the same job by hand and on a cron and diff the results.
- If you dispatch runs that invoke an agent in a permissive mode, remember that skipping permission prompts is a real but higher-risk Claude Code configuration; a manual trigger is a human gate, but it does not guard what happens *inside* the run. Bound the damage with `timeout-minutes` and, for agent loops, an iteration cap such as Claude Code headless mode's `--max-turns`-style limit.
- Dispatched runs still need the concurrency guard if the job writes to shared state. Treat "I clicked the button twice" the same way you'd treat two overlapping cron runs — one `flock` or concurrency-group discipline covers both worlds.
- A note on tool parity: how other AI coding agents (Cursor, Codex-CLI) handle manual or on-demand triggers is **unverified** in this module's research — the claims above are scoped to GitHub Actions, and cross-tool comparisons should be flagged rather than asserted.

### Optional deeper context

- The conceptual throughline across this module: headless mode is the prerequisite for all unattended triggers, and dispatch is the gentlest entry point because a human *is* the trigger. If learners later move to full schedules, the habits built here — bounded runs, idempotent tasks, concurrency control, watching billing and token usage — carry over directly.
- The kill-switch distinction applies here too: cancelling an active run and disabling future triggers are two separate operations in GitHub Actions. With manual dispatch, the "future trigger" is the button itself, so the equivalent of disabling is removing the `workflow_dispatch` trigger from the workflow file — worth noting for learners who assumed the Actions UI controls both.
- The cron comparison cuts both ways: scheduled workflows inherit cron's model but not cron's precision (documented caveats: delays or drops under load, default-branch-only, auto-disable after 60 days of repo inactivity). Dispatch has none of those caveats because a human fires it — one more reason it's a good first step.

## Cautions and common failures

- **The dispatch option doesn't appear.** The workflow file with `on: workflow_dispatch` must exist on the branch you're dispatching against. If you added it on a feature branch, it won't be dispatchable from the default branch yet.
- **Assuming dispatch is a free trial of scheduled runs, safety-wise.** A dispatched run is still an unattended cloud run once started. Apply the same guardrails: `timeout-minutes` to bound a run that never completes, `concurrency` to prevent overlapping runs, and awareness of workflow-run billing and any LLM token usage.
- **Double-dispatch overlap.** Two people (or one impatient click) can start two overlapping runs that both edit the repository. Use the `concurrency` key with `cancel-in-progress`, mirroring the `flock` discipline used for plain cron.
- **No approval-gate confusion.** The human click is the approval gate — but only for starting the run. What the run is *allowed to do* (e.g., an agent with prompts skipped) is a separate permission-mode decision.
- **Cross-tool assumption.** Don't assume other agent tools offer an equivalent manual-trigger mechanism; that parity is unverified here. Scope claims to GitHub Actions unless verified otherwise.

## Related capabilities

- Scheduled workflows (`on.schedule`) — the cron-style recurring trigger that dispatch naturally upgrades into.
- Headless / non-interactive agent mode — the prerequisite for any unattended trigger, manual or scheduled.
- Concurrency and overlap control (`concurrency` groups, `flock`) — protects any trigger type from overlapping runs.
- Runaway-loop bounds (`timeout-minutes`, iteration caps) — bounding damage when a run doesn't finish.
- Kill switch operations — cancelling vs. disabling, two separate actions.
- Git hooks and Claude Code lifecycle hooks — the event-driven siblings of trigger-based automation.

## Official sources

- GitHub Actions — "Events that trigger workflows" (includes `workflow_dispatch`): https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows
- GitHub Actions — "Manually running a workflow": https://docs.github.com/en/actions/using-workflows/manually-running-a-workflow

## Provenance

Grounded in real, documented GitHub Actions behavior as of fall 2026: `workflow_dispatch` as a manual/on-demand trigger event, its relationship to `on.schedule` and cron's 5-field model, and the surrounding safety features (concurrency, `timeout-minutes`, workflow-run billing, cancel vs. disable) all come from docs.github.com and the module's prior research. Claims about Cursor and Codex-CLI hook/scheduling parity are explicitly unverified and flagged as such. The "middle ground between fully manual and fully scheduled" framing follows the module's trigger-type taxonomy (loop / hook / schedule), with dispatch positioned as the human-gated entry point to unattended automation.