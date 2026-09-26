---
title: Avoiding hooks that trigger themselves forever
module_id: agentic-automation
capabilities:
  - hook-feedback-loop-risk
context7_library: /websites/platform_claude_en
context7_queries:
  - How do Claude Code hooks like the Stop event work?
  - What is the stop_hook_active field and when should a hook check it?
  - Can a hook that returns output cause the agent to keep working in an infinite loop?
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

A hook is a script that runs automatically on a specific event. In Claude Code, lifecycle hooks such as PreToolUse, PostToolUse, Stop, Notification, and SessionStart run around agent events (source: code.claude.com/docs/en/hooks). A hook can also return a non-zero exit code to deny or block an agent action.

The risk this page covers: some hooks don't just observe agent work -- they can cause more agent work. A PostToolUse hook that runs tests and feeds failures back to the agent, or a Stop hook that tells the agent "you're not done yet, keep going," is by design an instruction to the agent. If that instruction always produces more work, and that work re-triggers the hook, the two feed each other forever. This is an infinite feedback loop, and it is distinct from the ordinary runaway risk of any loop: here, the hook and the agent are explicitly re-triggering each other.

Claude Code documents a real, specific mechanism for this exact situation: the `Stop` event fires when the agent finishes responding, and hook input for that event includes a `stop_hook_active` field indicating that the stop itself already resulted from a hook continuing the agent's work. A Stop hook is expected to check that field and not instruct the agent to continue again when it is set -- that is the documented guard against a hook endlessly re-triggering more agent work.

## When it is useful

- You are writing or reviewing any Claude Code hook whose output can influence the agent's next action (especially `Stop` and `PostToolUse` hooks that feed results back).
- You are setting up a semi-autonomous agent run with guardrail hooks and want it to enforce rules without becoming a perpetual-motion machine.
- A colleague reports an agent run "that never ends" and you need a vocabulary and a concrete, documented cause to check first.
- You are teaching the general principle: a hook that can trigger more agent work needs a terminating condition, just like the act → observe → decide loop it sits inside.

## Prerequisites

- Understanding of Claude Code hooks as a concept (scripts on lifecycle events, non-zero exit code to deny an action).
- Ideally, prior exposure to headless / non-interactive agent runs (`claude -p`), since unattended runs are where a feedback loop does unattended damage.
- No programming-language loop expertise required -- but the distinction between an agent loop (repeat until done) and a code loop (repeat N times) is useful context.

## Current syntax

There is no new command syntax on this page; the relevant mechanics are the documented hook events and fields of Claude Code:

- `Stop` -- a documented Claude Code lifecycle event that fires when the agent finishes responding.
- `stop_hook_active` -- a documented field in Stop hook input that indicates the stop already resulted from a hook prompting further agent work.
- Non-zero exit code -- the documented way any hook denies/blocks an action.

(Note: this page scopes its claims to Claude Code, which has a verified, documented hooks system. Whether Cursor or Codex-CLI offer equivalent hook-and-anti-loop mechanisms is unverified in this material and is not asserted here.)

## What happens (local and remote)

**Local:** Claude Code runs lifecycle hook scripts on your machine as agent events occur. When the agent finishes, the `Stop` event fires and your Stop hook script runs. If that hook produces output that causes the agent to continue, the agent works again, finishes again, and `Stop` fires again. Claude Code sets `stop_hook_active` in the hook input on these hook-driven continuations precisely so a well-behaved hook can detect the situation and decline to continue the cycle.

**Remote/unattended:** the same mechanism applies, but nobody is watching. A feedback-looping hook in an unattended headless run consumes real tokens against real rate limits and (if it touches a repository) can push or modify state repeatedly. This is why the feedback-loop guard belongs to the same family of safety measures as iteration caps like `--max-turns` in headless mode and `timeout-minutes` in GitHub Actions -- bounding the damage of a run that never naturally completes.

## Practical example

A team wants their agent to keep working until its own tests pass. They write a Stop hook that runs the test suite and, on failure, tells the agent to fix the failing test.

The safe shape of that hook, per the documented mechanism:

1. The agent finishes a turn; the `Stop` event fires.
2. The hook script reads its input and first checks the `stop_hook_active` field.
3. If `stop_hook_active` is true, the hook exits without instructing the agent to continue -- the agent has already been given one hook-driven continuation, and continuing again risks an endless cycle.
4. If it is false and the tests fail, the hook returns output telling the agent what to fix.
5. The agent works, finishes, and `Stop` fires again -- now with `stop_hook_active` set, so step 3 applies.

The unsafe shape is the same hook without step 2-3: every failing test run produces another continuation, and a test that can never pass (or a hook with a bug) means the agent never stops.

For other hook events, the analogous discipline is: before your hook causes more agent work, ask "what terminates this?" If the answer is "the condition I'm checking eventually becomes true," verify that's actually guaranteed; if it isn't, don't let the hook re-trigger work unboundedly.

## Explanation guidance

### Essential

- Hooks run automatically on events; some hooks can *cause* more agent work, not just observe it.
- A hook that always causes more work, whose triggering work then re-fires the hook, is an infinite feedback loop.
- Claude Code's documented mechanism for exactly this is the `Stop` event plus the `stop_hook_active` field: a Stop hook that sees `stop_hook_active` set should not instruct the agent to continue again.
- Any hook that feeds instructions back to the agent needs a terminating condition.
- This matters most for unattended runs, where nobody is present to interrupt the cycle.

### Experienced-user note

- `stop_hook_active` is not a general "am I looping?" oracle -- it specifically marks that the current stop arose from a prior hook continuation. Design your hook to respect it rather than to rely on other heuristics.
- Combine the anti-loop guard with an iteration cap on unattended runs: Claude Code's headless mode offers a `--max-turns`-style iteration cap, so a defensive hook plus a bounded turn count is the robust configuration.
- A non-zero exit code from a hook *denies* an action; that's a different behavior from feeding guidance back. Decide deliberately which your hook is doing -- a blocking hook doesn't create the same feedback risk as one that prompts continuation.
- Whether other agent tools (Cursor, Codex-CLI) have an equivalent documented anti-feedback-loop field is unverified here; don't assume parity.

### Optional deeper context

- The feedback-loop problem is the hook-world cousin of the general runaway-loop problem: same family as a scheduled GitHub Actions workflow that re-triggers itself, which is why that platform separately documents `timeout-minutes` (default around 360 minutes) and `concurrency` settings. Defense in depth -- a loop-terminating condition *and* an external bound -- is the pattern.
- Conceptually, a hook feeding instructions back into the agent makes the agent loop and the hook mutually recursive; any mutually recursive pair without a base case runs forever. `stop_hook_active` is Claude Code's documented base case.

## Cautions and common failures

- **Assuming the agent "won't loop."** An agent repeats until done; if your hook keeps redefining "done," it repeats forever. The hook, not the agent, owns the terminating condition.
- **Writing a Stop hook without checking `stop_hook_active`.** This is the documented failure mode the field exists to prevent.
- **Conflating blocking with prompting.** A hook that exits non-zero to deny an action is a guardrail; a hook that returns "keep going because X" is a driver. Drivers need terminating conditions.
- **Testing only the happy path.** If your hook's condition can be permanently false (a flaky test, a wrong path), you have built a perpetual loop. Test with a condition that never resolves.
- **Leaving feedback-looping hooks in unattended runs.** Real token spend, real rate limits, real repository changes -- with nobody watching. Bound the run with `--max-turns` (headless mode) in addition to fixing the hook.
- **Assuming other tools behave identically.** Claude Code's Stop/stop_hook_active mechanism is verified and documented; equivalent features in Cursor or Codex-CLI are not verified in this material.

## Related capabilities

- Headless / non-interactive agent runs -- the prerequisite for unattended loops and the place where `--max-turns`-style caps apply.
- Agent lifecycle hooks (PreToolUse, PostToolUse, Stop, Notification, SessionStart) -- the broader hooks system this page's risk lives inside.
- Bounding unattended runs (timeout-minutes, concurrency) -- the external-bounds complement to internal terminating conditions.
- Loop vs. hook vs. schedule trigger types -- where hooks sit among the three ways agent work repeats.

## Official sources

- https://code.claude.com/docs/en/hooks (Claude Code hooks system, Stop event, stop_hook_active field)

## Provenance

- Claude Code hooks system, lifecycle events, non-zero-exit-code denial, and the Stop event / `stop_hook_active` anti-feedback-loop mechanism are from this session's research against code.claude.com/docs/en/hooks.
- Headless mode (`claude -p`) and `--max-turns`-style iteration caps per code.claude.com/docs.
- Cross-tool comparisons for Cursor and Codex-CLI hooks/scheduling are explicitly flagged unverified per this module's standing caution and are not asserted.