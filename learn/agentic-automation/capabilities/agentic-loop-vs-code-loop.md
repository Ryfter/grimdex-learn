---
title: An agentic "loop" is not a for/while loop
module_id: agentic-automation
capabilities:
  - agentic-loop-vs-code-loop
context7_library: /websites/platform_claude_en
context7_queries:
  - What does an agentic act-observe-decide loop look like in Claude Code?
  - How does headless mode relate to running an agent repeatedly until a condition is met?
  - Where is the act-observe-decide cycle documented for coding agents?
official_sources:
  - https://code.claude.com/docs/en/hooks
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

An **agentic loop** is a repeat cycle where an AI coding agent *acts* (runs a tool, edits a file, executes a command), *observes* the result (reads output, test failures, errors), and *decides* what to do next, repeating until it judges the task done -- for example, "keep fixing until tests pass." A **for/while loop** is a programming-language construct with a fixed, deterministic condition: the code inside runs exactly as written, the exit condition is evaluated mechanically, and nothing in the loop adapts its own behavior.

The agentic loop is conceptually different. Its "condition" is not a line of code evaluated by the runtime -- it is the agent's own judgment about whether the observed results mean the goal is met. Each iteration can branch, change strategy, or try a completely different approach, which a deterministic loop cannot do on its own.

## When it is useful

Understanding this distinction matters before you use any of the module's repeated-execution tools:

- When you ask an agent to "run until tests pass," you are describing an agentic loop, not a `while (!testsPass)` you can inspect.
- When you later wire that agent into a hook, schedule, or unattended run, you need to know you are repeating an *adaptive* process, whose iterations you cannot fully predict.
- When a beginner reads "loop" in an agent's transcript or docs, they may wrongly expect deterministic, inspectable control flow. This page prevents that conflation.

## Prerequisites

- Basic familiarity with running an AI coding agent such as Claude Code from a prompt.
- Basic programming literacy (what a for/while loop is) -- this page contrasts against it.
- Awareness that headless / non-interactive mode (Claude Code's `claude -p` programmatic invocation is a real, documented example) is the prerequisite building block for *any* repeated or automated agent work: you cannot loop, hook, or schedule an agent that requires an attended terminal session.

## Current syntax

There is no syntax for the agentic loop itself -- it is a behavior pattern, not a language construct. The related constructs worth knowing by name:

- A code loop: `for` / `while` in your language of choice; exit condition evaluated mechanically by the runtime.
- An agentic loop: expressed in natural language instructions to the agent (e.g. "iterate until the failing test is fixed"), executed by the agent's act → observe → decide → repeat cycle.
- The bridge between the two in practice: headless invocation such as Claude Code's `claude -p`, which lets an outer script or workflow drive the agent; whether an equivalent headless flag exists in other tools is a per-tool question -- Cursor and Codex-CLI feature parity here is unverified.

## What happens (local and remote)

When an agent runs an agentic loop locally:

1. **Act** -- the agent calls a tool (edit a file, run the test suite, read an error).
2. **Observe** -- the tool's output is fed back to the agent as new context.
3. **Decide** -- the agent (an LLM) interprets the observations and chooses the next action, which may be to retry, change approach, or stop.
4. **Repeat** until the agent judges the goal met, an iteration cap is reached, or a human intervenes.

Because the decision step is probabilistic (it is an LLM, not an `if` statement), the number of iterations, the specific actions taken, and even whether the loop terminates can all vary between runs. There is no local or remote machinery that guarantees the loop exits the way a `for` loop's counter does -- which is exactly why the module's later topics (hooks, guards like iteration caps, and unattended-run safety) exist.

## Practical example

**The conflated version (wrong mental model).** A beginner writes instructions like:

> Fix the failing test. Run the tests. If they fail, fix again. Repeat until green.

and imagines this is equivalent to:

```python
while not tests_pass():
    fix_bug()
```

It is not. In the Python loop, `tests_pass()` is a function whose return value deterministically controls the exit, and `fix_bug()` is a fixed function body. In the agentic version, "tests fail" is an *observation the agent interprets*, and "fix the bug" is an *action the agent chooses* -- potentially a different fix every iteration, sometimes a wrong one.

**The corrected mental model.** The agentic loop is better read as:

1. Agent edits code (act).
2. Agent runs tests, sees output (observe).
3. Agent reasons: "The error changed -- my first fix was wrong, try a different approach" (decide).
4. Agent repeats, possibly several times, possibly taking a detour you did not anticipate.

Two practical consequences follow: you should check the loop actually terminated with the result you wanted (the agent's judgment of "done" is not proof of correctness), and before letting such a loop run unattended you should bound it -- Claude Code's headless mode has a real, documented `--max-turns`-style iteration cap, and GitHub Actions jobs have a real `timeout-minutes` setting, both of which limit an unattended loop that never naturally completes.

## Explanation guidance

### Essential

- The agentic loop is **act → observe → decide → repeat until done**; the "decide" step is an LLM making a judgment, not a boolean check.
- A for/while loop is **deterministic**: fixed body, mechanical exit condition, inspectable control flow. The agentic loop is **adaptive**: variable iterations, variable actions, non-inspectable decision logic.
- Beginners conflate the two because both are "repetition until something stops" and both use the word "loop." The one-word overlap hides a structural difference.
- Practical upshot: with a code loop you debug the condition; with an agentic loop you bound the risk (caps, timeouts) and verify the outcome, because you cannot debug the agent's judgment the way you debug a boolean.

### Experienced-user note

- If you are building automation on top of an agent, recognize that you are composing an *outer* deterministic loop (a script, a GitHub Actions workflow, a shell `while`) around an *inner* probabilistic loop (the agent). The outer loop can only bound and observe the inner one; it cannot reason about it.
- A concrete guardrail pattern: drive the agent headlessly (`claude -p` is the verified Claude Code mechanism), cap iterations with `--max-turns`, and use the outer script's exit-code checks -- not the agent's self-report -- as the loop's exit condition. This restores a deterministic gate around an adaptive process.
- (Unverified comparison: whether other agent CLIs expose an equivalent turns/iteration cap is not established for Cursor or Codex-CLI -- check each tool's own docs rather than assuming parity.)

### Optional deeper context

- The conflation has a real cost in automation design: an agentic loop placed inside a cron schedule or a hook can re-trigger unpredictably. This is why Claude Code's hooks system (real, documented at code.claude.com/docs) includes the `Stop` event and a `stop_hook_active` field specifically to prevent a hook from re-triggering more agent work in an infinite feedback loop -- an acknowledgment at the tool level that agentic loops do not have code-loop termination semantics.
- Idempotency framing: a code loop's re-run safety is determined by the code; an agentic loop's re-run safety depends on what the agent *decides* a second time, which is why idempotent task design (the general engineering concept, formally anchored by HTTP's idempotent-methods concept, RFC 9110 §9.2.2) matters more, not less, when the repetition is agentic.

## Cautions and common failures

- **Expecting deterministic control flow.** You cannot set a breakpoint on the agent's "decide" step or unit-test its exit condition. If correctness matters, put deterministic checks *around* the loop (run tests yourself, check exit codes) rather than trusting "repeat until done."
- **Runaway iterations.** Because termination is the agent's judgment, a loop can continue far longer than intended. Bound unattended runs with real, documented caps: `--max-turns` in Claude Code headless mode, `timeout-minutes` in GitHub Actions jobs (documented default around 360 minutes).
- **Assuming cross-tool parity.** The named mechanisms above are verified for Claude Code and GitHub Actions. Do not assume Cursor or Codex-CLI have equivalent, named headless, hook, or iteration-cap features -- that comparison is unverified; scope claims to the tool you verified.
- **Confusing an agentic loop with a git hook or scheduler.** "Loop until condition," "hook on event," and "schedule at time" are three distinct trigger types; the agentic loop is the *work being repeated*, not the trigger mechanism.
- **Attended-only agents can't be looped.** None of this works unattended unless the agent supports headless/non-interactive invocation -- Claude Code's `claude -p` is the verified example.

## Related capabilities

- Headless/non-interactive agent invocation (the prerequisite for any repeated agent work)
- Agent lifecycle hooks (guardrails around agentic loops; the `Stop` / `stop_hook_active` anti-runaway mechanism)
- Scheduling agent work (cron and GitHub Actions `on.schedule`, with their documented caveats)
- Bounding unattended runs (`--max-turns`, `timeout-minutes`, concurrency controls, kill-switch operations)
- Unattended-run safety and human approval gates

## Official sources

- Claude Code hooks documentation: https://code.claude.com/docs/en/hooks
- Git hooks documentation (contrast: deterministic hooks around git operations): https://git-scm.com/docs/githooks
- Claude Code headless / programmatic mode: https://code.claude.com/docs

## Provenance

Drafted from this session's grounding research on agentic loops, Claude Code's documented headless mode and hooks system, and the module's explicit caution against asserting unverified Cursor/Codex-CLI feature parity. Core conceptual claims (act-observe-decide cycle vs. deterministic for/while; the conflation risk) are practice guidance anchored to the documented Claude Code mechanisms (`claude -p`, `--max-turns`, `Stop`/`stop_hook_active`) and standard engineering concepts (RFC 9110 §9.2.2 idempotency). Cross-tool comparisons beyond Claude Code, GitHub Actions, and git are explicitly flagged as unverified rather than asserted.