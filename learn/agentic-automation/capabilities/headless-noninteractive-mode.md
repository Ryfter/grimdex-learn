---
title: "Headless mode: the building block of automation"
module_id: agentic-automation
capabilities:
  - headless-noninteractive-mode
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I run Claude Code non-interactively / programmatically?
  - How does headless mode relate to loops, hooks, and scheduled runs?
  - What flags bound an unattended headless run?
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

Headless mode (also called non-interactive or programmatic invocation) is a way to run an AI coding agent without a human sitting at a terminal session. In Claude Code, this is a real, documented capability: `claude -p` invokes the agent programmatically, so the agent can be started and finished by a script rather than by a person typing at a prompt.

## When it is useful

Anytime you want the agent to do work on your behalf without attending the session. But its most important role is as a prerequisite: an agent loop (repeat until done), a hook (run on an event), or a schedule (run at a future or recurring time) all require the agent to be startable and steerable by machine. You cannot loop, hook, or schedule an agent that requires an attended terminal session. Headless mode is therefore the foundation every other automation capability in this module builds on.

## Prerequisites

- An installed Claude Code CLI.
- Basic familiarity with running commands from a shell or script.
- An understanding of which permission mode the agent will run in when nobody is present to approve actions (see Cautions below).
- For downstream automation (loops, hooks, schedules): a task whose outcome is machine-checkable, e.g. "run until tests pass."

## Current syntax

Claude Code's documented headless/programmatic invocation is:

```
claude -p "<prompt or task description>"
```

Because this is a programmatic invocation, it can be called from shell scripts, git hooks, CI workflows, or schedulers — exactly the places where loops, hooks, and schedules live.

## What happens (local and remote)

Locally, the script (or hook, or scheduler) starts the agent, the agent performs its act → observe → decide → repeat cycle until it finishes or hits a bound, and exits, returning control to whatever invoked it. No terminal session needs to be attended. Remotely, the same pattern applies when the invocation happens inside a CI environment (e.g. GitHub Actions), where the run consumes real workflow-run minutes and the LLM consumes real tokens against real rate limits — precisely because nobody is watching the run live, resource usage still accrues and should be observable.

## Practical example

A minimal script that runs the agent headlessly and checks its result:

```bash
#!/usr/bin/env bash
claude -p "Fix the failing test in src/auth.test.ts, then run the test suite"
if [ $? -eq 0 ]; then
  echo "Agent task completed"
else
  echo "Agent run failed — investigate before automating further"
fi
```

Once this works reliably by hand, the same invocation is what you would place inside a loop ("run until tests pass"), a git hook, or a scheduled workflow. That progression — verify interactively first, then automate the same invocation — is the standard safe path.

## Explanation guidance

### Essential

- Headless mode is the gate: no loop, hook, or schedule is possible without it, because all three require the agent to run without an attended terminal.
- The distinction between an agentic loop (act → observe → decide → repeat until done) and a programming for/while loop matters here: headless mode removes the human from the "observe/decide" loop, so the machine must handle both.
- Claude Code's `claude -p` programmatic invocation is the concrete, documented mechanism; teach the concept first, the flag second.
- Before automating anything, the human should have run the task interactively at least once and confirmed the outcome is correct and checkable.

### Experienced-user note

- Headless runs inherit the permission mode they are configured with. Claude Code asks for permission by default; explicit flags exist to skip permission prompts, which is a real but higher-risk mode — appropriate only with guardrails in place (e.g. agent lifecycle hooks that can deny actions via non-zero exit codes).
- Claude Code's headless mode supports an iteration cap (a `--max-turns`-style bound), which is essential when converting a one-off headless run into a loop, to prevent an unbounded run.
- Cross-tool caution: whether other agent CLIs (e.g. Cursor, Codex-CLI) offer equivalent, named headless/programmatic invocation features is not verified here. Scope claims about headless invocation to Claude Code unless you have independently confirmed a tool's own documentation.

### Optional deeper context

- Headless invocation is the seam where agent automation meets the rest of the tooling world: git hooks call scripts, cron calls scripts, GitHub Actions run scripts — and all of them can call `claude -p`. Understanding headless mode as "the scriptable entry point" makes the rest of the module's capabilities (loops, hooks, schedules, concurrency control, timeouts) concrete rather than abstract.
- The concept of bounding unattended work (iteration caps, timeouts) and designing idempotent tasks — work that is safe to re-run twice, anchored formally by HTTP's idempotent-methods concept in RFC 9110 §9.2.2 — becomes relevant the moment a headless run is placed inside a repeating or scheduled context.

## Cautions and common failures

- **Skipping the interactive-first step.** Automating a task headlessly before verifying it works attended is the most common beginner failure; you then have no baseline for what "done correctly" looks like.
- **Unbounded runs.** A headless run that never naturally completes will keep consuming tokens and (in CI) billed minutes. Use real, documented bounds: Claude Code's `--max-turns`-style iteration cap, and GitHub Actions' `timeout-minutes` (default around 360 minutes) when the headless run lives in a workflow.
- **Permission-mode surprises.** Skipping permission prompts is higher-risk; if nobody is watching, prefer guardrails such as lifecycle hooks that can deny actions, or (for GitHub) environment protection rules with required reviewers before unattended work touches sensitive resources.
- **Idempotency.** If a headless task might be re-run (retries, loops, schedules), design it so a second run is safe, not harmful.
- **Assuming other tools work the same.** Do not assume Cursor or Codex-CLI have equivalent headless/scheduling features matching Claude Code's or GitHub's — that parity is unverified; check the specific tool's documentation.

## Related capabilities

- agent-loops (repeat-until-done cycles built on headless invocation)
- git-hooks-and-agent-hooks (event-triggered runs calling the agent headlessly)
- scheduled-runs (cron / GitHub Actions scheduled invocations)
- unattended-run-safety (permission modes, timeouts, concurrency, kill switches)

## Official sources

- Claude Code hooks and programmatic use: https://code.claude.com/docs/en/hooks

## Provenance

Grounded in documented Claude Code headless/programmatic invocation (`claude -p`, code.claude.com/docs) and the module's earlier Context7/fleet research on the loop/hook/schedule model. Claims about headless invocation are scoped to Claude Code; feature parity for Cursor and Codex-CLI is explicitly unverified and flagged as such. Safety guidance (permission modes, iteration caps, timeouts, idempotency) anchored to real, documented mechanisms cited in the module's grounding facts (code.claude.com, docs.github.com, RFC 9110 §9.2.2). Drafted as practice guidance with official anchors; last verified 2026-09-20.