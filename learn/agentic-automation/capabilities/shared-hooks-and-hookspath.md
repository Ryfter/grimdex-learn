---
title: Sharing hooks across a team (core.hooksPath)
module_id: agentic-automation
capabilities:
  - shared-hooks-and-hookspath
context7_library: /websites/git-scm
context7_queries:
  - "Why don't my git hooks get cloned to other machines?"
  - "How do I make git hooks shared and version-controlled with core.hooksPath?"
  - "How does the pre-commit framework keep team hooks reproducible?"
official_sources:
  - https://git-scm.com/docs/githooks
  - https://pre-commit.com
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

Git hooks (pre-commit, commit-msg, pre-receive, etc.) are scripts that run automatically around git operations and can block them -- for example, a failing pre-commit hook aborts the commit. Crucially, hooks are **not version-controlled by default**: they live in `.git/hooks`, which is machine-local. When you clone a repository, you do not get anyone else's hooks. This page covers the two real, documented ways teams make hooks shareable and reproducible:

1. **`core.hooksPath`** -- a git configuration setting that tells git to look for hooks in a directory of your choosing (typically one that *is* version-controlled) instead of the default `.git/hooks`.
2. **The pre-commit framework** (pre-commit.com) -- a tool that manages hooks from a declarative config file (`.pre-commit-config.yaml`) committed to the repo, so every teammate installs the same set of hooks.

## When it is useful

- A team wants everyone's local `pre-commit` or `commit-msg` checks (linting, formatting, commit-message conventions) to be identical -- not "whatever each developer happened to set up."
- You want hook changes to be reviewed in pull requests like any other code, rather than living untracked on individual machines.
- Onboarding: a new clone should get working hooks with one setup step, not manual copying.
- When the repo later gains agent-driven automation (Claude Code lifecycle hooks, scheduled workflows), consistent client-side git hooks are one layer of the guardrails that keep both humans and semi-autonomous agents from committing things they shouldn't.

## Prerequisites

- Git installed locally; familiarity with basic commit and clone operations.
- For `core.hooksPath`: permission to change git config (local repo config is enough).
- For the pre-commit framework: Python available on the machine (the tool is distributed via pip and similar channels).

## Current syntax

`core.hooksPath` is a git config value pointing at a directory of hook scripts:

```bash
# inside the repository
mkdir -p githooks
# create/commit your hook scripts in githooks/, e.g. githooks/pre-commit
git config core.hooksPath githooks
```

After this, git looks for `pre-commit`, `commit-msg`, etc. in `githooks/` instead of `.git/hooks/`. Because `githooks/` is a normal tracked directory, hooks are now version-controlled. Each teammate (or a setup script / bootstrap step) runs the one-line config command after cloning.

With the pre-commit framework, hooks are declared in a committed config file:

```yaml
# .pre-commit-config.yaml (example shape; see pre-commit.com for exact keys)
repos:
  - repo: https://github.com/example/some-hook-repo
    rev: v1.0.0
    hooks:
      - id: some-hook-id
```

and installed with:

```bash
pip install pre-commit
pre-commit install
```

`pre-commit install` wires the framework into your git hooks (using the hooksPath mechanism under the hood), and `pre-commit run --all-files` runs the declared hooks across the repo.

## What happens (local and remote)

- **Local:** git checks the configured hooks directory before/after operations. A hook script's exit code controls the outcome -- non-zero aborts the operation (a failing pre-commit hook stops the commit). With `core.hooksPath` pointed at a tracked directory, every clone that runs the config command gets the same hooks; with the pre-commit framework, `pre-commit install` sets this up automatically from the committed config file.
- **Remote:** client-side hooks do *not* protect the remote. A developer can bypass local hooks (e.g. with `git commit --no-verify`), or simply not have them installed. Server-side hooks (`pre-receive`, `update`) run on the remote when a push arrives and can reject it regardless of what happened locally -- which is why a push can be rejected even though the local commit succeeded. Shared client-side hooks are a convenience and a first guardrail; server-side enforcement is the backstop.

## Practical example

A team wants a `pre-commit` hook that blocks commits containing a marker string, and wants it shared:

1. Create `githooks/pre-commit` in the repo, make it executable (`chmod +x githooks/pre-commit`), and commit it.
2. Each developer runs `git config core.hooksPath githooks` once after cloning (or a bootstrap script in the README does it).
3. Now every commit runs the shared script; if it exits non-zero, the commit is aborted locally.
4. Separately, the hosting server has a `pre-receive` hook that performs the same check server-side, so even a `--no-verify` commit can be rejected at push time.

Alternatively with the pre-commit framework: commit `.pre-commit-config.yaml`, have each developer run `pre-commit install` once, and the same hooks run for everyone at the pinned revision -- upgrades are a reviewed change to the config file, not a silent local edit.

## Explanation guidance

### Essential

- Git hooks are real, documented features (git-scm.com/docs/githooks) that run automatically around git operations and can block them.
- Hooks live in `.git/hooks`, which is machine-local and **not** version-controlled -- a fresh clone has no hooks. This surprises almost every beginner.
- `core.hooksPath` redirects git to a hooks directory you choose; pointing it at a tracked directory makes hooks shareable. It still requires a one-time per-machine config step after cloning.
- The pre-commit framework (pre-commit.com) manages hooks from a committed `.pre-commit-config.yaml`, so the hook set is pinned, reviewed, and reproducible across the team.
- Local hooks can be skipped or missing; server-side hooks (`pre-receive`, `update`) are the enforcement point on the remote.
- Hook exit codes are the control mechanism: non-zero blocks the git operation.

### Experienced-user note

- `core.hooksPath` takes precedence over `.git/hooks`; the pre-commit framework's `pre-commit install` uses this same mechanism, so mixing manually managed hooksPath setups with the framework requires some care.
- Hook scripts are plain executables -- anything that can exit non-zero can be a hook, which makes this a natural place to wrap agent tooling (e.g. rejecting commits that contain secrets before an unattended loop ever pushes).
- Distinct from agent lifecycle hooks: Claude Code has its own documented hooks system (PreToolUse, PostToolUse, Stop, etc.) that is separate from git hooks. Whether other agent tools such as Cursor or Codex-CLI offer equivalent lifecycle-hook features is unverified here -- scope that comparison explicitly or avoid it.

### Optional deeper context

- The same "make it reproducible" instinct generalizes: client-side hooks are one guardrail layer; GitHub environment protection rules with required reviewers are the analogous remote-side gate for deployments driven by automation.
- If hooks run agent tools, remember that unattended agent runs consume real resources (tokens, CI minutes) and should have iteration caps (`--max-turns`-style limits in Claude Code headless mode, `timeout-minutes` in GitHub Actions) -- bounds that matter just as much for a hook that triggers heavy work as for a scheduled loop.

## Cautions and common failures

- **Hooks don't travel with the clone.** The single most common failure: one developer has hooks working, everyone else doesn't. Fix by committing the hooks (via `core.hooksPath`) or a `.pre-commit-config.yaml` plus a documented `pre-commit install` step.
- **`core.hooksPath` is per-machine config.** Setting it locally does not set it for teammates; each clone needs the config step (or a bootstrap script).
- **Executable bit.** Hook scripts must be executable; a committed script without the executable bit set will not run.
- **Silent bypass.** `git commit --no-verify` skips pre-commit/commit-msg hooks, and uninstalled hooks skip them too -- never treat client-side hooks as a security boundary. Use server-side hooks for enforcement.
- **Framework vs. raw scripts.** If `core.hooksPath` is pointed somewhere the pre-commit framework didn't set up, `pre-commit install` may not take effect as expected; pick one ownership model for the hooks directory.

## Related capabilities

- agent-loop-vs-code-loop (agentic loop vs. programming loop distinction)
- claude-code-lifecycle-hooks (Claude Code's separate agent lifecycle hooks system)
- scheduling-basics (cron / GitHub Actions scheduling, a different trigger type)
- unattended-run-safety (approval gates, concurrency, timeouts, kill switches)

## Official sources

- https://git-scm.com/docs/githooks -- git hooks documentation (hook types, `.git/hooks` location, blocking behavior)
- https://pre-commit.com -- pre-commit framework documentation (config file and install workflow)

## Provenance

- Grounded in git-scm.com/docs/githooks (hooks are real, documented, machine-local, can block operations; server-side `pre-receive`/`update` exist) and pre-commit.com (documented framework for shareable, reproducible team hooks), per this module's research.
- Claude Code lifecycle-hook details sourced from code.claude.com/docs/en/hooks and scoped accordingly; no parity claims are made for Cursor or Codex-CLI, as that is explicitly unverified for this module.
- No invented commands, flags, or statistics beyond the grounding facts; exact config-file key shapes and installation steps should be confirmed against the official sources above.
- Status: current as of 2026-09-20; claim class: everyday; safety class: normal.