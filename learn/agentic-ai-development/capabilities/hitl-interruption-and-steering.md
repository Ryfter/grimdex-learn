---
title: Human-in-the-loop interruption and steering
module_id: agentic-ai-development
capabilities:
  - hitl-interruption-and-steering
context7_library: /websites/platform_claude_en
context7_queries:
  - How can a person pause or steer a running agent before it goes too far in the wrong direction?
  - Should constraints given to an agent be phrased as positive fallbacks ("if X, do Y") or bare negatives ("do NOT do X")?
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

Human-in-the-loop interruption and steering is the practice of watching an agent while it works and stepping in — pausing it, redirecting it, adding a clarification — *before* it completes a long run in the wrong direction, rather than letting it finish and reviewing/reverting afterward.

Two pieces of guidance make up this capability:

1. **Early steering beats late review.** A session you interrupt after two minutes of drift costs two minutes to fix. The same drift discovered after a twenty-minute autonomous run costs a full review of a large diff and often a revert.
2. **Positive fallback framing outperforms bare negatives.** "If X happens, do Y instead" gives the agent something actionable. "Do NOT do X" leaves the agent without instructions for the moment it actually encounters X, so it has to guess what to do instead.

This is general, well-established human–AI-interaction guidance — it applies to how people work with AI systems broadly, not just coding agents. It is not tied to one vendor's research.

## When it is useful

- Any agent session expected to run more than a couple of minutes: checking in early catches wrong assumptions while they are still cheap to correct.
- Sessions where the task is ambiguous and the agent will necessarily make interpretation choices; early steering aligns those choices before they compound.
- Writing instructions or constraint lists for an agent, where each "don't" can be rephrased as "if you're about to do X, do Y instead."
- Long autonomous runs where you can spot-check intermediate output (a trace, a plan, an early file edit) and redirect before completion.

## Prerequisites

- A working agent session with the ability to observe what it's doing (see Related capabilities on reading a trace).
- Basic familiarity with giving the agent instructions — this capability is about *when* and *how* to intervene, not about any new tool.

## Current syntax

No commands or flags are involved. The "syntax" is phrasing:

- Bare negative: "Do NOT rewrite the authentication module."
- Positive fallback: "If you think the authentication module needs changes, stop and present a short plan instead of editing it."

Both may be used together, but the positive fallback is the load-bearing part.

## What happens (local and remote)

Nothing changes technically — the agent runs the same way it otherwise would. What changes is the *cost profile of the session*:

- **With early steering:** the human watches the beginning of the run, notices a wrong assumption or approach, pauses, corrects, and the agent continues from a good state. Total wasted work: small.
- **Without it:** the agent completes the whole run in the wrong direction. The human reviews the output, discovers the mismatch, reverts or re-briefs, and the run (or a large part of it) is repeated. Total wasted work: the whole session plus review time.

On the phrasing side: a bare negative constraint doesn't tell the agent what *to* do when it hits the prohibited situation, so it improvises — often in a direction you didn't want. A positive fallback ("if X, do Y instead") supplies the intended behavior at exactly the moment the constraint binds.

## Practical example

An agent is asked to add a feature to an application. The instructions say: "Do NOT modify the database schema."

Ten minutes in, the agent has decided the feature requires a schema change anyway, worked around the constraint awkwardly, and produced a large diff full of workarounds. Reviewing and untangling this takes longer than the original task would have.

With positive framing: "The database schema is frozen for this release. If you find you need a schema change to implement the feature, stop and tell me, and we'll simplify the feature scope together." Early in the run, the agent hits exactly that situation, stops, and asks. The human steers in seconds instead of reverting later.

## Explanation guidance

### Essential

- Interrupting a running agent early is cheaper than reviewing and reverting a completed wrong-direction run. Check in early, especially on long sessions.
- When constraining an agent, prefer "if X, do Y instead" over "do NOT do X" alone — a negative-only rule doesn't tell the agent what to do when the situation arises.
- This is general human–AI interaction practice, applicable whether or not the agent writes code.

### Experienced-user note

- Bare negatives and positive fallbacks aren't mutually exclusive; a negative can set the boundary while the fallback supplies the behavior. The fallback is what does the work.
- Combine steering with plan-first review (see Related capabilities): approving a short plan up front is a form of pre-emptive steering that catches wrong approaches before any code exists.
- For long autonomous sessions, schedule checkpoints where you glance at the trace rather than waiting for the final result.

### Optional deeper context

- The same asymmetry — early correction cheap, late correction expensive — is why plan mode and incremental commits are valuable; interruption and steering is the interactive counterpart to those structural safeguards.
- This guidance long predates coding agents; it reflects well-established findings in human–AI interaction about keeping humans aligned with automated systems during execution rather than only inspecting results afterward.

## Cautions and common failures

- **Set-and-forget long runs.** Launching a long agent session and only reading the final answer guarantees you find drift at maximum cost.
- **Negative-only constraint lists.** A rules file full of "do NOT…" entries leaves the agent improvising in exactly the situations the rules care about most.
- **Over-interrupting.** Constant steering on trivial tasks adds friction without benefit; interruption is most valuable early in a session or at genuinely ambiguous decision points.
- **Assuming the agent understood a bare negative as you intended.** If a "don't" is important, pair it with what to do instead, and verify on the next run that the fallback fires.

## Related capabilities

- **verifying-agent-work** — the same "verify against real results, not the agent's narration" discipline applies after steering: confirm the correction actually took.
- **plan-first-development** — approving a plan before implementation is pre-emptive steering at the cheapest possible point.
- **reading-agent-traces** — the trace is the observation surface that makes early interruption possible.
- **checkpoints-and-rollback** — when steering fails and a run does go wrong, cheap rollback limits the damage.
- **repo-instruction-files** — positive fallback framing belongs in your AGENTS.md/CLAUDE.md rules, not just in ad-hoc session chat.

## Official sources

- Anthropic platform docs — prompting best practices (vendor documentation): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices

The positive-fallback-vs-negative-constraint guidance is general human–AI-interaction practice presented here as practitioner guidance, not as a claim from any vendor's research.

## Provenance

This page presents cross-tool, well-established human–AI interaction guidance, anchored to Anthropic's prompting best-practices documentation for related instruction-framing advice. It is not coding-agent-specific research, and no single canonical citation is claimed for the interruption/steering cost asymmetry itself; it is presented as widely-observed practitioner experience. Coverage is audience-generic essentials depth. Facts current as of 2026-09-20.
