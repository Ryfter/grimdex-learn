---
title: "Agent evals: measuring non-deterministic quality over time"
module_id: agentic-ai-development
capabilities:
  - agent-evals
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I measure whether an AI agent's output quality is improving or degrading over time?
  - What is a golden task set for evaluating non-deterministic agent output?
  - When should agent evaluations be re-run after changing a model, prompt, or tool configuration?
official_sources:
  - https://platform.claude.com/docs/en/test-and-evaluate/develop-tests
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

An agent eval is a small, fixed set of **"golden tasks"** -- representative real tasks your agent handles, each with a known-good expected outcome -- that you re-run automatically whenever something under the hood changes. Because an AI agent's output is **non-deterministic** (the same prompt can produce different-but-plausible answers on different runs), you cannot judge quality by inspecting one output. You judge it by whether the agent still passes a stable set of checkable tasks.

The core idea:

- **Golden tasks**: a handful of tasks drawn from your actual workload -- "fix this specific bug," "add this specific endpoint," "answer this specific question from this document." Each has an expected outcome you can verify objectively: the tests pass, the build succeeds, the answer matches.
- **Trigger for re-running**: whenever the underlying model, a prompt, a tool configuration, or the agent's instructions change. Those are exactly the moments when silent quality regressions sneak in.
- **Purpose**: catch regressions *before* they reach production use -- the same role a regression test suite plays in ordinary software, but for agent behavior.

This is standard evaluation practice in ML/LLM engineering broadly -- not one vendor's proprietary method, and not specific to any single tool.

## When it is useful

- You've changed the model the agent uses (upgrade, switch, or a cost-tier routing change) and need to know nothing got worse.
- You've edited a system prompt, an instructions file, or a tool description and want to confirm you improved the intended thing without breaking something else.
- You're comparing two approaches (different prompting strategies, different tool setups) and want evidence rather than vibes.
- You're putting an agent into routine use and stakeholders ask, reasonably, "how do you know it still works?"

## Prerequisites

- A set of real, representative tasks -- even three to five is enough to start.
- An **objective check** for each task's outcome: tests, a linter, a type-checker, a build step, or an exact-match comparison. This is the same "sensor" logic as verification-first loops: without an observable signal, you can't tell a good run from a plausible-looking bad one.
- A way to run the tasks repeatedly under the same configuration (manually is fine at small scale).

## Current syntax

There is no syntax. Agent evals are a practice, not a feature: a folder of task files plus a checklist (or script) that runs each task and records pass/fail against the expected outcome. Any tool- or vendor-specific eval features are supplements to this, not replacements.

## What happens (local and remote)

Everything happens in your own workflow:

1. You store the golden tasks and their expected outcomes.
2. When the model, prompt, or tool config changes, you (or a CI step, if you've automated it) re-run each task.
3. You compare results against the known-good outcomes. A task that used to pass and now fails is a **regression** -- you investigate before the change ships.
4. If you use a hosted agent platform or background agents in CI, the same logic applies: the eval set is yours; the platform just executes the tasks.

No data needs to leave your environment unless the agent itself uses external tools as part of the tasks.

## Practical example

A team uses a coding agent for routine bug fixes in a web service. They keep five golden tasks: three bug fixes (verified by "the existing test suite passes and the new test passes"), one refactor (verified by "build and linter clean, behavior unchanged"), and one documentation question (verified by "the answer matches the known-correct summary").

When they swap the agent to a newer model version, they re-run the five tasks. Four pass; the refactor task now quietly renames a helper function used elsewhere, breaking an import. Without the eval set, that break would have surfaced days later in someone else's work. With it, the change is caught the same afternoon.

## Explanation guidance

### Essential

- Agent output is non-deterministic, so "I looked at one output and it seemed fine" is not a quality measurement.
- Keep a small, fixed set of real tasks with checkable, known-good outcomes.
- Re-run that set every time the model, prompt, or tool configuration changes. That's the whole discipline.
- The check must be objective (tests, build, exact match) -- not "it looked right."

### Experienced-user note

- Start small. Five good golden tasks beat fifty vague ones. Choose tasks that represent your actual failure modes.
- Expect some noise: because output is non-deterministic, a single flaky failure may not mean a regression. Re-run before panicking, and look for failures that repeat.
- Golden tasks can also be wired into CI so regressions block a change automatically, rather than relying on someone remembering to re-run.

### Optional deeper context

- This practice descends from classic ML evaluation (fixed validation sets, regression testing on model changes) and carries over to LLM agents almost unchanged.
- The idea composes with other habits in this module: golden tasks *are* verification-first loops applied to the agent itself, rather than to the agent's code output. Relatedly, when a golden task fails, reading the agent's trace is how you find out *where* the run went off track.

## Cautions and common failures

- **No objective check**: if the expected outcome is "looks good," the eval measures nothing. Attach a test, build, or exact-match criterion to every task.
- **Overfitting the eval set**: if you tune the agent until it aces only the golden tasks, you've measured the tasks, not general quality. Refresh the set occasionally with new real-world tasks.
- **Skipping the re-run**: the most common failure is changing a prompt or model and not re-running at all, because "it's just a small edit." Small edits are exactly where silent regressions live.
- **Chasing flakiness**: a single failed run may be noise, not regression. Confirm with a re-run before reverting a change.
- **Treating evals as certification**: a passing eval set says the agent still handles your known tasks; it doesn't guarantee handling of novel tasks.

## Related capabilities

- **verifying-agent-work**: the same core discipline -- trust the actual diff and actual test runs, not the agent's narration -- applied per-task; evals apply it across changes over time.
- **verification-first loops**: golden tasks depend on having an objective check (tests, linters, build) as the feedback sensor.
- **reading-agent-traces**: when a golden task fails, the trace is where you diagnose why.
- **model routing and cost-tier optimization**: if you change which model handles which task, that's a change worth re-running the eval set for.
- **background agents in CI (issue-to-PR)**: if agents open PRs automatically, golden-task evals are a natural companion gate before human review.

## Official sources

- <https://platform.claude.com/docs/en/test-and-evaluate/develop-tests> -- Anthropic's own docs on developing tests and evaluations: success-criteria dimensions, example metrics, and grading-method tradeoffs. It covers the mechanics of grading one output, not the golden-task-regression-set framing this page builds on top of that -- treat it as the closest official anchor, not a page that specifically describes "agent evals over time."

No single canonical official page covers the golden-task-regression-set framing itself. Agent evals via that pattern are standard, cross-vendor evaluation practice in ML/LLM engineering; this page draws on that shared practitioner consensus rather than one vendor's documentation. For tool-specific eval features, consult your agent platform's own docs.

## Provenance

- Content is cross-tool, well-established practice per the module's grounding synthesis: golden tasks with known-good expected outcomes, re-run on model/prompt/tool-configuration changes to catch regressions -- standard evaluation practice in ML/LLM engineering broadly, not one vendor's proprietary method.
- The cited official source covers grading mechanics for a single output, which this page's golden-task/regression framing builds on -- it is the closest verified anchor, not a direct source for the specific "re-run over time" pattern. No commands or vendor claims beyond that boundary are asserted.
- Examples are illustrative constructions consistent with the described practice; no statistics or benchmark numbers are claimed.
- Status: current as of the fall-2026 version stamp; everyday claim class, normal safety class.