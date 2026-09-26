---
title: Spec-driven and plan-first development
module_id: agentic-ai-development
capabilities:
  - spec-driven-plan-first-development
context7_library: /websites/platform_claude_en
context7_queries:
  - "How does plan mode work in Claude Code before implementation?"
  - "What are best practices for reviewing an agent's plan before code is written?"
  - "How can I make a coding agent present a plan for approval first?"
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

Spec-driven (or plan-first) development means asking an AI coding agent to present a short plan — what it intends to do, which files it will touch, what approach it will take — and reviewing that plan *before* any code is written, rather than letting the agent implement first and reviewing a large change afterward.

Claude Code has a real "plan mode" feature that implements this pattern concretely: the agent presents a plan, you approve or adjust it, and only then does it implement. But this is not one vendor's exclusive idea — reviewing a plan before code is increasingly common practice across coding-agent tools generally, and you can get the same effect in almost any agent by simply instructing it: "Before writing any code, give me a short plan and wait for my approval."

## When it is useful

The core reason is cost asymmetry:

- **Catching a wrong approach in a plan costs minutes.** Reading a few paragraphs, spotting "wait, that would break X," and replying with a correction is cheap.
- **Catching the same wrong approach in a finished diff costs a rewrite.** By then the agent has implemented the wrong design across many files, and you either hand-revert it or spend tokens and time having the agent redo work.

Plan-first review is most valuable when:

- The task is large, ambiguous, or touches multiple files or systems.
- You're unsure whether the agent has understood the requirement correctly.
- The work is expensive to undo (data migrations, refactors, API changes).
- You're new to a codebase and want to learn the agent's intended direction early.

For trivial one-line changes, a full plan review is usually unnecessary overhead.

## Prerequisites

- A coding agent or AI assistant that can act on your codebase (or at least discuss it).
- Enough understanding of the task to recognize whether a proposed plan is sensible — you don't need to write the code, but you do need to know what "right" roughly looks like.
- Optionally: version control (git) so any implementation that follows a flawed plan can be rolled back cleanly. See Related capabilities.

## Current syntax

There is no universal command syntax, because this is a practice, not a single standard interface.

- **Claude Code:** a real "plan mode" feature — the agent presents a plan and waits for approval before implementing. Consult the official Claude Code documentation for the current exact way to enter and exit plan mode, rather than relying on memorized keystrokes.
- **Any agent, generically:** include an instruction in your prompt or repo instruction file along the lines of: "For any non-trivial task, first present a short plan (approach, files to change, risks) and wait for my approval before writing code."

## What happens (local and remote)

Nothing is executed remotely by the practice itself — this is a workflow pattern layered on your normal agent interaction.

**Local flow:**
1. You describe the task to the agent.
2. The agent produces a short plan instead of code.
3. You read the plan, checking approach, scope, and anything it seems to have misunderstood.
4. You approve, correct, or redirect — often a one-line reply ("do X instead, don't touch Y").
5. Only after agreement does the agent implement.
6. You still review the resulting diff — a good plan doesn't remove the need for final verification.

**Remote / shared context:** if your team uses a repo instruction file (AGENTS.md, CLAUDE.md, or similar), the plan-first expectation can be encoded there once, so every agent session starts with the convention instead of you re-explaining it each time. Plans can also serve as lightweight documentation of what was agreed before implementation.

## Practical example

**Without plan-first:**

> You: "Add rate limiting to our API."
> Agent: *implements a middleware across six files, using an in-memory counter.*
> You, reviewing the diff: "We run three instances behind a load balancer — in-memory counters won't work. Please redo it."
> Agent: *rewrites much of the work.*

**With plan-first:**

> You: "Add rate limiting to our API. Give me a plan first."
> Agent: "Plan: add middleware using an in-memory counter, applied to all routes..."
> You: "Stop — we run three instances, so it must be a shared store. Use our existing Redis."
> Agent: "Revised plan: use Redis-backed counters..." 
> You: "Approved. Go ahead."

The second version caught the same mistake in a two-minute plan review instead of a costly rewrite.

## Explanation guidance

### Essential

- Reviewing a short plan before code exists is cheaper than reviewing a large diff afterward — catching a wrong approach early costs minutes; catching it after implementation costs a rewrite.
- Claude Code's plan mode is one real, concrete implementation of this pattern: plan → approval → implementation.
- This is increasingly common practice across coding-agent tools, not one vendor's exclusive feature. If your tool has no plan mode, ask the agent to present a plan and wait for approval before writing code.
- A good plan review checks three things: is the approach right, is the scope right (no unrequested changes), and has the agent misunderstood anything?

### Experienced-user note

- Plan-first pairs naturally with verification-first loops: the plan defines what "done" looks like, and you can ask the agent to include its intended checks (tests, build) in the plan itself.
- Encoding "always plan first for non-trivial tasks" in a repo instruction file makes the convention apply automatically across sessions and across team members.
- For long agent sessions, an approved plan doubles as a reference point: if the agent drifts from it mid-session, you have a concrete artifact to steer it back with.

### Optional deeper context

- The cost asymmetry is the same reason code review exists at all: errors are cheapest to fix when less has been built on top of them. Plans just move the review earlier in that curve.
- Plans also expose the agent's *interpretation* of ambiguous requirements — a plan that quietly assumes something you didn't state ("I'll use library X") surfaces the assumption while it's still a one-line correction.
- Plan-first and multi-agent orchestration interact: if you fan work out to parallel sub-agents, agreeing on the split beforehand addresses the shared-context failure mode rather than discovering it after the work is fragmented.

## Cautions and common failures

- **Rubber-stamping the plan.** Skimming an approval ("looks good") gains nothing. The plan review is the whole point — actually read it.
- **Over-planning trivial tasks.** Requiring a plan for every tiny change adds friction with no payoff. Reserve it for non-trivial work.
- **Treating an approved plan as a guarantee.** The agent can still implement a correct plan incorrectly. You still need to verify the resulting diff and test runs — see the verifying-agent-work lesson.
- **Vague plans.** A plan like "I'll update the relevant files" isn't reviewable. Ask for specifics: which files, what approach, what it will *not* do.
- **Letting the plan drift silently.** If the agent deviates from an approved plan mid-session, that's a signal worth interrupting and asking about — not something to notice only in the final diff.

## Related capabilities

- verifying-agent-work — the essential companion discipline: verify claims against the actual diff and actual test runs, not the agent's narration (of its plan *or* its implementation).
- repo-instruction-files — encoding the "plan first for non-trivial tasks" convention in AGENTS.md / CLAUDE.md / rules files so it applies automatically.
- checkpoints-diffs-rollback — cheap rollback makes even a flawed approved plan low-cost to recover from.
- human-in-the-loop-interruption — steering early and often, of which plan approval is the earliest and cheapest intervention point.
- multi-agent-orchestration — agreeing on a plan before fanning out work mitigates the shared-context failure mode of splitting tasks across agents.

## Official sources

- Anthropic platform docs — prompting best practices (Claude Code documentation describes plan mode as a real feature; consult official docs for current exact usage): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices

## Provenance

- The cost-asymmetry rationale and plan-first framing are well-established, cross-tool agentic-coding practice — real, current, and increasingly common, but not exclusive to one vendor and not tied to a single canonical spec.
- Claude Code's plan mode is a real, documented feature of that tool; this page describes the concept and points to official documentation rather than inventing specific UI details or flags.
- Anchored via Context7 against Anthropic's platform documentation for the Claude Code feature reference; the general practice itself is practitioner-consensus guidance presented as such.
- Last checked 2026-09-20.