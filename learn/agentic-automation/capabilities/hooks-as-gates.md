---
title: Hooks as gates -- allowing and blocking agent actions
module_id: agentic-automation
capabilities:
  - hooks-as-gates
context7_library: /websites/platform_claude_en
context7_queries:
  - How does a Claude Code hook block or deny an agent action?
  - What lifecycle events can run hooks, such as PreToolUse and PostToolUse?
  - How do hook exit codes control whether an agent's action is allowed?
  - How do agent hooks differ from git hooks?
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

A hook is a script that runs automatically on a specific event. In the context of
agentic automation, the useful trick is that a hook can act as a **gate**: when the
agent tries to do something, a hook runs first, and if that hook exits with a
non-zero exit code, the agent's action is denied or blocked.

This is distinct from a git hook, even though the word is the same. Git hooks
(pre-commit, commit-msg, etc., documented at git-scm.com) run automatically around
git operations and can block them -- for example, a failing pre-commit hook aborts
the commit. Claude Code has its own, separate, documented hooks system: scripts
that run on agent lifecycle events such as `PreToolUse`, `PostToolUse`, `Stop`,
`Notification`, and `SessionStart`. On that system, a non-zero exit code from a hook
denies the agent's action.

The gate pattern is what lets a team run an agent semi-autonomously: the agent can
keep working on its own, but specific dangerous or out-of-policy actions are
automatically vetoed by a script rather than by a human sitting at the terminal.

## When it is useful

- You want an agent to run without attending it, but you do not want it to be able
  to do everything it could in an interactive session.
- You have a small set of clear rules ("never touch this directory", "always run
  this check before committing") that are easier to enforce mechanically than by
  prompt instructions alone.
- You want enforcement that is consistent: a prompt instruction can be ignored by
  the model; a gate that exits non-zero cannot be.

## Prerequisites

- Headless / non-interactive mode is the prerequisite building block for unattended
  agent work generally: you cannot hook an agent that requires an attended terminal
  session. Claude Code has a real, documented headless mode (`claude -p`,
  programmatic invocation, per code.claude.com/docs).
- Basic comfort with shell scripts and exit codes: a gate is just a script whose
  exit code carries the decision.
- Understanding what permission mode your agent runs in. Claude Code asks for
  permission by default; explicit flags exist to skip permission prompts, which is
  a real but higher-risk mode. Hooks-as-gates are one way to retain guardrails when
  prompts are not being shown.

## Current syntax

For Claude Code (per code.claude.com/docs/en/hooks), the relevant pieces are:

- **Lifecycle events**: hooks are attached to named events such as `PreToolUse`,
  `PostToolUse`, `Stop`, `Notification`, and `SessionStart`. A gate hook is
  typically attached to `PreToolUse`, so it runs before the agent's tool call
  executes.
- **Exit codes**: a hook returning a non-zero exit code denies/blocks the agent
  action. Exit zero means "allow / no objection".
- **Guarding the Stop event**: the `Stop` event and a `stop_hook_active` field
  exist specifically to prevent a hook from re-triggering more agent work in an
  infinite feedback loop. If your gate logic touches `Stop`, you must account for
  this mechanism.

(Exact configuration file syntax for registering hooks is documented at the
official source below; this page focuses on the gate concept and mechanism.)

For comparison, git's own hook system works on the same exit-code principle:
hooks like `pre-commit` live in `.git/hooks` (machine-local, not version-controlled
by default), and a non-zero exit aborts the operation. `core.hooksPath` and the
pre-commit framework (pre-commit.com) are documented ways to make git hooks
shareable across a team.

Whether Cursor or Codex-CLI have equivalent named hook features matching Claude
Code's hooks system is **unverified** as of this writing -- do not assume
cross-tool parity.

## What happens (local and remote)

Locally: the agent attempts an action (say, a tool call). If a `PreToolUse` hook is
registered for that tool, the hook script runs first. If it exits zero, the action
proceeds. If it exits non-zero, the action is denied and the agent receives the
rejection -- it can then decide how to proceed (try a different approach, or give
up). The gate fires every time the matching event occurs, without a human in the
loop.

Note the analogous behavior in git: a failing `pre-commit` hook aborts the commit
locally, and server-side hooks (`pre-receive`, `update`) can reject a push remotely
even though the local commit succeeded. In both systems, the pattern is the same --
a script's exit decision blocks the operation automatically.

## Practical example

A team wants Claude Code to fix a failing test suite overnight, headlessly, but
never wants it to force-push or modify CI configuration. They register a
`PreToolUse` hook that inspects the command the agent is about to run. If the
command matches a forbidden pattern (e.g. a force-push or an edit to the CI
workflow file), the script prints a short reason to stderr and exits with a
non-zero code; otherwise it exits zero.

Result: the agent works autonomously for hours, and every attempt to cross the
guardrail is denied at the moment it happens. The agent sees the denial and adapts
-- it does not silently break the rule. The team reviews the transcript in the
morning and sees exactly where the gate fired.

The same shape applies to git: a team-shared pre-commit hook (distributed via
`core.hooksPath` or pre-commit) blocks any commit that fails a lint or secret scan,
whether the commit was made by a human or by an agent.

## Explanation guidance

### Essential

- A hook is a script that runs automatically on an event; a *gate* is a hook whose
  exit code decides whether the action is allowed.
- Non-zero exit code = deny/block. That single mechanism is the whole trick.
- Claude Code's agent lifecycle hooks (`PreToolUse`, `PostToolUse`, `Stop`,
  `Notification`, `SessionStart`) are a separate system from git hooks, even though
  both use exit codes to block.
- Gates are how semi-autonomous runs stay safe: the human sets the policy up front,
  and the script enforces it on every event.

### Experienced-user note

- Distinguish *prompt-level* guardrails ("please never do X") from *mechanical*
  guardrails (a hook that exits non-zero). Only the second is reliably enforced;
  use hooks for anything that must not happen.
- If you attach gate logic to the `Stop` event, be aware of `stop_hook_active` --
  it exists precisely to stop a hook from re-triggering more agent work forever.
  Ignoring it is how people accidentally build infinite feedback loops.
- For git hooks, remember they are not version-controlled by default; teams that
  rely on hooks-as-gates in version control should use `core.hooksPath` or the
  pre-commit framework so the gates actually exist on every machine.

### Optional deeper context

- The same "exit code as decision" pattern appears across the toolchain: git
  client-side hooks (pre-commit, commit-msg), git server-side hooks (pre-receive,
  update, which is why a push can be rejected remotely after a successful local
  commit), and Claude Code lifecycle hooks. Learning it once transfers.
- Gates pair naturally with other unattended-run safety measures: bounding run
  length (GitHub Actions `timeout-minutes`, Claude Code's `--max-turns`-style cap),
  preventing overlapping runs (GitHub Actions `concurrency` groups, `flock` for
  cron), and human approval gates (Claude Code's default permission prompting;
  GitHub environment protection rules with required reviewers). A hook gate is one
  layer, not the whole defense.
- How these hook mechanisms map onto other coding agents (Cursor, Codex-CLI) is
  unverified here; if you teach a cross-tool comparison, flag it as such rather
  than asserting parity.

## Cautions and common failures

- **Prompt instructions are not gates.** If a rule matters, enforce it with a hook
  that exits non-zero, not with a paragraph in the system prompt.
- **Confusing the two hook systems.** Git hooks fire on git operations; Claude Code
  hooks fire on agent lifecycle events. A `pre-commit` script will not run when the
  agent calls an arbitrary tool, and a `PreToolUse` hook will not fire on a plain
  `git commit` outside the agent.
- **Hooks are machine-local by default in git.** A gate that exists only in your
  `.git/hooks` does not protect teammates or CI. Distribute via `core.hooksPath`
  or pre-commit.
- **Infinite loops via Stop hooks.** A hook that reacts to `Stop` by triggering
  more agent work can loop forever; the documented `stop_hook_active` mechanism is
  there to prevent this -- understand it before writing Stop hooks.
- **Gates are not a substitute for a human approval gate before enabling
  unattended runs.** Decide the permission mode deliberately; skipping permission
  prompts is a real but higher-risk mode, and hook gates should be layered on top
  of a conscious decision, not used to avoid one.

## Related capabilities

- Headless / non-interactive agent mode (`claude -p`) -- the prerequisite for any
  unattended loop, hook, or schedule.
- Agent loops (act → observe → decide → repeat) -- gates bound what a loop may do.
- Scheduling with cron and GitHub Actions scheduled workflows -- gates apply to
  scheduled runs the same as manual ones.
- Unattended-run safety: timeout-minutes / --max-turns caps, concurrency controls,
  and approval gates.

## Official sources

- https://code.claude.com/docs/en/hooks (Claude Code hooks: lifecycle events,
  exit codes, `stop_hook_active`)
- https://git-scm.com/docs/githooks (git hooks: pre-commit, pre-receive, exit-code
  blocking)
- https://code.claude.com/docs (Claude Code headless mode, `claude -p`)

## Provenance

Grounded in official documentation: Claude Code hooks system
(code.claude.com/docs/en/hooks) for lifecycle events, exit-code denial, and
`stop_hook_active`; git-scm.com/docs/githooks for git's client- and server-side
hooks; code.claude.com/docs for headless mode. Cross-tool feature parity claims
for Cursor and Codex-CLI are explicitly unverified and flagged as such in this
page. Content class: everyday practice guidance anchored to official sources;
last checked 2026-09-20.