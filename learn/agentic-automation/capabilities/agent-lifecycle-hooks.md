---
title: Agent lifecycle hooks (PreToolUse/PostToolUse/Stop)
module_id: agentic-automation
capabilities:
  - agent-lifecycle-hooks
context7_library: /websites/platform_claude_en
context7_queries:
  - How do Claude Code hooks fire scripts on lifecycle events like PreToolUse and Stop?
  - How can a hook return a non-zero exit code to block an agent action?
  - What does the stop_hook_active field do to prevent infinite hook loops?
  - How do agent lifecycle hooks differ from git hooks?
official_sources:
  - https://code.claude.com/docs/en/hooks
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

Agent lifecycle hooks are scripts that run automatically when an AI coding agent reaches a specific point in its own workflow -- not when a git operation happens. Claude Code has a real, documented hooks system (source: code.claude.com/docs/en/hooks) in which scripts fire on agent lifecycle events such as `PreToolUse`, `PostToolUse`, `Stop`, `Notification`, and `SessionStart`.

This is deliberately distinct from git hooks. Git hooks (pre-commit, commit-msg, pre-receive, etc., documented at git-scm.com/docs/githooks) fire around git operations like commits and pushes. Agent lifecycle hooks fire around the agent's own actions -- before or after it uses a tool, when it finishes a turn, when it needs your attention, or when a session starts. The two systems can be used together, but they answer different questions: a git hook guards the repository's history; a lifecycle hook guards the agent's behavior.

A hook is one of three distinct ways to trigger repeated or automated agent work, alongside a loop (repeat until a condition is met) and a schedule (run at a future time or recurring cadence). A hook is event-driven: nothing repeats on a timer; the script fires whenever its named event occurs.

## When it is useful

- You want the agent to run semi-autonomously but with guardrails -- for example, denying certain tool calls before they execute.
- You want automatic checks to run after every tool use (e.g. lint or format the file the agent just touched), without asking each time.
- You want to log or be notified when a session starts, when the agent stops, or when it raises a notification.
- You want to enforce team policy mechanically rather than by prompt instructions, which the agent might not follow reliably.

## Prerequisites

- Claude Code installed and runnable, ideally familiar with its headless/programmatic mode (`claude -p`), since unattended automation of any kind presupposes non-interactive operation.
- Basic scripting ability: hooks are scripts, so you need to be comfortable writing and running a small shell script or program.
- Understanding that hooks are a configuration mechanism on the machine or project where they are set up -- they are not, by themselves, version-controlled artifacts the way a committed file is.

## Current syntax

Per the Claude Code hooks documentation, hooks are configured per event type. The documented lifecycle events include:

- `PreToolUse` -- fires before the agent uses a tool; this is the natural place to allow, deny, or modify an action.
- `PostToolUse` -- fires after a tool completes; useful for checks or follow-up processing of what the tool did.
- `Stop` -- fires when the agent finishes its turn.
- `Notification` -- fires when Claude Code sends a notification (e.g. needs attention or permission).
- `SessionStart` -- fires when a session begins.

The key behavioral rule: a hook script can return a non-zero exit code to deny or block the agent action it is attached to. That exit code is the enforcement mechanism, not a prompt or suggestion.

A related, documented field is `stop_hook_active`, associated with the `Stop` event, which exists specifically to prevent a Stop hook from re-triggering more agent work in an infinite feedback loop (agent stops → hook restarts it → agent stops again → ...).

## What happens (local and remote)

Locally: when the configured event fires, Claude Code invokes your script and inspects its result. If the hook exits non-zero on a `PreToolUse` event, the tool call is denied before it runs. On `PostToolUse`, the tool has already run, so the hook can react but not prevent that specific invocation. On `Stop`, the hook fires as the agent's turn ends, and the `stop_hook_active` mechanism keeps the hook from indefinitely re-launching agent work.

Remotely/server-side: lifecycle hooks are agent-machine constructs; there is no remote enforcement layer analogous to git's server-side hooks (pre-receive, update) that reject a push. If you need a server-side gate for a repository, that is git's server-side hook territory, not agent lifecycle hooks. If you need team-wide reproducibility of agent hooks, you must distribute the hook configuration yourself (for example, by committing it to the repository and having teammates install it) -- analogously to how git users share hooks via `core.hooksPath` or the pre-commit framework, though the Claude Code hooks config itself is a distinct artifact.

## Practical example

Scenario: let the agent work semi-autonomously, but block any tool call you consider dangerous, and log when it finishes.

1. Configure a `PreToolUse` hook whose script inspects the tool invocation Claude Code passes it. If the tool call matches something your team forbids, the script exits non-zero -- Claude Code then denies the tool call, and the agent sees that the action was blocked. Otherwise it exits zero and the action proceeds.
2. Configure a `PostToolUse` hook that, say, runs a formatter or writes a log line recording which tool ran.
3. Configure a `Stop` hook to post a message or write a summary when the agent's turn ends. Be aware of `stop_hook_active`: if your Stop hook would trigger further agent work, that field is the documented mechanism that prevents the resulting infinite loop.

The result: the agent keeps working with minimal interruptions, but every tool call passes your gate first, and you have an audit trail of its activity.

## Explanation guidance

### Essential

- Lifecycle hooks fire on the agent's events (before/after tool use, on stop, on session start), not on git operations -- that's the core distinction from git hooks.
- The enforcement primitive is a non-zero exit code: a `PreToolUse` hook that exits non-zero blocks the action. This is how teams give an agent autonomy plus guardrails.
- Hook output is mechanical, not advisory -- the agent cannot talk its way past a denied tool call.
- Hooks live in agent/tool configuration and are not version-controlled by default, so a team must deliberately share them if they want consistent behavior across machines.

### Experienced-user note

- Distinguish deny-before (`PreToolUse`) from react-after (`PostToolUse`); only `PreToolUse` can prevent an action, so high-risk blocking belongs there.
- If you write a `Stop` hook that starts new agent work, you are creating a loop by construction -- that is exactly why `stop_hook_active` exists. Design Stop hooks to observe or notify, not to re-launch work, unless you have a bounded, deliberate reason.
- If you also use git hooks, keep the responsibilities straight: a pre-commit git hook guards what enters history; a `PreToolUse` agent hook guards what the agent does. They can disagree with each other by design.
- Cross-tool caution: whether other agents (e.g. Cursor, Codex-CLI) have an equivalent, named lifecycle-hooks system is unverified in this module's research -- do not assume parity; scope claims to Claude Code unless you have verified otherwise.

### Optional deeper context

- Hooks sit on the event axis of the three trigger types in this module: loops repeat until a condition is met, schedules fire on a clock, hooks fire on an event. Combining hooks with headless mode (`claude -p`) and a scheduler (e.g. a GitHub Actions `on.schedule` workflow) is how event-guarded, unattended agent pipelines get built.
- When hooks let an agent run with fewer permission prompts, revisit the permission-mode question: Claude Code asks for permission by default, and flags exist to skip prompts -- a higher-risk mode that becomes more consequential once hooks are the only guardrail. For GitHub-side automation, environment protection rules with required reviewers are the analogous gate.
- If multiple unattended agent runs can overlap on the same repository, guard against concurrency damage with GitHub Actions' `concurrency` syntax or `flock` for plain cron, and bound runaway work with `timeout-minutes` or `--max-turns`-style caps.

## Cautions and common failures

- Confusing lifecycle hooks with git hooks: they are different systems with different event models. A git `pre-commit` hook will not fire because the agent used a tool, and a `PreToolUse` hook will not fire because you ran `git commit`.
- Relying on `PostToolUse` to prevent damage: by the time it fires, the tool already ran. Prevention belongs in `PreToolUse`.
- Infinite feedback loops: a `Stop` hook that re-triggers agent work can loop forever. The documented `stop_hook_active` mechanism exists for this; be deliberate about whether your Stop hook should trigger anything at all.
- Assuming hooks are shared automatically: hook configuration is machine-local by default; teammates without the config get different (possibly permissive) behavior.
- Skipping the human approval gate: hooks are guardrails, not substitutes for reviewing what permission mode the agent runs in before enabling unattended operation.
- Unverified parity claims: do not assert that Cursor or Codex-CLI offer equivalent hooks; that comparison is unverified here.

## Related capabilities

- Headless/programmatic invocation (`claude -p`) -- the prerequisite for any unattended loop, hook, or schedule.
- Git hooks (client-side and server-side) -- the repository-operation counterpart to agent lifecycle hooks.
- Scheduled workflows and `workflow_dispatch` -- time-based triggers, to be contrasted with event-based hooks.
- Permission modes and approval gates -- the human-side guardrails that complement hook enforcement.

## Official sources

- Claude Code hooks: https://code.claude.com/docs/en/hooks
- Git hooks (for the distinction): https://git-scm.com/docs/githooks
- Claude Code documentation index: https://code.claude.com/docs

## Provenance

Grounded in this module's session research: the Claude Code hooks system, its documented event types (PreToolUse, PostToolUse, Stop, Notification, SessionStart), non-zero-exit-code denial, and the `stop_hook_active` loop-guard all come from code.claude.com/docs/en/hooks. The git-hooks contrast comes from git-scm.com/docs/githooks. Feature parity for Cursor and Codex-CLI is explicitly unverified and flagged as such. No facts beyond these grounding sources have been asserted.