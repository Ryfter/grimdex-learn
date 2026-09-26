---
title: "Hook, schedule, or loop: choosing the right trigger"
module_id: agentic-automation
capabilities:
  - loop-hook-schedule-triggers
context7_library: /websites/platform_claude_en
context7_queries:
  - How do Claude Code lifecycle hooks differ from git hooks?
  - How does headless mode enable loops, hooks, and schedules for an agent?
  - How does the Stop hook event prevent infinite re-triggering?
official_sources:
  - https://code.claude.com/docs/en/hooks
  - https://git-scm.com/docs/githooks
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

When you want an AI coding agent to do repeated or automatic work, you have to pick a *trigger* — the thing that causes the work to start. There are three distinct trigger types, and they are not interchangeable:

- **Loop** — repeat until a condition is met (e.g. "keep working until the tests pass").
- **Hook** — a script that runs automatically on a specific event (e.g. before/after a tool call, before a commit, after a git push attempt).
- **Schedule** — run at a future time or on a recurring cadence (e.g. cron, a scheduled workflow, a one-off reminder).

An agentic "loop" (act → observe → decide → repeat until done) is conceptually different from a programming-language `for`/`while` loop. The language loop iterates over data; the agentic loop iterates over an *outcome* — the agent decides each turn what to do next, and the loop ends when the goal is met or a bound (iteration cap, timeout) is hit.

A prerequisite that underlies all three: **headless / non-interactive mode**. You cannot loop, hook, or schedule an agent that requires an attended terminal session. Claude Code has a real, documented headless mode (`claude -p` / programmatic invocation) that makes unattended triggers possible.

## When it is useful

Choose deliberately, based on *what should start the work*:

- **Loop** when the work is not time- or event-driven but *outcome*-driven: "keep at it until done." Example: run the agent until tests pass.
- **Hook** when the work must happen automatically *in response to an event*, especially to enforce a rule. Examples: a pre-commit hook blocking bad commits, a Claude Code lifecycle hook blocking a tool call the agent is about to make.
- **Schedule** when the work should happen at a specific time or on a cadence, whether or not anything else happened. Example: a nightly maintenance job.

The common beginner mistake is treating these as interchangeable ("just automate it somehow"). They answer different questions: loop = *until what?*, hook = *in response to what?*, schedule = *when?*

## Prerequisites

- An agent that can run in headless / non-interactive mode (e.g. Claude Code's `claude -p`), since attended-only agents cannot be looped, hooked, or scheduled.
- For hooks: a place to install the script — git hooks live in `.git/hooks`; Claude Code lifecycle hooks are configured per its documented hooks system.
- For schedules: a scheduler — cron's 5-field format (minute/hour/day/month/weekday) is the standard that GitHub Actions' `on.schedule` and most other tools mimic or use directly.
- A human approval gate before going unattended: know what permission mode the agent runs in (Claude Code asks by default; flags exist to skip permission prompts, which is a real but higher-risk mode).

## Current syntax

Concrete, verified anchors for each trigger type:

- **Loop (agent-side bound):** Claude Code headless mode has a `--max-turns`-style iteration cap to bound an unattended loop.
- **Hook (git):** `pre-commit`, `commit-msg`, etc., documented at git-scm.com/docs/githooks; failing hooks abort the operation. Hooks are not version-controlled by default; `core.hooksPath` and the pre-commit framework (pre-commit.com) make them shareable.
- **Hook (agent lifecycle):** Claude Code hooks fire on events like `PreToolUse`, `PostToolUse`, `Stop`, `Notification`, `SessionStart`; a non-zero exit code denies/blocks the agent action.
- **Schedule:** cron's 5-field format; GitHub Actions `on.schedule` (with `workflow_dispatch` as the manual/on-demand middle ground).

## What happens (local and remote)

- **Local:** git hooks run client-side around operations like commit; a failing `pre-commit` hook aborts the commit locally.
- **Remote:** server-side git hooks (`pre-receive`, `update`) can reject a push even though the local commit succeeded — useful to know when a locally-fine commit is refused by the remote.
- **Agent lifecycle:** a Claude Code hook returning non-zero can deny the agent's tool call, letting it run semi-autonomously while guardrails stay enforced. The `Stop` event and its `stop_hook_active` field exist specifically to prevent a hook from re-triggering more agent work in an infinite feedback loop.
- **Scheduled (remote):** GitHub Actions scheduled runs are subject to documented caveats: they can be delayed or dropped under platform load, only run on the default branch, and are auto-disabled after 60 days of repository inactivity. Do not assume cron-like precision.

## Practical example

A deliberate trigger choice, using verified features:

1. **Goal:** let the agent fix lint failures without you babysitting it.
2. **Pick a hook, not a loop or schedule** — the trigger is an *event* (the agent trying to edit a file). Configure a Claude Code `PreToolUse` hook that lints the proposed change; a non-zero exit code blocks the edit.
3. If you instead wanted "keep fixing until the suite passes," that's a **loop**: run headless with an iteration cap (`--max-turns`-style) and a timeout bound.
4. If you wanted "tidy the repo every night," that's a **schedule**: cron or a GitHub Actions `on.schedule` workflow — with the documented caveats above in mind.

## Explanation guidance

### Essential

- Loop, hook, and schedule are three different answers to "what starts the work?" Pick based on whether the trigger is an outcome, an event, or a time.
- An agentic loop is not a programming loop: it repeats *decide → act → observe* until done, not over a collection.
- Headless mode is the prerequisite for all three; attended-only agents can't be automated this way.
- Hooks can *block* things: git's pre-commit aborts commits; Claude Code hooks deny tool calls via non-zero exit codes.

### Experienced-user note

- The `Stop` hook + `stop_hook_active` mechanism is the documented safeguard against a hook feeding back into more agent work forever — relevant when chaining hooks into loops.
- Git hooks aren't shared by default; `core.hooksPath` or pre-commit.com are the documented ways to make team hooks reproducible.
- GitHub's `workflow_dispatch` sits between manual and scheduled — a good first step before committing to a cadence.

### Optional deeper context

- Server-side hooks (`pre-receive`, `update`) explain "my commit worked locally but the push was rejected."
- Cross-tool note: this page's named hook/scheduling features are verified for Claude Code, git, and GitHub Actions. Whether Cursor or Codex-CLI have equivalent, named hook-and-scheduling features is **unverified** — do not assume parity when comparing tools.

## Cautions and common failures

- **Assuming schedule precision.** GitHub Actions scheduled workflows can be delayed or dropped, run only on the default branch, and are disabled after 60 days of repo inactivity.
- **Runaway loops.** Bound unattended runs: GitHub Actions `timeout-minutes` (documented default around 360 minutes) and Claude Code's `--max-turns`-style cap exist for this.
- **Overlapping runs.** Two overlapping unattended runs editing the same repo can cause real damage. Use GitHub Actions `concurrency` (with `cancel-in-progress`) or `flock` for plain cron jobs.
- **Kill-switch confusion.** Cancelling an active GitHub Actions run and disabling its future trigger are two separate operations — doing only one means the other keeps happening.
- **Unattended permission modes.** Flags that skip permission prompts are real but higher-risk; prefer approval gates (e.g. GitHub environment protection rules with required reviewers).
- **Cost/observability.** Unattended runs still bill workflow-run minutes and consume LLM tokens against real rate limits — monitor precisely because nobody is watching live.
- **Idempotency.** Design tasks so re-running them twice is safe; HTTP's idempotent methods (RFC 9110 §9.2.2) is the formal anchor.

## Related capabilities

- Headless / non-interactive agent mode (prerequisite for all triggers here)
- Guardrails via agent lifecycle hooks
- Unattended-run safety: timeouts, concurrency, and kill switches
- Scheduled workflows and their documented limits

## Official sources

- https://code.claude.com/docs/en/hooks
- https://git-scm.com/docs/githooks
- https://docs.github.com/en/actions

## Provenance

Grounded in this session's Context7/fleet research against official documentation: Claude Code hooks and headless mode (code.claude.com), git hooks (git-scm.com), and GitHub Actions scheduling/concurrency/timeout behavior (docs.github.com). Cross-tool claims about Cursor or Codex-CLI hook/scheduling parity are explicitly flagged as unverified.