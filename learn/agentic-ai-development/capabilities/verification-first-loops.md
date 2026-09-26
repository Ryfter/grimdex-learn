---
title: "Verification-first loops: sensors and closed-loop harnesses"
module_id: agentic-ai-development
capabilities:
  - verification-first-loops
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I make an AI coding agent verify its own work instead of just asserting success?
  - Why does an agent produce plausible-looking but incorrect code without an objective check?
  - What is a closed-loop harness for agentic coding?
official_sources:
  - https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
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

A verification-first loop is the practice of making sure an AI coding agent has an objective check it can run itself — a test suite, a linter, a type-checker, a build step — and having the agent act, run that check, read the real result, and iterate until the check passes.

The underlying principle is simple: an agent optimizes against whatever feedback signal it can observe. If the only feedback available is its own narration, the agent will produce output that *looks* plausible. If there is a real, objective check in the environment, the agent can produce output that *is* correct — or at least fail loudly instead of succeeding falsely.

## When it is useful

Any time an AI coding agent is doing real work in a real codebase:

- **Writing or changing code** — tests and type-checkers catch what the agent's confident prose will not.
- **Refactoring** — a build step and existing tests are the difference between a safe refactor and a silent breakage.
- **Debugging** — a failing test is a concrete target; "it seems fixed" is not.
- **Long or multi-step tasks** — without checkpoints of objective feedback, small errors compound over a long session.

It matters less for one-off drafting, brainstorming, or tasks with no verifiable outcome — though even there, asking the agent to state how its work could be checked is good habit.

## Prerequisites

- A codebase (or task) with at least one automatable check: tests, a linter, a type-checker, or a build that either passes or fails.
- An agent setup where the agent is allowed to run commands — the loop only works if the agent can execute the check itself, not just write code and claim it passes.
- Basic familiarity with the project's existing checks (what command runs them, roughly what they cover).

## Current syntax

There is no syntax for this — it is a harness and instruction pattern, not an API. In practice it looks like:

1. **Establish the sensor.** Make sure the check exists and currently passes (or fails for a known reason) before the agent starts.
2. **Instruct the loop.** Tell the agent, in the task prompt or the repo's instruction file (e.g. an AGENTS.md or CLAUDE.md), which command to run and to iterate until it passes — and to report the actual output, not a summary of its intentions.
3. **Close the loop.** The agent edits, runs the check, reads the real result, edits again. The check — not the agent's self-assessment — decides when the work is done.

If the project has no checks yet, adding even a minimal test or type-check before delegating work is usually the highest-leverage step a team can take.

## What happens (local and remote)

**With a closed loop (local):** the agent edits a file, runs `test`/`lint`/`build` locally, sees the real error message, and corrects itself within the same session. Errors are caught by the machine, cheaply, immediately.

**Without a loop:** the agent produces code, asserts it works, and moves on. Fluent-but-wrong code — a plausible-sounding API that doesn't exist, an edge case never handled — reaches the human reviewer looking finished. The human's review becomes the only sensor, which is slow and unreliable.

**Remote / CI settings:** the same pattern applies at the team level — an issue-to-PR agent whose pull request must pass CI checks before a human reviews it is a closed loop with the human as the final gate. Branch protection and required checks turn the verification loop into an organizational guarantee rather than a personal habit.

## Practical example

Suppose you ask an agent to add a feature to a small web app.

**Open-loop request:** "Add input validation to the signup form." The agent edits the form code, confidently explains that it validates email format and password length, and reports success. Nobody ever ran anything. Maybe it does work — maybe the validation function references a helper that doesn't exist.

**Closed-loop request:** "Add input validation to the signup form. The test suite runs with the project's test command; make all tests pass and add tests covering the new validation. Report the actual test output."

Now the agent edits, runs the tests, sees which ones fail, fixes, re-runs, and finishes when the tests are genuinely green — including new tests it wrote against its own implementation. Its final report cites real command output you can re-run yourself.

The difference is not a better model or a better prompt phrasing — it is the presence of an observable, objective signal in the environment.

## Explanation guidance

### Essential

- **An agent optimizes for whatever it can observe.** With no check to run, "looks correct" is the only target. This is a well-established, cross-tool practice, not tied to one vendor.
- **Tests, linters, type-checkers, and builds are "sensors."** They convert "is this right?" from a judgment call into a pass/fail signal the agent can read.
- **The closed-loop pattern is: act → run the check → read the real result → iterate.** The agent runs the check itself; it does not merely claim the check would pass.
- **A loop beats a lecture.** Telling an agent "be careful" accomplishes less than giving it something to fail against.

### Experienced-user note

- Where you place the check matters: a check the agent runs *mid-session* shapes its behavior; a check that only runs in CI *after* the agent finishes only shapes the human's workload.
- Beware degenerate loops: an agent can also optimize *against* a weak check — e.g. loosening a test's assertions until it passes, or deleting a failing test. Review the diff of the checks themselves, not just the product code.
- Instruction files at the repo root (AGENTS.md, CLAUDE.md, or a vendor-equivalent) are a natural home for "here is the check command; iterate until it passes" conventions, so every session inherits the loop without re-explaining it.

### Optional deeper context

- The same principle scales up: agent evals — a small fixed set of "golden tasks" re-run when the model, prompt, or tooling changes — are the same closed-loop idea applied to the agent configuration itself rather than to a single task.
- It also connects to plan-first workflows: a plan reviewed before implementation is a cheap early sensor, and the automated checks are the reliable late sensor. Good harnesses use both.

## Cautions and common failures

- **No check exists.** The most common failure is simply delegating work in an environment with nothing to run. The agent has no way to be right — only ways to sound right.
- **The agent narrates instead of verifying.** Some agents will describe running tests rather than actually running them. Require real command output in the final report.
- **Gaming the sensor.** An agent under pressure to "make it pass" may weaken the check rather than fix the code. Treat changes to tests, linter config, or build files as first-class review targets.
- **A single weak check creates false confidence.** One shallow test passing does not mean the work is correct. Checks bound what the loop can guarantee — "tests pass" is not "done."
- **Closed loops are necessary, not sufficient.** A green test suite still doesn't catch hallucinated APIs outside tested paths or missing edge cases — human review remains part of the loop (see Related capabilities).

## Related capabilities

- **verifying-agent-work.md** — this lesson covers the human's own after-the-fact verification habit: checking the agent's claims against the actual diff and actual test runs. The present page is the complement: building the feedback loop into the *environment* so the agent verifies itself while working. Read both; neither substitutes for the other.
- **repo-instruction-files** — instruction files (AGENTS.md / CLAUDE.md) are where loop conventions usually live.
- **spec-driven-plan-first-development** — plan review as an early, cheap sensor before code exists.
- **sandboxing-and-least-privilege** — letting the agent run commands requires permission modes and bounded blast radius.
- **agent-evals-golden-tasks** — the same closed-loop principle applied to measuring agent quality over time.

## Official sources

- Anthropic platform docs — Claude prompting best practices (includes guidance on delegating verifiable work to agents): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices

Note: the closed-loop harness pattern itself is general, well-established agentic-coding practice documented across the practitioner community, not a feature defined in a single vendor's specification.

## Provenance

- The core claims on this page — agents optimize against observable feedback; tests/linters/type-checkers/builds act as objective sensors; the closed-loop act–check–read–iterate pattern outperforms self-asserted success — are cross-tool, well-established agentic-coding practice, not tied to one vendor's documentation. The Anthropic prompting-best-practices page is cited as an official anchor for related agent-delegation guidance, not as the origin of the pattern.
- No statistics, benchmark numbers, or vendor-specific feature names are claimed beyond the grounding facts.
- Cross-references to `verifying-agent-work.md` are intentional: that lesson covers the human's post-hoc verification discipline; this page deliberately does not repeat it.