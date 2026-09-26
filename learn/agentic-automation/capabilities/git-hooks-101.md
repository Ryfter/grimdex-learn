---
title: Git hooks 101 (client-side)
module_id: agentic-automation
capabilities:
  - git-hooks-101
context7_library: /websites/git-scm
context7_queries:
  - What client-side git hooks exist and when does git run them?
  - How can a pre-commit or commit-msg hook block a git operation?
  - Why are git hooks not version-controlled, and how can teams share them?
official_sources:
  - https://git-scm.com/docs/githooks
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

Git hooks are real, documented git features: scripts that git runs automatically around git operations. Client-side examples include `pre-commit` (runs before a commit is created) and `commit-msg` (runs with the commit message before the commit completes). A hook can **block** the git operation: if a `pre-commit` hook exits with a failure, the commit is aborted. Source: git-scm.com/docs/githooks.

Hooks are distinct from both agent "loops" (act → observe → decide, repeat) and agent lifecycle hooks (Claude Code's own documented hooks system) — a git hook is simply a script triggered by a git event on your machine.

## When it is useful

- Enforcing checks before a commit lands locally: linting, formatting, or running tests.
- Validating commit message conventions via `commit-msg`.
- Adding a guardrail around agent-assisted commits: a `pre-commit` hook runs even when a commit is made by an unattended or semi-autonomous agent, since the hook fires at the git layer, not the tool layer.

## Prerequisites

- A git repository (hooks operate on git operations).
- Familiarity with running shell scripts and reading exit codes.
- Understanding that a failing hook aborts the operation — a hook is an enforcement point, not just a notification.

## Current syntax

Hooks live in `.git/hooks/` and are plain executables. Typical names:

- `pre-commit` — runs before the commit is created; a non-zero exit aborts the commit.
- `commit-msg` — receives the path to the commit message file; a non-zero exit aborts the commit.

They are **not version-controlled by default** (they live inside `.git/`, which git does not track). Two real, documented ways to make hooks shareable across a team:

1. `core.hooksPath` — a git configuration setting pointing git at a different hooks directory, e.g. one checked into the repo.
2. The **pre-commit framework** (pre-commit.com) — a real, documented tool for managing and sharing hooks reproducibly.

## What happens (local and remote)

- **Local (client-side):** when you run `git commit`, git looks in the hooks directory and runs the matching hook script automatically. A failing hook (non-zero exit) stops the operation before it completes — for `pre-commit`, the commit never happens; for `commit-msg`, the commit message is rejected.
- **Remote (server-side):** git servers also have hooks, notably `pre-receive` and `update`. These explain why a **push can be rejected by the remote** even though your local commit succeeded — the server ran its own hooks and refused the update.

## Practical example

A minimal `pre-commit` hook that blocks commits containing a leftover marker:

```sh
#!/bin/sh
# .git/hooks/pre-commit
if git diff --cached | grep -q "TODO-FIXME-BLOCKER"; then
  echo "Commit blocked: leftover marker found." >&2
  exit 1
fi
```

Make it executable (`chmod +x .git/hooks/pre-commit`). Now `git commit` runs it automatically; a non-zero exit aborts the commit. To share this hook with a team, move it into a tracked directory and set `core.hooksPath` to that directory, or adopt the pre-commit framework so every teammate installs the same hooks.

## Explanation guidance

### Essential

- Hooks are scripts git runs automatically around git events; they are a documented git feature, not an agent-tool feature.
- A failing hook **blocks** the operation — that is the point, and it's why hooks work as guardrails for agent-made commits too.
- Hooks are machine-local by default (in `.git/hooks/`); use `core.hooksPath` or the pre-commit framework to share them.
- Push rejections you didn't expect locally are often server-side hooks (`pre-receive`, `update`) firing on the remote.

### Experienced-user note

- A client-side hook only runs on the machine where the git operation happens. It cannot be relied on as a guarantee for commits made elsewhere; server-side hooks are the enforcement point when you control the server.
- When an agent (e.g. Claude Code) makes commits, client-side hooks still run — the hook executes at the git layer. This makes pre-commit a useful complement to agent-level guardrails rather than a replacement for them. (Whether other agent tools like Cursor or Codex-CLI expose equivalent hook systems is unverified; the git-layer behavior above is what's documented.)

### Optional deeper context

- Hooks generalize beyond commits: git documents hooks around many operations (git-scm.com/docs/githooks lists them).
- The pattern "an event triggers a script, and the script can veto the action" recurs across tooling — Claude Code's agent lifecycle hooks (PreToolUse, PostToolUse, Stop, etc.) work the same way for agent actions, with a non-zero exit denying the action. The concepts transfer, but the hook systems are distinct: git hooks fire on git events; agent hooks fire on agent lifecycle events.

## Cautions and common failures

- **"My hook didn't run."** Most often the file isn't executable, or the hook name doesn't match what git expects. Verify permissions and the exact filename against the githooks documentation.
- **"My teammate doesn't get my hook."** Expected: hooks in `.git/hooks/` are not version-controlled. Use `core.hooksPath` or the pre-commit framework to distribute them.
- **"The commit worked locally but the push was rejected."** That's server-side hooking (`pre-receive`/`update`) on the remote — a different hook, running elsewhere, with its own rules.
- **A hook that fails for the wrong reason can block an agent mid-task.** If you run a coding agent unattended, a broken pre-commit hook will abort its commits; test hooks deliberately before combining them with autonomous runs.

## Related capabilities

- Agentic loops, agent lifecycle hooks, and scheduling (sibling capabilities in this module).
- Headless/non-interactive agent runs — relevant when combining hooks with unattended commits.
- Server-side hooks and push-time enforcement.

## Official sources

- https://git-scm.com/docs/githooks — git's documentation of hook types, locations, and behavior.
- https://pre-commit.com — the pre-commit framework for managing and sharing hooks.

## Provenance

Grounded in git's official hook documentation (git-scm.com/docs/githooks) and the documented pre-commit framework (pre-commit.com), as established in this session's Context7/fleet research for the agentic-automation module. Claims are scoped to documented git behavior; any cross-tool comparison involving agent-tool hook systems is explicitly flagged as unverified where it appears.