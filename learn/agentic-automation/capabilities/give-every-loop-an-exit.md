---
title: Give every loop an exit condition
module_id: agentic-automation
capabilities:
  - give-every-loop-an-exit
context7_library: /websites/platform_claude_en
context7_queries:
  - How do I bound an unattended Claude Code loop so it stops instead of running forever?
  - What does the --max-turns flag do in Claude Code headless mode?
  - How does the Stop hook and stop_hook_active field prevent an infinite agent feedback loop?
official_sources:
  - https://code.claude.com/docs/en/hooks
  - https://code.claude.com/docs/
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

An agentic loop — act, observe, decide, repeat until done — is conceptually different from a programming-language `for`/`while` loop. In a program, the loop's exit is written into the code. In an agent session, "done" exists only if you define it explicitly, and "keep trying" only stays safe if you also bound how long or how many times the agent may try.

Giving every loop an exit condition means two things, and you need both:

1. **An explicit, checkable done condition** — something objective a human (or a script) can verify, such as "the test suite passes" or "the linter reports zero errors." "Improve the code" is not checkable; "all tests in `make check` pass" is.
2. **A bound on attempts or runtime** — a hard cap that fires even if the done condition is never met, so an unattended loop that never naturally completes stops itself instead of running indefinitely.

The bound is not a nice-to-have. It is what turns "keep trying until it works" from a safe instruction into potential unattended, endless work.

## When it is useful

- Any time you ask an agent to "run until tests pass," "keep fixing lint errors," or "retry the build" — especially in headless mode, where nobody is watching the session.
- Before you wrap an agent in a hook (for example, a Claude Code `Stop` hook that resumes work) or a schedule, because these are the mechanisms that can re-trigger agent work with no human in the loop.
- Anywhere two overlapping unattended runs might touch the same repository — an unbounded loop compounds that risk.
- Anywhere cost matters: an unattended loop keeps consuming tokens and (in CI) billed workflow minutes long after a human would have given up.

## Prerequisites

- Headless / non-interactive mode. You cannot loop, hook, or schedule an agent that requires an attended terminal session; Claude Code's documented headless mode (`claude -p`, programmatic invocation) is the building block.
- A checkable success signal — a command whose exit code means "done" (a test runner, a linter, a build).
- Basic familiarity with the distinction between an agentic loop and a programming loop, so the exit condition is understood as a design decision, not code.

## Current syntax

The grounding for concrete caps here is Claude Code, where these are real, documented mechanisms:

- **`--max-turns`-style iteration cap in headless mode**: Claude Code's headless mode supports an iteration cap that bounds how many agent turns an unattended run can take. If the loop never reaches its done condition, the run stops when the cap is hit. (Cursor and Codex-CLI equivalents are **unverified** — do not assume feature parity; check each tool's own docs.)
- **`Stop` hook and `stop_hook_active`**: Claude Code's hooks system (PreToolUse, PostToolUse, Stop, Notification, SessionStart) includes a `Stop` event with a `stop_hook_active` field, which exists specifically to prevent a hook from re-triggering more agent work in an infinite feedback loop. If you build a loop out of hooks, you must honor that field.
- **Non-zero exit codes from hooks**: a hook returning a non-zero exit code can deny/block an agent action — usable as an enforced exit when a checkable condition fails.
- **On GitHub Actions**, if the loop lives in CI rather than the agent session: `timeout-minutes` per job (documented default around 360 minutes) bounds runtime.

For plain cron jobs on a Linux host, there is no built-in agent-turn cap — you impose one via the scheduling wrapper itself (e.g. a timeout around the command) and, for overlapping runs, `flock`.

## What happens (local and remote)

**With an exit condition, working correctly:**

- The agent runs in headless mode, repeatedly acting and observing, and stops when the checkable condition is met (tests pass) or when the hard cap fires (max turns / timeout reached), whichever comes first.
- A hook-driven loop that respects `stop_hook_active` does not re-spawn itself endlessly.
- Resource use is bounded: a finite number of turns, tokens, and (if in CI) workflow-run minutes.

**Without an exit condition, what goes wrong:**

- "Keep trying" becomes an unattended loop that never completes because the done condition is vague or unverifiable — the agent keeps editing, keeps consuming tokens, keeps producing commits.
- A hook that fires on `Stop` and unconditionally resumes work creates an infinite feedback loop — exactly the scenario `stop_hook_active` exists to prevent.
- In GitHub Actions, a job without `timeout-minutes` can run for up to the documented default (around 360 minutes), burning billed minutes.
- If two overlapping unbounded runs edit the same repository, they can conflict and damage state; mitigations like GitHub Actions `concurrency` groups (`cancel-in-progress`) or `flock` for cron limit this, but bounding the loop itself is the first line of defense.

## Practical example

Goal: have an agent fix failing tests, unattended, but never endlessly.

1. **Define the done condition checkably.** Write it as a command, not a wish:
   - Done = `npm test` exits 0. Not done = anything else.
2. **Bound the attempts.** Invoke the agent in headless mode with an iteration cap, e.g. a `--max-turns`-style flag on Claude Code's headless invocation, so the run cannot exceed a fixed number of turns even if tests never pass.
3. **If you loop via a hook, honor the built-in guard.** A Claude Code `Stop` hook that resumes the agent must check `stop_hook_active` and do nothing when it is set — this is the documented mechanism that prevents the hook from re-triggering work forever.
4. **Gate it first.** Before the first unattended run, review what permission mode the agent runs in. Claude Code asks for permission by default; flags exist to skip permission prompts, but that is a real, higher-risk mode — decide deliberately.
5. **Run it, then check both exits.** Either the done condition fired (tests pass) or the cap fired (run stopped at max turns). Both are valid outcomes; report which one happened rather than assuming "the loop finished" means success.

Sketch of the decision logic (pseudocode, not a real script):

```
attempts = 0
while attempts < MAX_TURNS:          # hard bound — always present
    run agent turn (headless)
    if tests_pass():                 # checkable done condition
        exit("done")
    attempts += 1
exit("gave up after MAX_TURNS")      # a real, reported outcome
```

## Explanation guidance

### Essential

- Every agentic loop needs **two** things: a checkable "done" and a hard cap. Either alone is insufficient — a checkable condition the agent never reaches still needs a cap; a cap alone just truncates aimless work.
- "Done" must be a command or a verifiable state (tests pass, build succeeds), not an adjective ("good", "better").
- The cap is what makes unattended safe: max turns / timeout bounds damage, cost, and token use when the loop never naturally completes.
- If a hook can re-trigger agent work, it needs its own anti-recursion guard — Claude Code's `stop_hook_active` is the documented mechanism for this; do not hand-roll a hook loop without it.

### Experienced-user note

- Distinguish "loop finished" from "loop succeeded." A run that exhausts its `--max-turns` cap exits cleanly — that exit is your kill signal, not a success signal. Treat "hit the cap" as a failure report that needs human review.
- Hook-based guardrails compose with exit conditions: a non-zero-exit hook can deny an agent action when a check fails, turning your done condition into an enforced boundary rather than a suggestion.
- In CI-based loops, pair `timeout-minutes` with `concurrency` groups (`cancel-in-progress`) so a stuck run neither runs long nor overlaps with its own retry.
- Design the task to be **idempotent** — safe to re-run twice — so that a capped run that partially completed can be retried without compounding damage. HTTP's idempotent-methods concept (RFC 9110 §9.2.2) is the familiar formal anchor.

### Optional deeper context

- Why the cap exists as a separate mechanism from the done condition: agents decide based on observation, and an agent whose observations never show success has no internal reason to stop. The cap is the external, non-negotiable stop — the agent cannot argue with it.
- The `Stop` / `stop_hook_active` design is a general lesson: any mechanism that can spawn more work needs a flag or state that says "I was just triggered by myself." Recursion guards are a classic systems pattern; Claude Code documents one concrete instance.
- When comparing tools: this page's concrete mechanisms are verified for Claude Code (headless turn caps, `Stop` hooks, `stop_hook_active`) and GitHub Actions (`timeout-minutes`, concurrency). Whether Cursor or Codex-CLI have equivalent named features is **unverified** — check each tool's own documentation before claiming parity.

## Cautions and common failures

- **Vague done conditions.** "Make the code better" cannot be checked; the loop has no exit even with a cap — you just get truncated aimlessness. Always phrase done as a command exit code or verifiable state.
- **Cap only, no condition.** A run that always exhausts `MAX_TURNS` is not a loop; it's a timer burning tokens. Investigate why the condition never fires.
- **Hook feedback loops.** A `Stop` hook that resumes the agent without checking `stop_hook_active` will re-trigger work indefinitely. This is the documented failure mode the field exists to prevent.
- **Assuming CI default timeout is enough.** GitHub Actions' `timeout-minutes` default is around 360 minutes — six billed hours is a lot of runway for a runaway job. Set an explicit, much smaller cap.
- **Unbounded cost.** Unattended runs consume real tokens against real rate limits and (in GitHub Actions) real billed workflow-run minutes — precisely because nobody is watching live, budget the cap before the first run.
- **Skipping the permission review.** Before going unattended, confirm the agent's permission mode. Explicitly configured skip-permission modes are real but higher risk; an unbounded loop combined with fewer prompts multiplies damage potential.
- **Overlap damage.** Two overlapping unattended runs editing the same repository can conflict destructively; use GitHub Actions `concurrency` groups or `flock` for cron, and keep loops bounded so runs end before the next starts.
- **Cross-tool assumptions.** Do not assume Cursor or Codex-CLI have the same named caps or hook guards as Claude Code — this comparison is unverified; verify against each tool's own docs.

## Related capabilities

- Distinguish loops, hooks, and schedules as the three trigger types for repeated agent work — an exit condition applies to all three.
- Headless / non-interactive mode as the prerequisite for any loop, hook, or schedule.
- Enforcing guardrails with agent lifecycle hooks (non-zero exit codes deny actions).
- Bounding overlapping unattended runs (GitHub Actions `concurrency`, `flock`).
- Human approval gates before unattended runs (permission modes, GitHub environment protection rules with required reviewers).
- Cancelling vs. disabling: the two separate kill-switch operations for a run that escaped its bounds.

## Official sources

- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/

## Provenance

- Claude Code hooks system (PreToolUse, PostToolUse, Stop, Notification, SessionStart), non-zero-exit denial, and the `Stop` event / `stop_hook_active` anti-recursion mechanism: code.claude.com/docs/en/hooks.
- Claude Code headless mode (`claude -p` / programmatic invocation) and the `--max-turns`-style iteration cap: code.claude.com/docs.
- GitHub Actions `timeout-minutes` (documented default around 360 minutes) and `concurrency` syntax: docs.github.com.
- Idempotency as a general engineering concept anchored in HTTP idempotent methods: RFC 9110 §9.2.2.
- Explicit unverified flag carried per module caution: Cursor and Codex-CLI hook/scheduling feature parity with Claude Code and GitHub Actions is not verified in this module's research.
- Context7 sources used this session: /websites/platform_claude_en (Claude Code hooks and headless-mode topics).