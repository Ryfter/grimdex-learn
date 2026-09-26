# Agentic automation: loops, hooks, and scheduling

This is a **Learn module**: essentials-depth explainers any Grimdex user can install to
learn while building. It is not course material — anything course-scented lives in
`course/`, never here.

## What this module is

- One page per capability in `capabilities/*.md`, each following the frozen D32 page
  contract (YAML front matter + eleven fixed sections).
- Sources, refresh rules, and provenance are documented in `source-registry.md`,
  `refresh-policy.md`, and `provenance.md`.
- Depth discipline: pages stop at what/why plus a bit of how, then link to official
  documentation.

## Content admission

Every page passes the content-admission test before it lands: useful without any
specific course or professor; public-ready from its first reviewed version; claims about
vendor behavior are version-stamped and source-linked; provenance is honest; the module
is removable via `learn/manifest.json`.

## Pages (20)

- `capabilities/agent-lifecycle-hooks.md` — Agent lifecycle hooks (PreToolUse/PostToolUse/Stop)
- `capabilities/agentic-loop-vs-code-loop.md` — An agentic "loop" is not a for/while loop
- `capabilities/cost-and-observability.md` — Cost and observability of unattended runs
- `capabilities/cron-five-fields.md` — Cron syntax in ten minutes
- `capabilities/git-hooks-101.md` — Git hooks 101 (client-side)
- `capabilities/give-every-loop-an-exit.md` — Give every loop an exit condition
- `capabilities/headless-noninteractive-mode.md` — Headless mode: the building block of automation
- `capabilities/hook-feedback-loop-risk.md` — Avoiding hooks that trigger themselves forever
- `capabilities/hooks-as-gates.md` — Hooks as gates -- allowing and blocking agent actions
- `capabilities/human-approval-gates.md` — Human approval gates before autonomy
- `capabilities/idempotency-safe-to-rerun.md` — Idempotency: designing tasks safe to run again
- `capabilities/loop-hook-schedule-triggers.md` — Hook, schedule, or loop: choosing the right trigger
- `capabilities/manual-one-off-triggers.md` — Manual and one-off triggers (workflow_dispatch)
- `capabilities/overlap-and-concurrency.md` — What happens when the next run starts before the last ends
- `capabilities/runaway-loop-and-timeouts.md` — Runaway-loop risk and timeouts
- `capabilities/schedule-reality-checks.md` — Scheduled does not mean exactly on time
- `capabilities/scheduled-workflows-github-actions.md` — Scheduled GitHub Actions (on.schedule)
- `capabilities/server-side-git-hooks.md` — Server-side git hooks
- `capabilities/shared-hooks-and-hookspath.md` — Sharing hooks across a team (core.hooksPath)
- `capabilities/the-kill-switch.md` — The kill switch: stopping a run vs. disabling its trigger

Each page lists its own prerequisites and related capabilities.
