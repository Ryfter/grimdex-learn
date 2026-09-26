---
title: Human approval gates before autonomy
module_id: agentic-automation
capabilities:
  - human-approval-gates
context7_library: /websites/platform_claude_en
context7_queries:
  - How does Claude Code ask for permission before running tools by default?
  - What flag lets Claude Code skip permission prompts, and what are the risks?
  - How do lifecycle hooks block agent actions before they run?
official_sources:
  - https://code.claude.com/docs/en/hooks
  - https://docs.github.com/
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

A human approval gate is any mechanism that forces a person to say "yes" before an agent does something consequential. Before you let an agent loop, run on a hook, or execute on a schedule unattended, you need to decide two things:

1. **What permission mode the agent runs in.** By default, Claude Code asks before performing actions that need permission — an unattended run can't "ask," so you must either keep the default attended behavior for attended work, or consciously choose a higher-risk configuration.
2. **What deploy/run gates exist downstream.** For GitHub-based work, environment protection rules with required reviewers are a real, documented GitHub feature: a workflow that targets a protected environment pauses until an approved reviewer signs off.

An approval gate is deliberately the opposite of "skip permission prompts" — it's a real but higher-risk mode. The gate is what makes semi-autonomy safe.

## When it is useful

- You are about to run an agent in headless mode (`claude -p` style programmatic invocation) inside a loop, hook, or schedule — anywhere nobody is sitting at the terminal to answer prompts.
- You want an agent to draft or stage work automatically, but a human to approve anything that merges, deploys, or mutates a protected resource.
- You are converting a previously attended workflow into a scheduled one (e.g., a cron-style GitHub Actions workflow) and need to decide who reviews its output.

## Prerequisites

- Understanding of the headless / non-interactive mode prerequisite — you cannot loop, hook, or schedule an agent that requires an attended terminal session, which is exactly why explicit approval gates matter for unattended runs.
- A git repository, and (for the GitHub side) a repository hosted on GitHub where you can configure environments and workflow protection rules.
- Familiarity with the agent's permission behavior — Claude Code asks by default in interactive use.

## Current syntax

There is no single command for "approval gate"; it's a configuration decision across two layers:

- **Claude Code permission mode:** the default behavior asks before consequential actions. Explicit flags exist to skip permission prompts — these are real and documented, but they are the higher-risk path. Do not combine "skip prompts" with unattended loops/schedules without an intentional compensating gate (e.g., agent lifecycle hooks that block dangerous actions).
- **Claude Code lifecycle hooks (as guardrails):** scripts on events such as `PreToolUse` can return a non-zero exit code to deny an agent action. This is the documented way to keep an agent running semi-autonomously while still enforcing guardrails — a scripted stand-in for a human yes/no at the riskiest steps. The `Stop` event and its `stop_hook_active` field exist to prevent those hooks from re-triggering infinite agent work.
- **GitHub environment protection rules:** define an environment (e.g., `production`), mark it protected, and add required reviewers. A workflow job targeting that environment waits for an approved human reviewer before proceeding.

This page's syntax claims are scoped to Claude Code and GitHub Actions, which are the verified tools here.

## What happens (local and remote)

**Locally (Claude Code):** in attended use, permission prompts act as the natural approval gate. Once the run goes unattended, those prompts can't be answered — so either the agent proceeds under its configured permission mode, or a hook denies specific actions. A non-zero exit from a `PreToolUse` hook blocks the action before it executes; the `Stop`/`stop_hook_active` mechanism prevents the denial itself from spinning up more work in an infinite loop.

**Remotely (GitHub):** a scheduled or manually dispatched workflow reaches a job targeting a protected environment and pauses. GitHub notifies the required reviewers. Only after an approved reviewer signs off does the job continue; otherwise it waits. This is the documented "environment protection rules with required reviewers" behavior. The approval happens at the environment boundary — before the deploy/run step executes.

## Practical example

Scenario: an agent writes a dependency-upgrade PR on a schedule, and a human approves anything that reaches production.

1. Keep the scheduled agent's blast radius small: it works in a branch and opens a PR. It does not merge, and it does not deploy.
2. Configure a Claude Code `PreToolUse` hook that denies (non-zero exit) any command matching a dangerous pattern (e.g., force-push, direct deploys) — so even an unattended run can't cross those lines.
3. On the GitHub side, create a `production` environment with required reviewers. The deploy workflow targets that environment, so every deployment pauses for a human sign-off — even if the change arrived via a fully automated pipeline.
4. If you are tempted to run Claude Code with prompts skipped to make unattended runs smoother: treat that as the higher-risk mode it is, and only accept it alongside compensating gates like the hook above plus the GitHub environment review.

## Explanation guidance

### Essential

- The core question before any unattended run: *who says yes to consequential actions?* In attended use, it's the default Claude Code permission prompt. Unattended, you must design the yes.
- Claude Code asks by default; explicit flags exist to skip prompts. That's real and documented, and it is explicitly the higher-risk mode — not the default recommendation for unattended loops.
- GitHub environment protection rules with required reviewers are the documented way to put a human back in the loop at deploy time, regardless of who (or what) triggered the workflow.
- Agent lifecycle hooks (e.g., `PreToolUse` returning non-zero) are how Claude Code teams enforce guardrails during semi-autonomous runs.

### Experienced-user note

- Distinguish "gate the action" from "gate the run." A `PreToolUse` hook gates individual agent actions; a GitHub environment review gates a whole deploy step. Mature setups use both.
- Remember the `Stop` / `stop_hook_active` mechanism: hooks that block actions must not themselves re-trigger agent work, or you've built the infinite feedback loop the guardrail was meant to prevent.
- Approval gates interact with kill-switch discipline: cancelling an active run and disabling its future trigger are separate operations in GitHub Actions — an approval gate doesn't replace either.

### Optional deeper context

- The skip-permission-prompt mode is a deliberate trade-off: smoothness and autonomy versus blast radius. Teams that use it typically pair it with scoped hooks, short `timeout-minutes` on workflow jobs (documented default around 360 minutes), iteration caps like a `--max-turns`-style limit in headless mode, and concurrency controls (`concurrency` with `cancel-in-progress`, or `flock` for plain cron) so that an unattended run can neither run too long nor overlap with itself.
- Approval gates are one part of idempotent, bounded autonomy: design the task so running it twice is safe (the same principle behind HTTP's idempotent methods, RFC 9110 §9.2.2), and gate the parts that aren't.
- Cross-tool caution: this page's claims are verified for Claude Code and GitHub Actions. Whether Cursor or Codex-CLI offer equivalent named permission-prompting or environment-review features is unverified — do not assume parity; check each tool's own documentation.

## Cautions and common failures

- **Running unattended with prompts skipped by default.** Skipping permission prompts is real but higher-risk; doing it merely because the loop "keeps stopping to ask" defeats the gate.
- **Assuming a schedule implies a review.** A GitHub Actions scheduled workflow runs on its trigger; it only pauses if it targets a protected environment with required reviewers. No environment protection = no human gate.
- **Forgetting scheduled workflow caveats.** GitHub Actions scheduled runs can be delayed or dropped under load, run only on the default branch, and are auto-disabled after 60 days of repository inactivity — plan your gate around the fact that timing is approximate.
- **Hooks as guardrails misfiring into loops.** A blocking hook that triggers more agent work recreates the runaway-loop problem; that's exactly what `Stop`/`stop_hook_active` exists to prevent.
- **Unbounded unattended runs.** Pair any unattended loop with `timeout-minutes` (GitHub Actions) and iteration caps (headless Claude Code) so a run that never completes can't consume unlimited billable minutes or tokens unobserved.
- **Assuming feature parity across tools.** Whether Cursor or Codex-CLI have equivalent permission modes or environment-review features is unverified in this module's research.

## Related capabilities

- headless-mode (the prerequisite building block for any unattended loop/hook/schedule)
- loops (repeat-until-done agent runs that gates should bound)
- hooks (lifecycle events where guardrails and approvals are enforced)
- scheduling (cron-style and recurring runs that need approval gates downstream)
- run-safety-and-kill-switches (concurrency, timeouts, and stopping/disabling runs)

## Official sources

- https://code.claude.com/docs/en/hooks
- https://docs.github.com/
- https://git-scm.com/docs/githooks

## Provenance

Grounded in this module's session research: Claude Code's default permission-prompting behavior and its documented hooks system (`PreToolUse` deny via non-zero exit; `Stop`/`stop_hook_active` loop prevention; headless `claude -p` mode) per code.claude.com/docs; GitHub's environment protection rules with required reviewers, scheduled-workflow caveats, `workflow_dispatch`, `concurrency`, and `timeout-minutes` per docs.github.com; git hooks per git-scm.com. Cross-tool feature-parity claims for Cursor and Codex-CLI are explicitly unverified and flagged as such. Safety framing (gates, bounding runaway runs, idempotency anchored in RFC 9110 §9.2.2) reflects general engineering practice with official anchors.